# Historical benchmark source check

This audit retains the [November 4 month-prefix measurements](results/month-prefix/README.md)
as historical Linux x86-64 results. It does not claim a new timing run. The check
compares measured file hashes, not the age of the captures.

## Library and harness

The optimized capture's five hashes match source commit
`7c3f93cb8b398476c8ef88afe90204711ee26951` (v0.1.1). They also match performance
commit `bcbe9ea24990467fbe3aa8f5b122212aa539d5c0` and v0.1.0. Main's documentation
changes do not change these files. The two production files are `time.goose` and
`detail.goose`; this library has no vendored runtime dependencies.

| File | SHA-256 in optimized capture and v0.1.1 |
| --- | --- |
| `time.goose` | `9a43e3f14b838ab7f40e9968ce35c0972f23cfd663408d773bff67da491cb2b7` |
| `detail.goose` | `54e54e81fa2efc3efb00d380f19ca46af5ca728fbc8e9004d562c965357754d6` |
| `bench/bench.goose` | `c9045917d1ccfd5b8a4460a5b4b012e9f412c2a974fa9034eb8050054f2aaaff` |
| `bench/measure.py` | `335505801cc7e31fb9dbcb1fc5d0c6806a1a3eabe0f04a1c091f8f04f5647be6` |
| `GOOSE_REVISION` | `64e14b181dfe96743211738fb0f1b1f7798ea940da2ca50ff122e6f028c24e15` |

The baseline's production hashes match
`1ccea5a3c264bc3ce2cbdd0662bc3b4c54139984`; both captures use the same revised
harness and recorder hashes above. Optimized capture metadata still names that
baseline commit with a dirty working tree: its hashes, rather than the commit
label alone, identify the measured implementation. The final production change
replaces the month-accumulation loop in `from_calendar` with a 12-entry table and
leap adjustment; `to_calendar` retains its bounded month scan.

All 14 retained CSVs were checked: nine fixtures per batch, 1,000,000 iterations,
matching checksums across seven batches per version. All 18 median/min/max cells
in the report recompute from those files. No historical CSV, JSON or profile was
rewritten.

## Compiler source and executable limits

Both captures declare Goose revision
`eadca409f68210893f366e60d0c2f0dc29a339be` and report
`goose eadca40 (runtime 3025e5810379)`, with GCC `16.2.1 20260810`.
The audit inspected the original selected compiler checkout and the separate
compiler checkout used for release acceptance: both were clean at that full
revision. Their `std.goose`, `os.goose`, runtime sources, generated runtime
header and build logic match byte-for-byte. The current GCC banner also matches.

This establishes a source/runtime-source match, not identical executable builds.
At audit time the original selected Goose executable hashed to
`7ffde13da95fbbdaa15b27419494fc9b71f2c91c0b4c4d732f51815e928a4b56`;
the release-acceptance compiler hashed to
`5e5bd97c13d8f4902855e6bbd2df1be510b81f13fe92a2482c9ac5e208bdb7a9`.
The historical captures did not record Goose/GCC executable digests, resolved
shared-library hashes or a compiled runtime-object identity. Present-day hashes
cannot fill that historical gap. The metadata's declared pin and version output
alone would not prove the full compiler checkout.

The unchanged implementation and checked source match support retaining the
original machine-scoped results without another timing campaign. They do not
establish current performance for a different compiler binary, dependency build,
OS or machine. Those claims would need a new capture with those identities.

## Recheck without measuring

From a checkout of the release, this verifies the optimized hashes:

```sh
python3 - <<'PY'
import hashlib, json
from pathlib import Path
m = json.loads(Path('bench/results/month-prefix/optimized/metadata.json').read_text())
for name, expected in m['sha256'].items():
    actual = hashlib.sha256(Path(name).read_bytes()).hexdigest()
    assert actual == expected, name
    print(name, actual)
PY
```

Raw [baseline](results/month-prefix/baseline/metadata.json) and
[optimized](results/month-prefix/optimized/metadata.json) metadata retain the
original dirty status, build commands, tool versions, CPU and OS. Full compiler
source verification additionally requires inspecting the selected compiler's
checkout; binary hashes and version strings cannot replace it.
