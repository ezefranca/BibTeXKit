#!/usr/bin/env python3

"""Validate a Stryker-compatible swift-mutation-testing JSON report."""

from __future__ import annotations

import argparse
import json
import math
import sys
from collections import Counter
from pathlib import Path
from typing import Any


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--minimum-score", type=float, default=100.0)
    parser.add_argument("--maximum-timeouts", type=int, default=0)
    parser.add_argument("--maximum-no-coverage", type=int, default=0)
    parser.add_argument("--maximum-unviable-percent", type=float, default=5.0)
    parser.add_argument("--allowed-timeout", action="append", default=[])
    parser.add_argument("--summary", type=Path)
    return parser.parse_args()


def load_mutants(report: Path) -> list[tuple[str, dict[str, Any]]]:
    payload = json.loads(report.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("Mutation report root must be an object")
    if str(payload.get("schemaVersion")) != "1":
        raise ValueError("Mutation report must use schemaVersion 1")
    files = payload.get("files")
    if not isinstance(files, dict):
        raise ValueError("Mutation report has no 'files' object")

    mutants: list[tuple[str, dict[str, Any]]] = []
    for file_path, file_payload in files.items():
        if not isinstance(file_payload, dict):
            raise ValueError(f"Mutation file record for {file_path!r} is invalid")
        entries = file_payload.get("mutants", [])
        if not isinstance(entries, list):
            raise ValueError(f"Mutation list for {file_path!r} is invalid")
        for mutant in entries:
            if not isinstance(mutant, dict):
                raise ValueError(f"Mutation record for {file_path!r} is invalid")
            location(mutant)
            mutants.append((file_path, mutant))
    return mutants


def location(mutant: dict[str, Any]) -> tuple[int, int]:
    location_value = mutant.get("location")
    if not isinstance(location_value, dict):
        raise ValueError("Mutation record has no valid location")
    start = location_value.get("start")
    if not isinstance(start, dict):
        raise ValueError("Mutation record has no valid start location")
    line = start.get("line")
    column = start.get("column")
    if (
        not isinstance(line, int)
        or isinstance(line, bool)
        or not isinstance(column, int)
        or isinstance(column, bool)
        or line < 0
        or column < 0
    ):
        raise ValueError("Mutation record has an invalid start location")
    return line, column


def validate_arguments(arguments: argparse.Namespace) -> None:
    percentages = {
        "minimum score": arguments.minimum_score,
        "maximum unviable percentage": arguments.maximum_unviable_percent,
    }
    for name, value in percentages.items():
        if not math.isfinite(value) or not 0.0 <= value <= 100.0:
            raise ValueError(f"{name} must be finite and within 0...100")
    if arguments.maximum_timeouts < 0:
        raise ValueError("maximum timeouts must be nonnegative")
    if arguments.maximum_no_coverage < 0:
        raise ValueError("maximum no-coverage count must be nonnegative")


def main() -> int:
    arguments = parse_arguments()
    validate_arguments(arguments)
    mutants = load_mutants(arguments.report)
    statuses = Counter(str(mutant.get("status", "Unknown")) for _, mutant in mutants)
    allowed_statuses = {
        "Killed",
        "Crash",
        "Survived",
        "Timeout",
        "NoCoverage",
        "Unviable",
    }
    unknown_statuses = set(statuses) - allowed_statuses
    if unknown_statuses:
        values = ", ".join(sorted(unknown_statuses))
        raise ValueError(f"Mutation report contains unknown statuses: {values}")

    killed = statuses["Killed"] + statuses["Crash"]
    survived = statuses["Survived"]
    timeouts = statuses["Timeout"]
    no_coverage = statuses["NoCoverage"]
    unviable = statuses["Unviable"]
    detected = killed + timeouts
    denominator = detected + survived + no_coverage
    score = 0.0 if denominator == 0 else detected / denominator * 100.0
    discovered = denominator + unviable
    unviable_percent = (
        0.0 if discovered == 0 else unviable / discovered * 100.0
    )

    survivors = sorted(
        (
            (file_path, *location(mutant), mutant)
            for file_path, mutant in mutants
            if mutant.get("status") in {"Survived", "Timeout", "NoCoverage"}
        ),
        key=lambda item: (item[0], item[1], item[2], str(item[3].get("id", ""))),
    )
    timeout_identifiers = {
        (
            f"{file_path}:{line}:{column}:"
            f"{mutant.get('mutatorName', 'Unknown')}"
        )
        for file_path, line, column, mutant in survivors
        if mutant.get("status") == "Timeout"
    }
    allowed_timeout_identifiers = set(arguments.allowed_timeout)
    unexpected_timeouts = timeout_identifiers - allowed_timeout_identifiers

    lines = [
        "## BibTeXKit mutation testing",
        "",
        "| Metric | Result | Required |",
        "|---|---:|---:|",
        f"| Mutation score | {score:.2f}% | {arguments.minimum_score:.2f}% |",
        f"| Counted mutants | {denominator} | ≥ 1 |",
        f"| Detected | {detected} | Informational |",
        f"| Killed | {killed} | Informational |",
        f"| Survived | {survived} | Informational |",
        f"| Timeouts | {timeouts} | ≤ {arguments.maximum_timeouts} |",
        f"| No coverage | {no_coverage} | ≤ {arguments.maximum_no_coverage} |",
        (
            f"| Unviable | {unviable} ({unviable_percent:.2f}%) | "
            f"≤ {arguments.maximum_unviable_percent:.2f}% |"
        ),
    ]

    if survivors:
        lines.extend(["", "### Surviving, timed-out, or uncovered mutants", ""])
        for file_path, line, column, mutant in survivors:
            status = mutant.get("status", "Unknown")
            mutator = mutant.get("mutatorName", "Unknown")
            original = str(mutant.get("originalText", "")).replace("`", "\\`")
            replacement = str(mutant.get("replacement", "")).replace("`", "\\`")
            lines.append(
                f"- `{file_path}:{line}:{column}` — {status}, {mutator}: "
                f"`{original}` → `{replacement}`"
            )
    else:
        lines.extend(["", "No surviving, timed-out, or uncovered mutants."])

    if unexpected_timeouts:
        lines.extend(["", "### Unexpected timeout mutants", ""])
        lines.extend(f"- `{identifier}`" for identifier in sorted(unexpected_timeouts))

    summary = "\n".join(lines) + "\n"
    print(summary, end="")

    if arguments.summary is not None:
        arguments.summary.parent.mkdir(parents=True, exist_ok=True)
        arguments.summary.write_text(summary, encoding="utf-8")

    failed = (
        denominator == 0
        or score < arguments.minimum_score
        or timeouts > arguments.maximum_timeouts
        or bool(unexpected_timeouts)
        or no_coverage > arguments.maximum_no_coverage
        or unviable_percent > arguments.maximum_unviable_percent
    )
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Unable to validate mutation report: {error}", file=sys.stderr)
        sys.exit(2)
