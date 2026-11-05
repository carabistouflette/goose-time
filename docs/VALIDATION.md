# Validation

The current release, [v0.1.1](https://github.com/carabistouflette/goose-time/releases/tag/v0.1.1),
contains source commit `7c3f93cb8b398476c8ef88afe90204711ee26951`.
Its tree equals the tested release candidate `7cb7e23ae52696ef47fc4d087214aeefee741dcb`.
All three native platforms passed in both candidate runs:

| Platform | Candidate checks | Earlier platform record |
| --- | --- | --- |
| Linux x86-64 | [Push](https://github.com/carabistouflette/goose-time/actions/runs/42082297138), [PR](https://github.com/carabistouflette/goose-time/actions/runs/42082639437) | [Linux tools and results](NATIVE-LINUX-2026-11-05.md) |
| Linux ARM64 | Same two runs, `linux-arm64` job | [Linux tools and results](NATIVE-LINUX-2026-11-05.md) |
| macOS ARM64 | Same two runs, `macos-arm64` job | [macOS tools and results](NATIVE-MACOS-2026-11-05.md) |

The release notes link archive and Git-import acceptance details. The earlier
platform records retain their original commits, job links and observed tools;
they do not describe later CI runs. Current main-branch results are available in
the [CI workflow](https://github.com/carabistouflette/goose-time/actions/workflows/ci.yml).

## What is checked

Each platform uses Goose source revision
`eadca409f68210893f366e60d0c2f0dc29a339be` (runtime `3025e5810379`).
CI builds or restores that compiler, verifies its full checkout identity, and
records the actual architecture, OS and compiler versions. Caches separate OS
and architecture. These are native runs, without emulation.

- Formatting and type checks, example execution, and public API regressions.
  Cases cover signed integer endpoints, subtraction of `i64.min`, invalid fields,
  offsets/fractions, calendar boundaries and unchanged output on formatter errors.
  A consumer test also supplies competing formatting overloads.
- Normal/debug runners and executables, plus GCC/Clang standalone debug builds.
- An independent Python datetime/integer oracle: 21,390 deterministic cases per
  mode, seed 3339, across all six modes. Expected timestamps use integer arithmetic.
- An independent Python regex/datetime parser oracle: 78,274 cases, seed 882,
  under standalone debug Clang. It substitutes bytes and truncates four fixtures,
  then adds 50,000 arbitrary byte strings. Hex transport preserves NUL and non-ASCII.
- Full calendar enumeration under both GCC and Clang: all 3,652,059 days in
  years 0001..9999, with expected seconds advancing independently by one day.
  Normal regressions also cover a 146,097-day Gregorian cycle with fractions.
- Execution and checksum checks for all nine benchmark fixtures. CI does not
  enforce timing thresholds or establish platform performance comparisons.

The release's production files and compiler pin are unchanged from v0.1.0.
The [benchmark currentness record](../bench/CURRENTNESS.md) compares those source
identities with the historical measured implementation.

## Run the checks

A standalone checkout needs the [quickstart prerequisites](../README.md#try-it),
Python 3, GNU GCC and Clang. On Linux, the defaults are `gcc` and `clang`:

```sh
make setup
make check test test-debug differential test-portable fuzz test-calendar
make bench BENCH_ITERATIONS=100
git diff --check
```

To reuse a compiler, pass `GOOSE=/absolute/path/to/goose` to make after verifying
its source checkout matches `GOOSE_REVISION`. `make check` checks formatting and
types; `make test` also runs a ten-iteration benchmark smoke. `make differential`
runs four runner/executable modes; `test-portable` adds both standalone compilers.
Generated programs and oracle inputs/results stay under `.build`.

On macOS, install GNU GCC 15 as well as the Apple command-line tools. Select
compilers explicitly before the commands above:

```sh
export CC=/usr/bin/clang CXX=/usr/bin/clang++ GOOSE_CC=/usr/bin/clang
export GCC_CC="$(command -v gcc-15)" CLANG_CC=/usr/bin/clang
export BENCH_CC=/usr/bin/clang
test -x "$GCC_CC"
```

The pinned Goose accepts built-in compiler names or absolute paths, so resolve
`gcc-15` rather than passing that bare name. CI checks that it is GNU GCC, not a
Clang alias. See the macOS record for the observed SDK and tool versions.

## Documentation examples

The current README's examples were checked against the published v0.1.1 source
above using a clean checkout of the pinned compiler. A fresh public tag clone's
`examples/timestamps.goose` printed `2026-11-04T17:31:30.125Z`. The README's
exact-commit Git import printed `2026-11-04T17:30:00.125Z` in normal and debug
runners, starting with an empty package cache. Formatting and type checks also passed.

These local checks reused an already built compiler. The unchanged `make setup`
bootstrap is covered by the recorded release CI; it was not rebuilt locally for
this prose update. No new performance measurements were made.

## Scope

These results cover the recorded native Linux x86-64/ARM64 and macOS ARM64
environments. Windows, Intel Macs and other toolchains remain unvalidated.
Tests do not prove correctness for every malformed byte string or cover
allocator failure recovery. The library contains no native code.

[Historical measurements](../bench/results/month-prefix/README.md) remain scoped
to their original Linux x86-64 machine. They are not latency guarantees.
