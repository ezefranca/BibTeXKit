#!/usr/bin/env python3
"""Validate, reproducibly archive, and describe a BibTeXKit XCFramework."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import re
import stat
import sys
import tempfile
import urllib.parse
import zipfile
from pathlib import Path
from typing import Iterable, Sequence


MODULE_NAME = "BibTeXKit"
XCFRAMEWORK_NAME = f"{MODULE_NAME}.xcframework"
XCFRAMEWORK_ZIP_NAME = f"{XCFRAMEWORK_NAME}.zip"
CHECKSUM_FILE_NAME = f"{XCFRAMEWORK_NAME}.checksum"
METADATA_FILE_NAME = "release-metadata.json"
RELEASE_VERSION_PATTERN = re.compile(
    r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
)
PLATFORM_GROUPS = {
    "macos": {("macos", None)},
    "catalyst": {("ios", "maccatalyst")},
    "ios": {("ios", None), ("ios", "simulator")},
    "tvos": {("tvos", None), ("tvos", "simulator")},
    "watchos": {("watchos", None), ("watchos", "simulator")},
    "visionos": {("xros", None), ("xros", "simulator")},
}
ALL_PLATFORM_GROUPS = tuple(PLATFORM_GROUPS)
EXPECTED_ARCHITECTURES = {
    ("macos", None): {"arm64", "x86_64"},
    ("ios", "maccatalyst"): {"arm64", "x86_64"},
    ("ios", None): {"arm64"},
    ("ios", "simulator"): {"arm64", "x86_64"},
    ("tvos", None): {"arm64"},
    ("tvos", "simulator"): {"arm64", "x86_64"},
    ("watchos", None): {"arm64", "arm64_32"},
    ("watchos", "simulator"): {"arm64", "x86_64"},
    ("xros", None): {"arm64"},
    ("xros", "simulator"): {"arm64", "x86_64"},
}
FIXED_ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)


class DistributionError(ValueError):
    """Raised when a distribution input or artifact is invalid."""


def parse_platform_groups(value: str) -> tuple[str, ...]:
    """Return validated platform group names in canonical order."""
    requested = [item.strip().lower() for item in value.split(",") if item.strip()]
    if not requested:
        raise DistributionError("at least one platform group is required")
    if "all" in requested:
        if len(requested) != 1:
            raise DistributionError("'all' cannot be combined with platform names")
        return ALL_PLATFORM_GROUPS

    unknown = sorted(set(requested).difference(PLATFORM_GROUPS))
    if unknown:
        raise DistributionError(
            f"unknown platform group(s): {', '.join(unknown)}"
        )
    return tuple(group for group in ALL_PLATFORM_GROUPS if group in requested)


def expected_platform_slices(groups: Sequence[str]) -> set[tuple[str, str | None]]:
    expected: set[tuple[str, str | None]] = set()
    for group in groups:
        expected.update(PLATFORM_GROUPS[group])
    return expected


def _path_is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def validate_xcframework(
    xcframework: Path, platform_groups: Sequence[str]
) -> list[dict[str, object]]:
    """Validate structure, platform coverage, and library-evolution metadata."""
    xcframework = xcframework.resolve()
    if not xcframework.is_dir():
        raise DistributionError(f"XCFramework does not exist: {xcframework}")
    if xcframework.name != XCFRAMEWORK_NAME:
        raise DistributionError(
            f"XCFramework must be named {XCFRAMEWORK_NAME}: {xcframework}"
        )

    info_path = xcframework / "Info.plist"
    try:
        with info_path.open("rb") as stream:
            info = plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        raise DistributionError(f"invalid XCFramework Info.plist: {error}") from error

    if info.get("XCFrameworkFormatVersion") != "1.0":
        raise DistributionError("unsupported or missing XCFrameworkFormatVersion")
    libraries = info.get("AvailableLibraries")
    if not isinstance(libraries, list) or not libraries:
        raise DistributionError("XCFramework has no AvailableLibraries")

    discovered: set[tuple[str, str | None]] = set()
    validated: list[dict[str, object]] = []
    for raw_library in libraries:
        if not isinstance(raw_library, dict):
            raise DistributionError("AvailableLibraries contains a non-dictionary")

        identifier = raw_library.get("LibraryIdentifier")
        library_path_value = raw_library.get("LibraryPath")
        platform = raw_library.get("SupportedPlatform")
        variant = raw_library.get("SupportedPlatformVariant")
        architectures = raw_library.get("SupportedArchitectures")
        if not all(isinstance(value, str) and value for value in (
            identifier,
            library_path_value,
            platform,
        )):
            raise DistributionError("library metadata has missing string fields")
        if variant is not None and not isinstance(variant, str):
            raise DistributionError(f"{identifier} has a non-string platform variant")
        if (
            not isinstance(architectures, list)
            or not architectures
            or not all(isinstance(item, str) and item for item in architectures)
        ):
            raise DistributionError(f"{identifier} has no supported architectures")

        slice_key = (platform, variant)
        expected_architectures = EXPECTED_ARCHITECTURES.get(slice_key)
        if expected_architectures is None:
            raise DistributionError(f"{identifier} has an unsupported platform slice")
        discovered_architectures = set(architectures)
        if discovered_architectures != expected_architectures:
            raise DistributionError(
                f"{identifier} architectures {sorted(discovered_architectures)} "
                f"do not match required {sorted(expected_architectures)}"
            )
        if slice_key in discovered:
            raise DistributionError(f"duplicate platform slice: {slice_key}")
        discovered.add(slice_key)

        library_root = (xcframework / identifier / library_path_value).resolve()
        if not _path_is_within(library_root, xcframework):
            raise DistributionError(f"{identifier} escapes the XCFramework root")
        if not library_root.is_dir() or library_root.suffix != ".framework":
            raise DistributionError(f"{identifier} does not contain a framework")

        framework_info_candidates = (
            library_root / "Info.plist",
            library_root / "Resources" / "Info.plist",
            library_root / "Versions" / "A" / "Resources" / "Info.plist",
        )
        executable = library_root / MODULE_NAME
        module_root = library_root / "Modules" / f"{MODULE_NAME}.swiftmodule"
        interfaces = sorted(module_root.glob("*.swiftinterface"))
        if not any(path.is_file() for path in framework_info_candidates):
            raise DistributionError(f"{identifier} has no framework Info.plist")
        if not executable.is_file() or executable.stat().st_size == 0:
            raise DistributionError(f"{identifier} has no non-empty framework binary")
        if not interfaces:
            raise DistributionError(f"{identifier} has no public Swift interface")

        for interface in interfaces:
            text = interface.read_text(encoding="utf-8")
            if "-enable-library-evolution" not in text:
                raise DistributionError(
                    f"{identifier} interface was not built for library evolution"
                )
            if f"-module-name {MODULE_NAME}" not in text:
                raise DistributionError(
                    f"{identifier} interface has the wrong module name"
                )

        validated.append(
            {
                "identifier": identifier,
                "platform": platform,
                "variant": variant,
                "architectures": sorted(architectures),
                "interfaceCount": len(interfaces),
            }
        )

    expected = expected_platform_slices(platform_groups)
    if discovered != expected:
        missing = sorted(expected.difference(discovered), key=str)
        unexpected = sorted(discovered.difference(expected), key=str)
        details = []
        if missing:
            details.append(f"missing={missing}")
        if unexpected:
            details.append(f"unexpected={unexpected}")
        raise DistributionError(
            "XCFramework platform slices do not match the request: "
            + ", ".join(details)
        )

    return sorted(
        validated,
        key=lambda item: (
            str(item["platform"]),
            str(item["variant"]),
            str(item["identifier"]),
        ),
    )


def validate_release_version(version: str) -> str:
    """Validate the stable MAJOR.MINOR.PATCH version used by release artifacts."""
    if not RELEASE_VERSION_PATTERN.fullmatch(version):
        raise DistributionError(f"invalid release version: {version!r}")
    return version


def validate_artifact_url(url: str) -> str:
    if any(character in url for character in ('"', "\\", "\r", "\n")):
        raise DistributionError("artifact URL contains unsafe characters")
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https":
        raise DistributionError("artifact URL must use HTTPS")
    if not parsed.hostname:
        raise DistributionError("artifact URL must have a host")
    if parsed.username is not None or parsed.password is not None:
        raise DistributionError("artifact URL must not contain credentials")
    if parsed.fragment:
        raise DistributionError("artifact URL must not contain a fragment")
    return url


def _normalized_zip_info(relative_path: str, mode: int, is_directory: bool) -> zipfile.ZipInfo:
    archive_name = relative_path + ("/" if is_directory else "")
    info = zipfile.ZipInfo(archive_name, FIXED_ZIP_TIMESTAMP)
    info.create_system = 3
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = mode << 16
    if is_directory:
        info.external_attr |= 0x10
    return info


def _archive_entries(root: Path) -> Iterable[tuple[Path, str]]:
    parent = root.parent
    paths = [root]
    paths.extend(root.rglob("*"))
    for path in sorted(paths, key=lambda item: item.relative_to(parent).as_posix()):
        yield path, path.relative_to(parent).as_posix()


def create_deterministic_zip(root: Path, destination: Path) -> str:
    """Archive a directory with stable order, timestamps, modes, and metadata."""
    root = root.resolve()
    if not root.is_dir():
        raise DistributionError(f"archive root does not exist: {root}")
    if destination.exists():
        raise DistributionError(f"archive already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)

    resolved_root = root.resolve()
    with zipfile.ZipFile(
        destination,
        mode="x",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
        strict_timestamps=True,
    ) as archive:
        for path, archive_name in _archive_entries(root):
            metadata = path.lstat()
            if stat.S_ISLNK(metadata.st_mode):
                target = os.readlink(path)
                resolved_target = (path.parent / target).resolve()
                if not _path_is_within(resolved_target, resolved_root):
                    raise DistributionError(
                        f"symbolic link escapes archive root: {archive_name}"
                    )
                info = _normalized_zip_info(
                    archive_name,
                    stat.S_IFLNK | 0o777,
                    is_directory=False,
                )
                archive.writestr(info, target.encode("utf-8"))
            elif stat.S_ISDIR(metadata.st_mode):
                info = _normalized_zip_info(
                    archive_name,
                    stat.S_IFDIR | 0o755,
                    is_directory=True,
                )
                archive.writestr(info, b"")
            elif stat.S_ISREG(metadata.st_mode):
                permissions = 0o755 if metadata.st_mode & 0o111 else 0o644
                info = _normalized_zip_info(
                    archive_name,
                    stat.S_IFREG | permissions,
                    is_directory=False,
                )
                with path.open("rb") as stream:
                    archive.writestr(info, stream.read())
            else:
                raise DistributionError(
                    f"unsupported filesystem entry in archive: {archive_name}"
                )

    checksum = hashlib.sha256()
    with destination.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def _write_text_atomically(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f".{path.name}.",
        delete=False,
    ) as stream:
        temporary = Path(stream.name)
        stream.write(content)
    os.replace(temporary, path)


def package_distribution(
    *,
    xcframework: Path,
    output_directory: Path,
    version: str,
    artifact_url: str,
    platform_groups: Sequence[str],
) -> dict[str, object]:
    version = validate_release_version(version)
    artifact_url = validate_artifact_url(artifact_url)
    slices = validate_xcframework(xcframework, platform_groups)

    output_directory.mkdir(parents=True, exist_ok=True)
    zip_path = output_directory / XCFRAMEWORK_ZIP_NAME
    checksum_path = output_directory / CHECKSUM_FILE_NAME
    metadata_path = output_directory / METADATA_FILE_NAME
    outputs = (
        zip_path,
        checksum_path,
        metadata_path,
    )
    existing = [str(path) for path in outputs if path.exists()]
    if existing:
        raise DistributionError(
            "refusing to overwrite distribution output(s): " + ", ".join(existing)
        )

    checksum = create_deterministic_zip(xcframework, zip_path)
    _write_text_atomically(checksum_path, checksum + "\n")

    metadata: dict[str, object] = {
        "artifact": XCFRAMEWORK_ZIP_NAME,
        "artifactURL": artifact_url,
        "checksum": checksum,
        "module": MODULE_NAME,
        "platformGroups": list(platform_groups),
        "slices": slices,
        "version": version,
    }
    _write_text_atomically(
        metadata_path,
        json.dumps(metadata, indent=2, sort_keys=True) + "\n",
    )
    return metadata


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xcframework", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--artifact-url", required=True)
    parser.add_argument(
        "--platforms",
        default="all",
        help="all or comma-separated macos,catalyst,ios,tvos,watchos,visionos",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    arguments = build_parser().parse_args(argv)
    try:
        groups = parse_platform_groups(arguments.platforms)
        metadata = package_distribution(
            xcframework=arguments.xcframework,
            output_directory=arguments.output_directory,
            version=arguments.version,
            artifact_url=arguments.artifact_url,
            platform_groups=groups,
        )
    except (DistributionError, OSError, zipfile.BadZipFile) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"XCFramework: {arguments.xcframework.resolve()}")
    print(f"ZIP: {(arguments.output_directory / XCFRAMEWORK_ZIP_NAME).resolve()}")
    print(f"Checksum: {metadata['checksum']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
