# goose-time

A [Goose](https://github.com/aardappel/goose) library for durations, Unix
timestamps and UTC dates. Parse and format a limited RFC 3339 timestamp format,
convert calendar dates, and do checked integer arithmetic.

The current release is [v0.1.1](https://github.com/carabistouflette/goose-time/releases/tag/v0.1.1),
an experimental release with no compatibility promise before 1.0. Main-branch
docs may be newer than the tagged release. The quickstart below checks out the tag.

## Try it

Building Goose requires Git, Make, CMake 3.27+, C/C++20 compilers and libc
development headers. The setup script builds the compiler pinned by this project.

```sh
git clone --branch v0.1.1 https://github.com/carabistouflette/goose-time.git
cd goose-time
make setup
.toolchain/goose/build/goose run examples/timestamps.goose
```

The example prints `2026-11-04T17:31:30.125Z`.

## Use it

This program imports the exact v0.1.1 source commit:

```goose
import std;
import time from "carabistouflette/goose-time@7c3f93cb8b398476c8ef88afe90204711ee26951";

fn main() {
    let stamp, error = time::parse_rfc3339("2026-11-04T18:30:00.125+01:00");
    assert(error == time::Error.None);
    var out: u8[>..] = [];
    assert(time::append_rfc3339(out, stamp) == time::Error.None);
    print(out); // 2026-11-04T17:30:00.125Z
}
```

Put the import in your application's root file. Assertions keep this example
short; applications should check returned errors. For a local checkout, use
`import time from "../goose-time";` instead.

| Type | Represents |
| --- | --- |
| `Duration` | A signed interval in integer nanoseconds |
| `Instant` | A reading supplied by the caller's monotonic clock |
| `Timestamp` | Unix seconds and a nanosecond fraction |
| `Calendar` | Gregorian UTC date and time fields |

## Limits

- The library contains no native code and reads no clocks. Your clock determines
  actual measurement resolution and accuracy; nanoseconds are the storage unit.
- Arithmetic returns errors instead of wrapping, including in release builds.
  Calendar dates cover years 0001..9999; signed 64-bit nanoseconds cover a narrower range.
- Parsing consumes the complete input, at most 35 bytes, with up to nine
  fractional digits. It accepts numeric UTC offsets, but rejects leap seconds,
  year zero, `-00:00` and trailing text. There is no timezone database or daylight-saving policy.
- Formatting appends canonical UTC text to your buffer. It drops the original
  spelling/offset and trims fractional zeroes. Returned errors leave existing output unchanged.

Validation covers native Linux x86-64/ARM64 and macOS ARM64. Other platforms are
not yet validated. See the [API reference](docs/API.md) for exact ranges, signatures
and errors; [validation](docs/VALIDATION.md) for platform results and test commands;
and [benchmarks](bench/README.md) for the historical measurements and their scope.

[Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [Apache-2.0 license](LICENSE)
