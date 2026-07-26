import hashlib
import importlib.util
import os
import plistlib
import stat
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "package_xcframework.py"
VALIDATION_SCRIPT_PATH = (
    Path(__file__).resolve().parents[1] / "validate_distribution.sh"
)
SPEC = importlib.util.spec_from_file_location("package_xcframework", SCRIPT_PATH)
distribution = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(distribution)


class XCFrameworkDistributionTests(unittest.TestCase):
    def make_xcframework(self, parent: Path) -> Path:
        root = parent / "BibTeXKit.xcframework"
        identifier = "macos-arm64"
        framework = root / identifier / "BibTeXKit.framework"
        module = framework / "Modules" / "BibTeXKit.swiftmodule"
        module.mkdir(parents=True)
        (framework / "BibTeXKit").write_bytes(b"deterministic Mach-O fixture")
        (framework / "BibTeXKit").chmod(0o755)
        with (framework / "Info.plist").open("wb") as stream:
            plistlib.dump({"CFBundleExecutable": "BibTeXKit"}, stream)
        (module / "arm64-apple-macos.swiftinterface").write_text(
            "// swift-module-flags: -enable-library-evolution "
            "-module-name BibTeXKit\n",
            encoding="utf-8",
        )
        with (root / "Info.plist").open("wb") as stream:
            plistlib.dump(
                {
                    "XCFrameworkFormatVersion": "1.0",
                    "AvailableLibraries": [
                        {
                            "LibraryIdentifier": identifier,
                            "LibraryPath": "BibTeXKit.framework",
                            "SupportedArchitectures": ["arm64", "x86_64"],
                            "SupportedPlatform": "macos",
                        }
                    ],
                },
                stream,
            )
        return root

    def test_given_a_complete_framework_when_validated_then_its_slice_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            xcframework = self.make_xcframework(Path(directory))

            slices = distribution.validate_xcframework(xcframework, ("macos",))

            self.assertEqual(len(slices), 1)
            self.assertEqual(slices[0]["platform"], "macos")
            self.assertEqual(slices[0]["architectures"], ["arm64", "x86_64"])

    def test_given_a_missing_library_evolution_flag_when_validated_then_it_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            xcframework = self.make_xcframework(Path(directory))
            interface = next(xcframework.rglob("*.swiftinterface"))
            interface.write_text(
                "// swift-module-flags: -module-name BibTeXKit\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                distribution.DistributionError, "library evolution"
            ):
                distribution.validate_xcframework(xcframework, ("macos",))

    def test_given_a_requested_missing_platform_when_validated_then_it_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            xcframework = self.make_xcframework(Path(directory))

            with self.assertRaisesRegex(
                distribution.DistributionError, "platform slices"
            ):
                distribution.validate_xcframework(xcframework, ("ios",))

    def test_given_equivalent_trees_when_archived_then_zip_bytes_are_identical(self):
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            first_tree = self.make_xcframework(parent / "first")
            second_tree = self.make_xcframework(parent / "second")
            for index, path in enumerate(second_tree.rglob("*")):
                os.utime(path, (1_700_000_000 + index, 1_700_000_000 + index))
            first_zip = parent / "first.zip"
            second_zip = parent / "second.zip"

            first_checksum = distribution.create_deterministic_zip(
                first_tree, first_zip
            )
            second_checksum = distribution.create_deterministic_zip(
                second_tree, second_zip
            )

            self.assertEqual(first_checksum, second_checksum)
            self.assertEqual(first_zip.read_bytes(), second_zip.read_bytes())
            with zipfile.ZipFile(first_zip) as archive:
                self.assertTrue(archive.namelist())
                self.assertTrue(
                    all(item.date_time == (1980, 1, 1, 0, 0, 0)
                        for item in archive.infolist())
                )

    def test_given_an_external_symbolic_link_when_archived_then_it_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            root = parent / "Archive"
            root.mkdir()
            outside = parent / "secret"
            outside.write_text("not distributable", encoding="utf-8")
            (root / "escape").symlink_to(outside)

            with self.assertRaisesRegex(
                distribution.DistributionError, "escapes archive root"
            ):
                distribution.create_deterministic_zip(root, parent / "bad.zip")

    def test_given_release_inputs_when_packaged_then_checksum_and_metadata_match(self):
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            xcframework = self.make_xcframework(parent)
            output = parent / "Release"
            url = (
                "https://github.com/ezefranca/BibTeXKit/releases/download/"
                "v1.1.0/BibTeXKit.xcframework.zip"
            )

            metadata = distribution.package_distribution(
                xcframework=xcframework,
                output_directory=output,
                version="1.1.0",
                artifact_url=url,
                platform_groups=("macos",),
            )

            archive = output / "BibTeXKit.xcframework.zip"
            checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
            self.assertEqual(metadata["checksum"], checksum)
            self.assertEqual(metadata["artifactURL"], url)
            self.assertEqual(
                (output / "BibTeXKit.xcframework.checksum")
                .read_text(encoding="utf-8")
                .strip(),
                checksum,
            )
            self.assertTrue((output / "release-metadata.json").is_file())

    def test_given_unsafe_or_non_https_urls_when_validated_then_they_are_rejected(self):
        invalid_urls = (
            "http://example.com/BibTeXKit.zip",
            "https://user:secret@example.com/BibTeXKit.zip",
            "https://example.com/BibTeXKit.zip#fragment",
            'https://example.com/"BibTeXKit.zip',
        )
        for url in invalid_urls:
            with self.subTest(url=url):
                with self.assertRaises(distribution.DistributionError):
                    distribution.validate_artifact_url(url)

    def test_given_invalid_versions_when_validated_then_they_are_rejected(self):
        invalid_versions = (
            "1.1",
            "01.1.0",
            "1.1.0\n",
            "v1.1.0",
            "1.1.0-alpha",
            "1.1.0+build",
            "1.1.0-alpha+build",
            "1.1.0-a..b",
            "1.1.0-01",
        )
        for version in invalid_versions:
            with self.subTest(version=version):
                with self.assertRaises(distribution.DistributionError):
                    distribution.validate_release_version(version)

    def test_given_stable_release_versions_when_validated_then_they_are_preserved(self):
        for version in ("0.0.0", "1.1.0", "10.203.4005"):
            with self.subTest(version=version):
                self.assertEqual(
                    distribution.validate_release_version(version),
                    version,
                )

    def test_given_platform_selection_when_parsed_then_order_is_canonical(self):
        self.assertEqual(
            distribution.parse_platform_groups("visionos,macos,ios"),
            ("macos", "ios", "visionos"),
        )
        self.assertEqual(
            distribution.parse_platform_groups("all"),
            distribution.ALL_PLATFORM_GROUPS,
        )
        with self.assertRaises(distribution.DistributionError):
            distribution.parse_platform_groups("all,ios")
        with self.assertRaises(distribution.DistributionError):
            distribution.parse_platform_groups("")

    def test_given_empty_platform_selection_when_validating_then_it_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [
                    str(VALIDATION_SCRIPT_PATH),
                    "--xcframework",
                    directory,
                    "--platforms",
                    "",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("at least one platform group is required", result.stderr)


if __name__ == "__main__":
    unittest.main()
