#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Record whole benchmark batches and provenance, without timing thresholds."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def capture(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()

def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--goose', default=os.environ.get('GOOSE', '.toolchain/goose/build/goose'))
    parser.add_argument('--cc', default='gcc')
    parser.add_argument('--iterations', type=int, default=1000000)
    parser.add_argument('--runs', type=int, default=7)
    parser.add_argument('--output', type=Path, default=ROOT / '.build' / 'measure')
    args = parser.parse_args()
    if not 1 <= args.iterations <= 100000000 or not 1 <= args.runs <= 100:
        parser.error('iterations must be 1..100000000; runs 1..100')
    output = args.output.resolve()
    if output.exists() and any(output.iterdir()):
        parser.error("--output must be an empty or new directory; refusing to mix samples")
    output.mkdir(parents=True, exist_ok=True)
    binary = ROOT / '.build' / 'bench-measure'
    binary.parent.mkdir(exist_ok=True)
    command = [args.goose, 'build', 'bench/bench.goose', '--cc', args.cc, '-O2', '-o', str(binary)]
    subprocess.run(command, cwd=ROOT, check=True)
    source = ['time.goose', 'detail.goose', 'bench/bench.goose', 'bench/measure.py', 'GOOSE_REVISION']
    metadata = {
        'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'source_commit': capture('git', 'rev-parse', 'HEAD'),
        'working_tree': capture('git', 'status', '--short'),
        'sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in source},
        'goose_revision': (ROOT / 'GOOSE_REVISION').read_text().strip(),
        'goose_version': capture(args.goose, '--version'),
        'cc_version': capture(args.cc, '--version'),
        'platform': platform.platform(), 'cpu': capture('lscpu'),
        'build_command': command, 'iterations': args.iterations, 'runs': args.runs,
        'warmup_batches': 1,
    }
    (output / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    subprocess.run([str(binary), str(args.iterations)], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    for batch in range(args.runs):
        raw = capture(str(binary), str(args.iterations))
        (output / f'run-{batch + 1}.csv').write_text(raw + '\n')
    print(f'Recorded {args.runs} batches in {output}')

if __name__ == '__main__':
    main()
