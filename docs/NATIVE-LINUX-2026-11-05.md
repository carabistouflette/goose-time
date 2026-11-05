# Native Linux validation — 2026-11-05

The first native ARM64 validation passed at source head
`f5ae02e4fa719b4c88e0cbeacfeb9057ae1e02ca`. Both maintained CI runs completed
successfully, with all four jobs below passing. The push checkout was that head;
the PR checkout was synthetic merge `f144924a2eec58818ef5469fd3dcc19333b211c6`
against base `343887caeee0a1f4e2e536ff322fcafb454e11bd`. Its complete Git tree
was verified identical to the tested head. Later documentation and main-branch
CI runs are separate evidence rather than part of these recorded runs.

| Event | Native runner | Job | Observed CPU |
| --- | --- | --- | --- |
| Push | `ubuntu-24.04-arm`, `aarch64` | [linux-arm64](https://github.com/carabistouflette/goose-time/actions/runs/42002680287/job/127161567000) | Neoverse-N2 |
| PR | `ubuntu-24.04-arm`, `aarch64` | [linux-arm64](https://github.com/carabistouflette/goose-time/actions/runs/42002689868/job/127161599958) | Neoverse-N2 |
| Push | `ubuntu-24.04`, `x86_64` | [test](https://github.com/carabistouflette/goose-time/actions/runs/42002680287/job/127161567526) | AMD EPYC 9V74 |
| PR | `ubuntu-24.04`, `x86_64` | [test](https://github.com/carabistouflette/goose-time/actions/runs/42002689868/job/127161599672) | AMD EPYC 9V45 |

## Recorded provenance

All four jobs asserted Linux, their actual expected `uname -m`, and a 64-bit
process environment before building. Their logs report Ubuntu 24.04.5 LTS,
GCC 13.3.0 (`13.3.0-6ubuntu2~24.04.1`), Ubuntu Clang 18.1.3 (`1ubuntu1`),
CMake 3.31.6 and Python 3.12.3. GCC reported `aarch64-linux-gnu` on ARM64 and
`x86_64-linux-gnu` on x86-64; Clang reported `aarch64-unknown-linux-gnu` and
`x86_64-pc-linux-gnu`, respectively.

Every job reported a compiler-cache miss and built the pinned upstream compiler
from source. Each verified checkout identity
`eadca409f68210893f366e60d0c2f0dc29a339be` and printed
`goose eadca40 (runtime 3025e5810379)`. The ARM64 and x86-64 caches use distinct
`runner.arch` keys. The workflow uses native hosted runners, without an emulation
or cross-compilation setup.

## Completed workload

Both architectures ran the same commands and deterministic inputs:

```sh
make setup
make check test test-debug differential test-portable fuzz test-calendar
make bench BENCH_ITERATIONS=100
```

Each of the four job logs confirms:

- Format/type, public-interface and hostile consumer-formatting checks; normal
  and debug runner/executable tests, including example execution.
- 21,390 datetime/integer oracle cases per mode, seed 3339: normal/debug runners,
  normal/debug executables, and GCC/Clang standalone debug executables (six modes).
- 78,274 byte-mutation/parser oracle cases, seed 882, Clang standalone debug.
- Both GCC and Clang standalone debug calendar sweeps completed. The unchanged
  test enumerates all 3,652,059 days in years 0001..9999.
- All nine benchmark fixtures completed at 100 iterations. Their checksums
  matched across the four jobs. This checks execution/output consumption;
  no timing thresholds or cross-architecture performance conclusions are drawn.

## Source identity and limits

Production files, test inputs, Makefile, bootstrap script and compiler pin are
unchanged from released `343887caeee0a1f4e2e536ff322fcafb454e11bd`:

| Production file | SHA-256 |
| --- | --- |
| `time.goose` | `9a43e3f14b838ab7f40e9968ce35c0972f23cfd663408d773bff67da491cb2b7` |
| `detail.goose` | `54e54e81fa2efc3efb00d380f19ca46af5ca728fbc8e9004d562c965357754d6` |

This establishes the recorded compiler/workload results on native hosted Linux
x86-64 and ARM64. It is not exhaustive malformed-input or allocator-failure
coverage, a performance ranking, or validation of Windows, macOS, other ARM
environments or other architectures. The API and v0.1.0 tag remain unchanged.
