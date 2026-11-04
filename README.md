# goose-time

Small, pure time arithmetic and bounded RFC 3339 parsing/formatting for the
[Goose programming language](https://github.com/aardappel/goose). Apache-2.0.
Experimental interface; no tagged release or compatibility promise before 1.0.

Distinct durations, monotonic samples and Unix timestamps, checked integer
arithmetic, nanosecond precision, and Gregorian UTC dates in years 0001..9999.
No native dependencies, global clock, locale or timezone database. Applications
sample clocks; the same functions accept fixed values in tests.

## Quickstart

Requires Git, Make, Python 3, CMake 3.27+, C/C++20 compilers and libc development
headers. `make setup` builds the full upstream revision in GOOSE_REVISION with
optional graphics/audio disabled. GCC and Clang are needed for full validation.

```sh
make setup
make check test test-debug differential test-portable
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

See [contribution standards](CONTRIBUTING.md), [security](SECURITY.md),
[benchmark method](bench/README.md), and [validation evidence](docs/VALIDATION.md).
