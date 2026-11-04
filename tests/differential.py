#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Deterministic datetime/integer differential checks; no floating timestamps."""
import argparse
import datetime as dt
import os
from pathlib import Path
import random
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BILLION = 1_000_000_000
MIN_I64, MAX_I64 = -(1 << 63), (1 << 63) - 1
MIN_SECONDS, MAX_SECONDS = -62_135_596_800, 253_402_300_799
EPOCH = dt.datetime(1970, 1, 1)


def unix_seconds(value):
    difference = value - EPOCH
    return difference.days * 86400 + difference.seconds


def civil_text(value):
    return (f"{value.year:04}-{value.month:02}-{value.day:02}T"
            f"{value.hour:02}:{value.minute:02}:{value.second:02}")


def canonical(value, ns):
    fraction = f".{ns:09}".rstrip("0") if ns else ""
    return civil_text(value) + fraction + "Z"


def fixtures(count):
    rng = random.Random(3339)
    rows = []

    def add(command, expected):
        rows.append((command, expected))

    def parse(value, ns, offset, width=9, lowercase=False):
        try:
            local = value + dt.timedelta(minutes=offset)
        except OverflowError:
            return
        fraction = ("." + f"{ns:09}"[:width]) if width else ""
        actual_ns = int((fraction[1:] + "0" * 9)[:9]) if fraction else 0
        suffix = "Z" if offset == 0 else (
            ("+" if offset > 0 else "-")
            + f"{abs(offset) // 60:02}:{abs(offset) % 60:02}"
        )
        source = civil_text(local) + fraction + suffix
        if lowercase:
            source = source.replace("T", "t").replace("Z", "z")
        expected = "\t".join(map(str, (
            unix_seconds(value), actual_ns, canonical(value, actual_ns),
            value.year, value.month, value.day, value.hour, value.minute,
            value.second, actual_ns,
        )))
        add("P\t" + source, expected)

    anchors = [dt.datetime(1, 1, 1), dt.datetime(9999, 12, 31, 23, 59, 59),
               dt.datetime(1969, 12, 31, 23, 59, 59), EPOCH,
               dt.datetime(2000, 2, 29, 23, 59, 59),
               dt.datetime(1900, 3, 1), dt.datetime(2400, 2, 29)]
    for year in range(100, 10000, 100):
        march = dt.datetime(year, 3, 1)
        anchors.extend((march, march - dt.timedelta(seconds=1)))
    for value in anchors:
        for offset in (-1439, -60, -1, 0, 1, 60, 1439):
            for width in (0, 1, 9):
                parse(value, 123456789, offset, width)
    for _ in range(count):
        value = dt.datetime.fromordinal(rng.randint(1, dt.date.max.toordinal()))
        value += dt.timedelta(seconds=rng.randrange(86400))
        parse(value, rng.randrange(BILLION), rng.randint(-1439, 1439),
              rng.randrange(10), bool(rng.getrandbits(1)))

    edges = [MIN_I64, MIN_I64 + 1, MIN_I64 + BILLION - 1,
             -BILLION - 1, -BILLION, -BILLION + 1, -1, 0, 1,
             BILLION - 1, BILLION, BILLION + 1, MAX_I64 - 1, MAX_I64]
    for value in edges + [rng.randint(MIN_I64, MAX_I64) for _ in range(count)]:
        seconds, ns = divmod(value, BILLION)
        add(f"U\t{value}", f"{seconds}\t{ns}")
    pairs = [(a, b) for a in edges for b in edges]
    pairs += [(rng.randint(MIN_I64, MAX_I64), rng.randint(MIN_I64, MAX_I64))
              for _ in range(count)]
    for a, b in pairs:
        for operation in ("A", "S", "I"):
            result = a + b if operation == "A" else a - b
            expected = str(result) if MIN_I64 <= result <= MAX_I64 else "O"
            add(f"{operation}\t{a}\t{b}", expected)

    stamps = [(MIN_SECONDS, 0), (MIN_SECONDS, BILLION - 1),
              (MAX_SECONDS, 0), (MAX_SECONDS, BILLION - 1),
              (-1, 0), (-1, BILLION - 1), (0, 0), (0, 1), (1, 0)]
    stamps += [divmod(value, BILLION) for value in edges]
    stamps += [(rng.randint(MIN_SECONDS, MAX_SECONDS), rng.randrange(BILLION))
               for _ in range(count)]
    for seconds, ns in stamps:
        delta = rng.choice(edges) if rng.getrandbits(1) else rng.randint(MIN_I64, MAX_I64)
        for operation in ("T", "B"):
            result = seconds * BILLION + ns + (delta if operation == "T" else -delta)
            result_seconds, result_ns = divmod(result, BILLION)
            expected = (f"{result_seconds}\t{result_ns}"
                        if MIN_SECONDS <= result_seconds <= MAX_SECONDS else "O")
            add(f"{operation}\t{seconds}\t{ns}\t{delta}", expected)
        other_seconds, other_ns = rng.choice(stamps)
        difference = (seconds - other_seconds) * BILLION + ns - other_ns
        add(f"X\t{seconds}\t{ns}\t{other_seconds}\t{other_ns}",
            str(difference) if MIN_I64 <= difference <= MAX_I64 else "O")
    for difference in edges + [MIN_I64 - 1, MAX_I64 + 1]:
        for base_seconds, base_ns in ((0, 0), (-1, BILLION - 1), (123456789, 7)):
            seconds, ns = divmod(base_seconds * BILLION + base_ns + difference, BILLION)
            expected = str(difference) if MIN_I64 <= difference <= MAX_I64 else "O"
            add(f"X\t{seconds}\t{ns}\t{base_seconds}\t{base_ns}", expected)
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--goose", default=os.environ.get("GOOSE", str(ROOT / ".toolchain/goose/build/goose")))
    parser.add_argument("--cases", type=int, default=2048)
    parser.add_argument("--mode", action="append", choices=("run", "debug", "build", "build-debug"))
    args = parser.parse_args()
    if not 1 <= args.cases <= 100000:
        parser.error("--cases must be in 1..100000")
    goose = shutil.which(args.goose) or str(Path(args.goose).resolve())
    rows = fixtures(args.cases)
    inputs = "\n".join(command for command, _ in rows) + "\n"
    expected = [result for _, result in rows]
    build = ROOT / ".build"
    build.mkdir(exist_ok=True)
    (build / "differential-input.tsv").write_text(inputs, encoding="ascii")
    (build / "differential-expected.tsv").write_text("\n".join(expected) + "\n", encoding="ascii")
    for mode in args.mode or ("run", "build-debug"):
        if mode in ("run", "debug"):
            command = [goose, "run", "tests/oracle.goose"]
            if mode == "debug":
                command.append("--debug")
        else:
            executable = build / ("oracle-" + mode)
            command = [goose, "build", "tests/oracle.goose", "-o", str(executable)]
            if mode == "build-debug":
                command.append("--debug")
            subprocess.run(command, cwd=ROOT, check=True, timeout=120)
            command = [str(executable)]
        result = subprocess.run(command, input=inputs, text=True, capture_output=True,
                                cwd=ROOT, timeout=120)
        (build / ("differential-" + mode + ".tsv")).write_text(result.stdout, encoding="ascii")
        actual = result.stdout.splitlines()
        if result.returncode != 0:
            raise AssertionError(f"{mode} exited {result.returncode}: {result.stderr[-4000:]}")
        if len(actual) != len(expected):
            raise AssertionError(f"{mode}: expected {len(expected)} lines, got {len(actual)}")
        for index, (observed, wanted) in enumerate(zip(actual, expected)):
            if observed != wanted:
                raise AssertionError(f"{mode} case {index}: {rows[index][0]!r}; expected {wanted!r}, got {observed!r}")
        print(f"{mode}: {len(rows)} deterministic datetime/integer oracle cases passed (seed 3339)")


if __name__ == "__main__":
    main()
