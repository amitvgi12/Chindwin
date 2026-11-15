#!/usr/bin/env python3
"""Run the GUT unit tests headless and fail loudly.

GUT's own exit code is not enough for CI: a test file that does not compile is
skipped and GUT still exits 0. This wrapper also fails when

  * Godot printed a script error, or
  * GUT ran a different number of test scripts than exist on disk.

Usage: python3 tools/run_tests.py     (or: make test)
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
TEST_DIR = GAME / "test" / "unit"
ANSI_COLOUR = re.compile(r"\x1b\[[0-9;]*m")


def main() -> int:
    test_files = sorted(TEST_DIR.rglob("test_*.gd"))
    if not test_files:
        print(f"error: no test files found under {TEST_DIR}", file=sys.stderr)
        return 1

    result = subprocess.run(
        [
            str(ROOT / "tools" / "godot.sh"),
            "--headless",
            "--path", str(GAME),
            "-s", "addons/gut/gut_cmdln.gd",
            "-gexit",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    output = ANSI_COLOUR.sub("", result.stdout)
    print(output)

    problems = []
    if result.returncode != 0:
        problems.append(f"GUT exited with code {result.returncode}")
    if "SCRIPT ERROR" in output:
        problems.append("Godot reported a script error (search the output above for SCRIPT ERROR)")
    scripts_line = re.search(r"^Scripts\s+(\d+)\s*$", output, re.MULTILINE)
    scripts_run = int(scripts_line.group(1)) if scripts_line else 0
    if scripts_run != len(test_files):
        problems.append(
            f"GUT ran {scripts_run} test script(s) but {len(test_files)} exist on disk; "
            "one probably failed to compile and was skipped"
        )

    if problems:
        print("TESTS FAILED", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    print(f"TESTS OK: {scripts_run} script(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
