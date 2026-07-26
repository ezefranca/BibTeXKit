from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
COVERAGE_CHECKER = REPOSITORY_ROOT / "Scripts" / "check_coverage.py"
MUTATION_CHECKER = REPOSITORY_ROOT / "Scripts" / "check_mutation_score.py"
MUTATION_RUNNER = REPOSITORY_ROOT / "Scripts" / "mutation.sh"
PACKAGE_PIN_CHECKER = REPOSITORY_ROOT / "Scripts" / "check_package_pin.py"


class QualityGateTests(unittest.TestCase):
    def run_checker(self, checker: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(checker), *arguments],
            check=False,
            capture_output=True,
            text=True,
        )

    def write_json(self, directory: Path, name: str, payload: object) -> Path:
        path = directory / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def mutation_report(self, statuses: list[str]) -> dict[str, object]:
        mutants = [
            {
                "id": str(index),
                "location": {"start": {"line": index + 1, "column": 1}},
                "mutatorName": "Fixture",
                "originalText": "true",
                "replacement": "false",
                "status": status,
            }
            for index, status in enumerate(statuses)
        ]
        return {
            "schemaVersion": "1",
            "files": {
                "/Sources/BibTeXKit/Fixture.swift": {
                    "language": "swift",
                    "mutants": mutants,
                    "source": "let value = true",
                }
            },
        }

    def coverage_report(self, repository: Path) -> dict[str, object]:
        def metric(covered: int, count: int) -> dict[str, object]:
            return {
                "count": count,
                "covered": covered,
                "notcovered": count - covered,
                "percent": 0 if count == 0 else covered / count * 100,
            }

        def file(filename: Path, covered: int) -> dict[str, object]:
            return {
                "filename": str(filename),
                "summary": {
                    "lines": metric(covered, 100),
                    "functions": metric(covered, 100),
                    "regions": metric(covered, 100),
                    "branches": metric(0, 0),
                },
            }

        return {
            "data": [
                {
                    "files": [
                        file(
                            repository
                            / "Sources"
                            / "BibTeXKit"
                            / "Models"
                            / "Core.swift",
                            95,
                        ),
                        file(
                            repository
                            / "Sources"
                            / "BibTeXKit"
                            / "Views"
                            / "View.swift",
                            75,
                        ),
                        file(repository / "Tests" / "InflationTests.swift", 0),
                    ]
                }
            ]
        }

    def package_pin(
        self,
        *,
        kind: str = "remoteSourceControl",
        location: str = "https://github.com/apple/swift-syntax.git",
        revision: str = "expected-revision",
        schema_version: object = 3,
        version: str = "603.0.2",
    ) -> dict[str, object]:
        return {
            "pins": [
                {
                    "identity": "swift-syntax",
                    "kind": kind,
                    "location": location,
                    "state": {
                        "revision": revision,
                        "version": version,
                    },
                }
            ],
            "version": schema_version,
        }

    def package_pin_arguments(self, resolved_file: Path) -> list[str]:
        return [
            str(resolved_file),
            "--schema-version",
            "3",
            "--identity",
            "swift-syntax",
            "--kind",
            "remoteSourceControl",
            "--location",
            "https://github.com/apple/swift-syntax.git",
            "--version",
            "603.0.2",
            "--revision",
            "expected-revision",
        ]

    def test_mutation_gate_accepts_exact_score_boundary(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            report = self.write_json(
                directory,
                "mutation.json",
                self.mutation_report(
                    ["Killed", "Killed", "Killed", "Killed", "Survived", "Unviable"]
                ),
            )

            result = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "80",
                "--maximum-unviable-percent",
                "20",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("80.00%", result.stdout)

    def test_mutation_gate_enforces_timeout_and_unviable_ceilings(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            report = self.write_json(
                directory,
                "mutation.json",
                self.mutation_report(
                    [
                        "Killed",
                        "Killed",
                        "Killed",
                        "Killed",
                        "Timeout",
                        "Unviable",
                    ]
                ),
            )

            timeout_result = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--maximum-timeouts",
                "0",
                "--maximum-unviable-percent",
                "20",
            )
            default_timeout_result = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "80",
                "--maximum-unviable-percent",
                "20",
            )
            unviable_result = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "80",
                "--maximum-timeouts",
                "1",
                "--maximum-unviable-percent",
                "10",
            )
            allowed_timeout = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "80",
                "--maximum-timeouts",
                "1",
                "--maximum-unviable-percent",
                "20",
                "--allowed-timeout",
                "/Sources/BibTeXKit/Fixture.swift:5:1:Fixture",
            )
            unexpected_timeout = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "80",
                "--maximum-timeouts",
                "1",
                "--maximum-unviable-percent",
                "20",
                "--allowed-timeout",
                "/Sources/BibTeXKit/Fixture.swift:99:1:Fixture",
            )

            self.assertEqual(timeout_result.returncode, 1)
            self.assertEqual(default_timeout_result.returncode, 1)
            self.assertIn(
                "Unexpected timeout mutants",
                default_timeout_result.stdout,
            )
            self.assertEqual(unviable_result.returncode, 1)
            self.assertEqual(allowed_timeout.returncode, 0)
            self.assertEqual(unexpected_timeout.returncode, 1)
            self.assertIn("Unexpected timeout mutants", unexpected_timeout.stdout)

    def test_mutation_gate_counts_an_allowlisted_timeout_as_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            report = self.write_json(
                directory,
                "mutation.json",
                self.mutation_report(["Killed", "Timeout"]),
            )

            result = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "100",
                "--maximum-timeouts",
                "1",
                "--maximum-unviable-percent",
                "0",
                "--allowed-timeout",
                "/Sources/BibTeXKit/Fixture.swift:2:1:Fixture",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("| Mutation score | 100.00%", result.stdout)
            self.assertIn("| Detected | 2 |", result.stdout)

    def test_mutation_gate_rejects_zero_and_unknown_mutants(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            empty_report = self.write_json(
                directory,
                "empty.json",
                self.mutation_report([]),
            )
            unknown_report = self.write_json(
                directory,
                "unknown.json",
                self.mutation_report(["Killed", "FutureStatus"]),
            )

            empty_result = self.run_checker(MUTATION_CHECKER, str(empty_report))
            unknown_result = self.run_checker(MUTATION_CHECKER, str(unknown_report))

            self.assertEqual(empty_result.returncode, 1)
            self.assertEqual(unknown_result.returncode, 2)
            self.assertIn("unknown statuses", unknown_result.stderr)

    def test_mutation_gate_rejects_nonfinite_threshold(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            report = self.write_json(
                directory,
                "mutation.json",
                self.mutation_report(["Killed"]),
            )

            result = self.run_checker(
                MUTATION_CHECKER,
                str(report),
                "--minimum-score",
                "nan",
            )

            self.assertEqual(result.returncode, 2)
            self.assertIn("must be finite", result.stderr)

    def test_mutation_runner_rejects_stale_reports(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            fake_tool = directory / "fake-mutation-tool"
            fake_tool.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            fake_tool.chmod(0o700)
            for name in (
                "mutation.json",
                "mutation.html",
                "mutation-sonar.json",
                "summary.md",
            ):
                (directory / name).write_text("stale", encoding="utf-8")

            environment = os.environ.copy()
            environment["MUTATION_REPORT_DIR"] = str(directory)
            environment["MUTATION_TESTING_BIN"] = str(fake_tool)
            result = subprocess.run(
                [str(MUTATION_RUNNER)],
                check=False,
                capture_output=True,
                env=environment,
                text=True,
            )

            self.assertEqual(result.returncode, 2)
            self.assertIn("did not create", result.stderr)
            self.assertFalse((directory / "mutation.json").exists())
            self.assertFalse((directory / "mutation.html").exists())
            self.assertFalse((directory / "mutation-sonar.json").exists())
            self.assertFalse((directory / "summary.md").exists())

    def test_package_pin_gate_accepts_the_exact_remote_dependency(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            resolved_file = self.write_json(
                directory,
                "Package.resolved",
                self.package_pin(),
            )

            result = self.run_checker(
                PACKAGE_PIN_CHECKER,
                *self.package_pin_arguments(resolved_file),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(
                "Verified swift-syntax 603.0.2 at expected-revision.",
                result.stdout,
            )

    def test_package_pin_gate_rejects_dependency_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            drifted_payloads = {
                "kind": self.package_pin(kind="localSourceControl"),
                "location": self.package_pin(location="https://example.com/fork.git"),
                "version": self.package_pin(version="603.0.3"),
                "revision": self.package_pin(revision="unexpected-revision"),
                "schema": self.package_pin(schema_version=2),
            }

            for name, payload in drifted_payloads.items():
                with self.subTest(name=name):
                    drifted_file = self.write_json(
                        directory,
                        f"{name}.resolved",
                        payload,
                    )
                    result = self.run_checker(
                        PACKAGE_PIN_CHECKER,
                        *self.package_pin_arguments(drifted_file),
                    )

                    self.assertEqual(result.returncode, 2)
                    self.assertIn(name, result.stderr)

    def test_package_pin_gate_rejects_malformed_and_duplicate_pins(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            duplicate_payload = self.package_pin()
            duplicate_payload["pins"].append(duplicate_payload["pins"][0])
            duplicate_file = self.write_json(
                directory,
                "Duplicate.resolved",
                duplicate_payload,
            )
            malformed_file = directory / "Malformed.resolved"
            malformed_file.write_text("{", encoding="utf-8")

            duplicate = self.run_checker(
                PACKAGE_PIN_CHECKER,
                *self.package_pin_arguments(duplicate_file),
            )
            malformed = self.run_checker(
                PACKAGE_PIN_CHECKER,
                *self.package_pin_arguments(malformed_file),
            )

            self.assertEqual(duplicate.returncode, 2)
            self.assertIn("found 2", duplicate.stderr)
            self.assertEqual(malformed.returncode, 2)
            self.assertIn("error:", malformed.stderr)

    def test_coverage_gate_filters_nonproduction_files_and_reports_missing_branches(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            report = self.write_json(
                repository,
                "coverage.json",
                self.coverage_report(repository),
            )

            result = self.run_checker(
                COVERAGE_CHECKER,
                str(report),
                "--repository-root",
                str(repository),
                "--minimum-line",
                "85",
                "--minimum-function",
                "85",
                "--minimum-region",
                "85",
                "--minimum-core-line",
                "95",
                "--minimum-core-function",
                "95",
                "--minimum-core-region",
                "95",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("85.00% (170/200)", result.stdout)
            self.assertIn("Unavailable", result.stdout)

    def test_coverage_gate_rejects_regressions_and_nonfinite_thresholds(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            report = self.write_json(
                repository,
                "coverage.json",
                self.coverage_report(repository),
            )

            regression = self.run_checker(
                COVERAGE_CHECKER,
                str(report),
                "--repository-root",
                str(repository),
                "--minimum-line",
                "86",
            )
            nonfinite = self.run_checker(
                COVERAGE_CHECKER,
                str(report),
                "--repository-root",
                str(repository),
                "--minimum-line",
                "nan",
            )

            self.assertEqual(regression.returncode, 1)
            self.assertEqual(nonfinite.returncode, 2)
            self.assertIn("must be finite", nonfinite.stderr)


if __name__ == "__main__":
    unittest.main()
