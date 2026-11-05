# Validation evidence

Production source: bcbe9ea (the performance commit), after the reviewed internal
namespace split and month-prefix optimization. Documentation and validation-target
changes after that commit do not change either production source file.

Validated locally on Linux x86-64 with Goose revision
`eadca409f68210893f366e60d0c2f0dc29a339be` (runtime `3025e5810379`),
GCC 16.2.1 20260810 and Clang 23.1.4. The compiler checkout's full identity was
verified against GOOSE_REVISION. Initial local validation reused an existing
exact-pin compiler and did not include fresh compiler bootstrap or hosted CI.
The maintained [CI workflow](https://github.com/carabistouflette/goose-time/actions/workflows/ci.yml)
bootstraps that exact revision and runs the validation targets without timing
thresholds. Publication requires successful CI on the exact release commit;
immutable publication evidence is linked in the
[release notes](https://github.com/carabistouflette/goose-time/releases/tag/v0.1.0).

## Native Linux CI

The maintained workflow runs the same full validation targets on
`ubuntu-24.04` (x86-64) and `ubuntu-24.04-arm` (ARM64). Each job checks its actual
Linux architecture and 64-bit process environment, records OS/CPU/compiler tools,
bootstraps the pinned compiler, and verifies the full compiler checkout identity.
Compiler caches include OS and architecture to keep native executables separate.

Both jobs run contract and consumer-formatting regressions, normal/debug
runner and executable modes, Python differential and byte-mutation oracles,
GCC/Clang standalone debug tests, the complete Gregorian calendar enumeration,
and a benchmark correctness smoke. They use the same inputs and case counts;
there is no emulation or timing threshold in the workflow. Hosted ARM64 evidence
for this change is pending; actual outcomes and tool versions must be checked in
the Actions logs. Immutable run/job links and results must be recorded before
claiming completed ARM64 validation. A configured runner alone is not evidence
of a passed validation suite.

This CI addition preserves the production sources, API and compiler pin from
v0.1.0. It does not move that release tag or extend the historical local x86-64
measurements below to ARM64. No cross-architecture performance ranking or
Windows/macOS validation is claimed.

## Performed checks

- Format/type checks and example execution.
- Public-interface regression and hostile consumer-formatting tests in normal
  and debug runner/executable modes. Checks include i64 endpoints, subtraction
  of i64.min, invalid public fields, cancellation before multiplication overflow,
  atomic formatter rejection, offsets/fractions, and Gregorian boundaries.
- GCC and Clang standalone debug executables for both regression files.
- Independent Python datetime/integer oracle: 21,390 deterministic cases,
  seed 3339. Normal/debug runner, normal/debug executable, plus standalone
  debug executables under GCC and Clang. No float Unix timestamps.
- Independent Python regex/datetime parser oracle: 78,274 deterministic cases,
  seed 882, Clang standalone debug. Exhaustive byte substitutions and truncations
  of four fixture strings plus 50,000 arbitrary byte strings, safely transported
  as hex so NUL, line endings and non-ASCII reach the real public parser.
- Full 3,652,059-day calendar enumeration in years 0001..9999, GCC and Clang
  standalone debug. Expected seconds advance by one day independently of the
  library conversion algorithm. Normal regressions also cover one full
  146,097-day Gregorian cycle with fractional end-of-day timestamps.
- Benchmark smoke, Python syntax compilation, and `git diff --check`.
- Measurement-tool rejection of nonempty output directory, preserving the
  previous file bytes; benchmark checksums consume all formatted output bytes.
- Fresh local clone at bcbe9ea: format/type checks, normal/debug regression
  modes, GCC/Clang standalone regressions and differential cases, parser mutation
  corpus, full calendar enumeration and benchmark smoke all passed without any
  dependency on sibling library sources. It used the existing exact-pin compiler.

Three independent reviewers challenged design, arithmetic/bounds, test coverage,
and measurement quality across several checkpoints. Actionable findings were
addressed: unchecked helpers moved to unsupported time_detail, benchmark output
reuse rejected, and all formatted bytes included in benchmark checksums. The
profiled month-table change received a separate full-calendar review/check.

## Reproduce

From a standalone checkout, run `make setup`, then:

```sh
make check test test-debug differential test-portable fuzz test-calendar
make bench BENCH_ITERATIONS=100
```

To reuse an exact-pin compiler, pass `GOOSE=/absolute/path/to/goose` to make.
`make differential` runs all four runner/executable modes; `test-portable` adds
GCC/Clang standalone differential coverage. Fuzz seeds and input/expected/actual
TSV files are retained under .build. No generated executables are tracked.

The [measured optimization](../bench/results/month-prefix/README.md) retains all
raw batches, source hashes, platform/compiler provenance, and the original
sampling profile. Measurements are not latency guarantees. No exhaustive proof
of arbitrary malformed input, allocator failure recovery, or validation on
Windows/macOS/other architectures beyond the recorded evidence is claimed. This
core contains no native code.
