# goose-time

Small, pure time arithmetic and bounded RFC 3339 parsing/formatting for the
[Goose programming language](https://github.com/aardappel/goose). Apache-2.0.
Experimental 0.1.1 maintenance release; runtime and public interface unchanged
from 0.1.0. No compatibility promise before 1.0.
Validated locally on Linux x86-64 and in maintained CI on native Linux x86-64,
Linux ARM64 and macOS ARM64; see the recorded [Linux](docs/NATIVE-LINUX-2026-11-05.md)
and [macOS](docs/NATIVE-MACOS-2026-11-05.md) results. Other platforms are not yet
validated.

Distinct durations, monotonic samples and Unix timestamps, checked integer
arithmetic, nanosecond precision, and Gregorian UTC dates in years 0001..9999.
No native dependencies, global clock, locale or timezone database. Applications
sample clocks; the same functions accept fixed values in tests.

## Quickstart

Requires Git, Make, Python 3, CMake 3.27+, C/C++20 compilers and libc development
headers. `make setup` builds the full upstream revision in GOOSE_REVISION with
optional graphics/audio disabled. GCC and Clang are needed for full validation.
`GCC_CC` and `CLANG_CC` select the standalone test compilers (defaults: `gcc`
and `clang`). macOS CI resolves `gcc-15` to an absolute path and uses
`/usr/bin/clang`; `CC`, `CXX` and `GOOSE_CC` explicitly select Apple Clang for
compiler bootstrap and default
generated executables. `BENCH_CC` selects the benchmark compiler separately.
For local macOS validation, use the compiler environment in the hosted record.

```sh
git clone https://github.com/carabistouflette/goose-time.git
cd goose-time
make setup
make check test test-debug differential test-portable fuzz test-calendar
.toolchain/goose/build/goose run examples/timestamps.goose
```

From a program next to a checkout named goose-time:

```goose
import std;
import time from "../goose-time";

fn main() {
    let stamp, error = time::parse_rfc3339("2026-11-04T18:30:00.125+01:00");
    assert(error == time::Error.None);
    var out: u8[>..] = [];
    assert(time::append_rfc3339(out, stamp) == time::Error.None);
    print(out); // 2026-11-04T17:30:00.125Z
}
```

Declare sourced imports in the application's root file. Assertions keep this
example short; applications should handle errors. See the [interface contract](docs/API.md)
for exact ranges, operations and error/ownership behavior. Formatting appends;
failure leaves existing output unchanged. Invalid public structs are rejected.

The supported RFC 3339 profile consumes at most 35 bytes. It accepts numeric
offsets and up to nine fractional digits; rejects leap seconds, year zero,
unknown-local-offset `-00:00`, and trailing bytes. Formatting normalizes to UTC
and removes trailing fractional zeroes. It preserves instants, not source spelling
or source offset metadata. Calendar arithmetic excludes leap seconds.

For a reproducible Git import, the reviewed implementation can be pinned as
`import time from "carabistouflette/goose-time@bcbe9ea24990467fbe3aa8f5b122212aa539d5c0";`.
That implementation commit is unchanged in the experimental
[release](https://github.com/carabistouflette/goose-time/releases/tag/v0.1.1);
maintenance changes update documentation, CI and test compiler selection.

See [contribution standards](CONTRIBUTING.md), [security](SECURITY.md),
[benchmark method](bench/README.md), and [validation evidence](docs/VALIDATION.md).
