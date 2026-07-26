#!/usr/bin/env python3

"""Verify an exact dependency pin in a SwiftPM Package.resolved file."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("resolved_file", type=Path)
    parser.add_argument("--schema-version", required=True, type=int)
    parser.add_argument("--identity", required=True)
    parser.add_argument("--kind", required=True)
    parser.add_argument("--location", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    return parser.parse_args()


def load_resolved(
    resolved_file: Path,
) -> tuple[int, list[dict[str, Any]]]:
    payload = json.loads(resolved_file.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("Package.resolved root must be an object")

    schema_version = payload.get("version")
    if not isinstance(schema_version, int) or isinstance(schema_version, bool):
        raise ValueError("Package.resolved has no valid schema version")

    pins = payload.get("pins")
    if not isinstance(pins, list):
        raise ValueError("Package.resolved has no pin list")
    if not all(isinstance(pin, dict) for pin in pins):
        raise ValueError("Package.resolved contains an invalid pin")
    return schema_version, pins


def verify_pin(arguments: argparse.Namespace) -> None:
    schema_version, pins = load_resolved(arguments.resolved_file)
    if schema_version != arguments.schema_version:
        raise ValueError(
            "Package.resolved schema mismatch: "
            f"expected {arguments.schema_version}, found {schema_version}"
        )

    matches = [
        pin
        for pin in pins
        if pin.get("identity") == arguments.identity
    ]
    if len(matches) != 1:
        raise ValueError(
            f"expected exactly one {arguments.identity!r} pin; found {len(matches)}"
        )

    pin = matches[0]
    state = pin.get("state")
    if not isinstance(state, dict):
        raise ValueError(f"{arguments.identity!r} has no valid state")

    expected = {
        "kind": arguments.kind,
        "location": arguments.location,
        "version": arguments.version,
        "revision": arguments.revision,
    }
    actual = {
        "kind": pin.get("kind"),
        "location": pin.get("location"),
        "version": state.get("version"),
        "revision": state.get("revision"),
    }
    mismatches = [
        f"{name}: expected {expected[name]!r}, found {actual[name]!r}"
        for name in expected
        if actual[name] != expected[name]
    ]
    if mismatches:
        raise ValueError(
            f"{arguments.identity!r} pin mismatch: " + "; ".join(mismatches)
        )


def main() -> int:
    arguments = parse_arguments()
    verify_pin(arguments)
    print(
        f"Verified {arguments.identity} {arguments.version} "
        f"at {arguments.revision}."
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
