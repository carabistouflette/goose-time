# Native macOS ARM64 validation — 2026-11-05

Both initial native macOS jobs passed at head
`6b98ab84854d9411d571a2926585c447ad5274c6`, alongside all four Linux jobs.
The push checkout was that head. The PR used synthetic merge
`10c0d6aec1fef2bdcd20685bc6123b8d4cc16b28` against base
`83e7ce385dab0c356b060beab8b0af8192564703`; its complete tree
`08dc0a9b82b2bfa2cdbf04c69e5530b409b17dff` was verified identical to the head.
Later documentation/main runs are separate evidence from these initial runs.

| Event | Platform | Passed job |
| --- | --- | --- |
| Push | Native macOS ARM64 | [macos-arm64](https://github.com/carabistouflette/goose-time/actions/runs/42008171018/job/127180120565) |
| PR | Native macOS ARM64 | [macos-arm64](https://github.com/carabistouflette/goose-time/actions/runs/42008180620/job/127180153602) |
| Push | Native Linux x86-64 | [test](https://github.com/carabistouflette/goose-time/actions/runs/42008171018/job/127180120146) |
| PR | Native Linux x86-64 | [test](https://github.com/carabistouflette/goose-time/actions/runs/42008180620/job/127180153213) |
| Push | Native Linux ARM64 | [linux-arm64](https://github.com/carabistouflette/goose-time/actions/runs/42008171018/job/127180120457) |
| PR | Native Linux ARM64 | [linux-arm64](https://github.com/carabistouflette/goose-time/actions/runs/42008180620/job/127180153425) |

## Observed macOS provenance

Both `macos-15` jobs asserted Darwin and `arm64`. Their logs report:

- macOS 15.8.2, build 24H232; Darwin 24.6.0; Apple M1 (Virtual).
- Xcode 16.4, build 16F6, with selected SDK 15.5.
- Apple Clang 17.0.0 (`clang-1700.0.13.5`), target
  `arm64-apple-darwin24.6.0`, selected explicitly through `/usr/bin/clang`.
- GNU GCC 15.3.0 (Homebrew), target `aarch64-apple-darwin24`, resolved to
  `/opt/homebrew/bin/gcc-15`. Its predefines passed the GNU check and contained
  no `__clang__` alias marker.
- CMake 4.4.4 and Python 3.15.2.

Both reported a compiler-cache miss and built the pinned upstream compiler from
source with Apple Clang. They verified full checkout identity
`eadca409f68210893f366e60d0c2f0dc29a339be` and printed
`goose eadca40 (runtime 3025e5810379)`. The compiler cache separates OS and
architecture. Native hosted macOS VMs were used without an emulation or
cross-compilation setup.

## Completed workload and reproduction

The macOS compiler environment was:

```sh
export CC=/usr/bin/clang CXX=/usr/bin/clang++ GOOSE_CC=/usr/bin/clang
export GCC_CC="$(command -v gcc-15)" CLANG_CC=/usr/bin/clang
export BENCH_CC=/usr/bin/clang
test -x "$GCC_CC"
make setup
make check test test-debug differential test-portable fuzz test-calendar
make bench BENCH_ITERATIONS=100
```

GNU GCC 15 must be available for that reproduction. The workflow additionally
checks compiler predefines and requires the resolved GCC path to be absolute:
the pinned Goose accepts built-in compiler names or paths, not bare `gcc-15`.

Each macOS log confirms format/type checks, public-interface/hostile-formatting
tests, normal/debug runner and executable modes, and example execution.
Standalone regressions and complete calendar sweeps ran under both GNU GCC and
Apple Clang. Default generated executables and benchmark smoke used Apple Clang.

Each also confirms 21,390 datetime/integer oracle cases per mode (seed 3339)
across six modes: normal/debug runners, normal/debug executables, and standalone
debug executables for each compiler. The parser mutation oracle passed 78,274
cases (seed 882), standalone debug under Apple Clang. Both compiler calendar
sweeps enumerated all 3,652,059 days in years 0001..9999 using the unchanged test.

All nine benchmark fixtures completed at 100 iterations. Their checksums matched
between both macOS jobs and the companion Linux push jobs. This is correctness
smoke/output-consumption evidence; no timings or platform speed ranking are
inferred. The existing Linux jobs, case counts and compiler defaults were retained.

## Source identity and limits

Production files, public API, test inputs, bootstrap script and compiler pin are
unchanged from the v0.1.0 source. Only compiler argument selection was added to
the Makefile; it defaults to the previous GCC/Clang commands on Linux.

| Production file | SHA-256 |
| --- | --- |
| `time.goose` | `9a43e3f14b838ab7f40e9968ce35c0972f23cfd663408d773bff67da491cb2b7` |
| `detail.goose` | `54e54e81fa2efc3efb00d380f19ca46af5ca728fbc8e9004d562c965357754d6` |

The record covers the observed hosted macOS ARM64 environment and compilers.
It is not a guarantee for other macOS versions, Intel Macs, Windows, arbitrary
toolchains, allocator failures, or exhaustive malformed input. Historical Linux
performance measurements remain scoped to their original machines. The v0.1.0
tag remains unchanged; no new release tag or runtime dependency was introduced.
