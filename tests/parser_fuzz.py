#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Reproducible byte-mutation checks against an independent RFC 3339 profile.

Python regex/datetime implement the oracle; the Goose parser sees hex-transported
arbitrary bytes, including NUL, LF, CR, and non-ASCII. No native-time conversions,
floating-point timestamps, third-party modules, or network access are used.
"""
import argparse
import datetime as dt
import os
from pathlib import Path
import random
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PATTERN = re.compile(
    rb"([0-9]{4})-([0-9]{2})-([0-9]{2})[Tt]"
    rb"([0-9]{2}):([0-9]{2}):([0-9]{2})"
    rb"(?:\.([0-9]{1,9}))?([Zz]|[+-][0-9]{2}:[0-9]{2})"
)


def expected(source):
    if len(source) > 35:
        return "E"
    match = PATTERN.fullmatch(source)
    if match is None:
        return "E"
    fields = match.groups()
    try:
        local = dt.datetime(*map(int, fields[:6]))
        suffix = fields[7]
        offset = 0
        if len(suffix) > 1:
            hours, minutes = int(suffix[1:3]), int(suffix[4:])
            if hours > 23 or minutes > 59 or suffix == b"-00:00":
                return "E"
            offset = (hours * 60 + minutes) * (1 if suffix[:1] == b"+" else -1)
        utc = local - dt.timedelta(minutes=offset)
    except (ValueError, OverflowError):
        return "E"
    elapsed = utc - dt.datetime(1970, 1, 1)
    seconds = elapsed.days * 86400 + elapsed.seconds
    nanos = int((fields[6] or b"").ljust(9, b"0"))
    return f"{seconds}\t{nanos}"


def corpus(random_cases):
    rng = random.Random(882)
    sources = []
    for base in (b"1970-01-01T00:00:00Z",
                 b"2000-02-29T12:34:56.123456789+23:59",
                 b"0001-01-01T00:00:00-00:00",
                 b"9999-12-31T23:59:59.999999999Z"):
        for position in range(len(base)):
            for byte in range(256):
                sources.append(base[:position] + bytes([byte]) + base[position + 1:])
        for length in range(len(base) + 1):
            sources.append(base[:length])
    for _ in range(random_cases):
        sources.append(bytes(rng.randrange(256) for _ in range(rng.randrange(50))))
    return sources


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--goose", default=os.environ.get("GOOSE", str(ROOT / ".toolchain/goose/build/goose")))
    parser.add_argument("--cc", default="clang", help="C compiler for executable")
    parser.add_argument("--standalone", action="store_true")
    parser.add_argument("--mode", choices=("build", "build-debug"), default="build-debug")
    parser.add_argument("--cases", type=int, default=50000, help="Arbitrary byte cases, in addition to fixed mutations")
    args = parser.parse_args()
    if not 1 <= args.cases <= 200000:
        parser.error("--cases must be in 1..200000")
    goose = shutil.which(args.goose) or str(Path(args.goose).resolve())
    sources = corpus(args.cases)
    inputs = "\n".join("Q\t" + source.hex() for source in sources) + "\n"
    wanted = [expected(source) for source in sources]
    build = ROOT / ".build"
    build.mkdir(exist_ok=True)
    (build / "parser-fuzz-input.tsv").write_text(inputs, encoding="ascii")
    (build / "parser-fuzz-expected.tsv").write_text("\n".join(wanted) + "\n", encoding="ascii")
    executable = build / "parser-fuzz-oracle"
    command = [goose, "build", "tests/oracle.goose", "--cc", args.cc, "-o", str(executable)]
    if args.mode == "build-debug":
        command.append("--debug")
    if args.standalone:
        command.append("--standalone")
    subprocess.run(command, cwd=ROOT, check=True, timeout=120)
    result = subprocess.run([str(executable)], input=inputs, text=True, capture_output=True,
                            cwd=ROOT, timeout=120)
    (build / "parser-fuzz-actual.tsv").write_text(result.stdout, encoding="ascii")
    actual = result.stdout.splitlines()
    if result.returncode != 0:
        raise AssertionError(f"parser oracle exited {result.returncode}: {result.stderr[-4000:]}")
    if len(actual) != len(wanted):
        raise AssertionError(f"expected {len(wanted)} result lines, got {len(actual)}")
    for index, (observed, correct) in enumerate(zip(actual, wanted)):
        if observed != correct:
            raise AssertionError(f"case {index}, bytes={sources[index].hex()}: expected {correct!r}, got {observed!r}")
    print(f"{len(sources)} byte-mutation/parser oracle cases passed (seed 882; {args.cc}, {args.mode}, standalone={args.standalone})")


if __name__ == "__main__":
    main()
