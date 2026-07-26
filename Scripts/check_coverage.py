#!/usr/bin/env python3

"""Summarize and enforce BibTeXKit's production-source coverage."""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


@dataclass
class Metric:
    covered: int = 0
    count: int = 0

    @property
    def percent(self) -> float:
        return 100.0 if self.count == 0 else self.covered / self.count * 100.0


@dataclass
class Coverage:
    lines: Metric
    functions: Metric
    regions: Metric
    branches: Metric


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--repository-root", required=True, type=Path)
    parser.add_argument("--minimum-line", type=float, default=100.0)
    parser.add_argument("--minimum-function", type=float, default=100.0)
    parser.add_argument("--minimum-region", type=float, default=100.0)
    parser.add_argument("--minimum-core-line", type=float, default=100.0)
    parser.add_argument("--minimum-core-function", type=float, default=100.0)
    parser.add_argument("--minimum-core-region", type=float, default=100.0)
    parser.add_argument("--summary", type=Path)
    return parser.parse_args()


def load_files(report: Path) -> list[dict[str, Any]]:
    payload = json.loads(report.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("Coverage report root must be an object")
    data = payload.get("data")
    if not isinstance(data, list) or len(data) != 1:
        raise ValueError("Coverage report must contain exactly one data object")
    files = data[0].get("files")
    if not isinstance(files, list):
        raise ValueError("Coverage report has no file list")
    return [entry for entry in files if isinstance(entry, dict)]


def validate_arguments(arguments: argparse.Namespace) -> None:
    thresholds = {
        "minimum line": arguments.minimum_line,
        "minimum function": arguments.minimum_function,
        "minimum region": arguments.minimum_region,
        "minimum core line": arguments.minimum_core_line,
        "minimum core function": arguments.minimum_core_function,
        "minimum core region": arguments.minimum_core_region,
    }
    for name, value in thresholds.items():
        if not math.isfinite(value) or not 0.0 <= value <= 100.0:
            raise ValueError(f"{name} coverage must be finite and within 0...100")


def aggregate(
    files: list[dict[str, Any]],
    include: Callable[[Path], bool],
) -> Coverage:
    metrics = {
        name: Metric()
        for name in ("lines", "functions", "regions", "branches")
    }
    matched_files = 0

    for entry in files:
        filename = entry.get("filename")
        summary = entry.get("summary")
        if not isinstance(filename, str) or not isinstance(summary, dict):
            continue
        if not include(Path(filename)):
            continue

        matched_files += 1
        for name, metric in metrics.items():
            values = summary.get(name)
            if not isinstance(values, dict):
                raise ValueError(f"{filename!r} has no {name!r} summary")
            covered = values.get("covered")
            count = values.get("count")
            if (
                not isinstance(covered, int)
                or isinstance(covered, bool)
                or not isinstance(count, int)
                or isinstance(count, bool)
                or covered < 0
                or count < 0
                or covered > count
            ):
                raise ValueError(f"{filename!r} has an invalid {name!r} summary")
            metric.covered += covered
            metric.count += count

    if matched_files == 0:
        raise ValueError("Coverage filter matched no source files")

    return Coverage(**metrics)


def metric_cell(metric: Metric) -> str:
    return f"{metric.percent:.2f}% ({metric.covered}/{metric.count})"


def below(actual: float, required: float) -> bool:
    return actual + 1e-9 < required


def main() -> int:
    arguments = parse_arguments()
    validate_arguments(arguments)
    source_root = (
        arguments.repository_root.resolve() / "Sources" / "BibTeXKit"
    )
    files = load_files(arguments.report)

    def production(path: Path) -> bool:
        try:
            path.resolve().relative_to(source_root)
            return True
        except ValueError:
            return False

    def core(path: Path) -> bool:
        try:
            relative = path.resolve().relative_to(source_root)
        except ValueError:
            return False
        return (
            relative.parts[0] in {"Models", "Parsing"}
            or relative == Path("Highlighting/BibTeXHighlighter.swift")
        )

    production_coverage = aggregate(files, production)
    core_coverage = aggregate(files, core)

    if production_coverage.branches.count == 0:
        branch_result = (
            "Unavailable (the selected Swift compiler emitted no branch counters)"
        )
    else:
        branch_result = metric_cell(production_coverage.branches)

    rows = [
        (
            "Production lines",
            metric_cell(production_coverage.lines),
            f"{arguments.minimum_line:.1f}%",
        ),
        (
            "Production functions",
            metric_cell(production_coverage.functions),
            f"{arguments.minimum_function:.1f}%",
        ),
        (
            "Production regions",
            metric_cell(production_coverage.regions),
            f"{arguments.minimum_region:.1f}%",
        ),
        ("Production branches", branch_result, "Not gated when unsupported"),
        (
            "Core lines",
            metric_cell(core_coverage.lines),
            f"{arguments.minimum_core_line:.1f}%",
        ),
        (
            "Core functions",
            metric_cell(core_coverage.functions),
            f"{arguments.minimum_core_function:.1f}%",
        ),
        (
            "Core regions",
            metric_cell(core_coverage.regions),
            f"{arguments.minimum_core_region:.1f}%",
        ),
    ]

    lines = [
        "## BibTeXKit coverage",
        "",
        "| Metric | Result | Required |",
        "|---|---:|---:|",
        *(f"| {name} | {result} | {required} |" for name, result, required in rows),
        "",
        (
            "Core comprises `Models/**`, `Parsing/**`, and "
            "`Highlighting/BibTeXHighlighter.swift`."
        ),
    ]
    summary = "\n".join(lines) + "\n"
    print(summary, end="")

    if arguments.summary is not None:
        arguments.summary.parent.mkdir(parents=True, exist_ok=True)
        arguments.summary.write_text(summary, encoding="utf-8")

    failures = (
        below(production_coverage.lines.percent, arguments.minimum_line),
        below(production_coverage.functions.percent, arguments.minimum_function),
        below(production_coverage.regions.percent, arguments.minimum_region),
        below(core_coverage.lines.percent, arguments.minimum_core_line),
        below(core_coverage.functions.percent, arguments.minimum_core_function),
        below(core_coverage.regions.percent, arguments.minimum_core_region),
    )
    if any(failures):
        print("Coverage thresholds were not met.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Unable to validate coverage report: {error}", file=sys.stderr)
        sys.exit(2)
