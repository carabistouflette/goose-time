# API reference

The `time` namespace provides deterministic integer operations. It uses Goose's
standard library and contains no native code. Only formatting can grow a
caller-owned output buffer; the other operations do not allocate.

## Values

`Duration { nanoseconds: i64 }` is a signed interval, roughly ±292 years.
`Unit` contains `Nanosecond`, `Microsecond`, `Millisecond`, `Second`, `Minute`,
`Hour` and `Day`. A `Day` is always 86,400 seconds.

`Instant { nanoseconds: i64 }` holds a caller-supplied monotonic clock reading.
Only compare or subtract readings from the same clock domain. Do not persist
them across processes or interpret them as wall-clock dates. Nanosecond storage
does not guarantee a nanosecond-resolution clock; resolution and accuracy come
from the clock you supply. The library cannot check clock-domain identity.

`Timestamp { seconds: i64, nanoseconds: i64 }` holds Unix seconds, excluding leap
seconds, and a fraction in `0..999999999`. Seconds must fall in
`-62135596800..253402300799`, covering UTC years 0001..9999.
For example, `{ -1, 500000000 }` is half a second before the epoch.

`Calendar { year, month, day, hour, minute, second, nanosecond }` has `i64`
fields. It uses the proleptic Gregorian calendar in UTC: year 1..9999, month
1..12, a valid day for that month, hour 0..23, minute/second 0..59, and
nanosecond 0..999999999. There are no leap seconds or timezone rules.

You can construct these structs directly. Timestamp and calendar operations
check their fields; invalid fields are rejected rather than normalized.

Public constants are `NANOSECONDS_PER_SECOND = 1000000000`,
`MIN_SECONDS = -62135596800`, `MAX_SECONDS = 253402300799`, and
`MAX_INPUT_BYTES = 35`.

## Errors

Fallible value-producing operations return `(value, error)`. On error, the value
is zero/default-initialized and must be discarded. The formatter returns only
an error. `Error` has these values:

| Error | Meaning |
| --- | --- |
| `None` | Success |
| `Invalid` | A field is outside its allowed range, such as an invalid date |
| `Overflow` | The result cannot fit the destination type or supported calendar range |
| `Syntax` | Text does not match the accepted timestamp layout |
| `Unsupported` | A feature outside the profile, such as more than nine fractional digits or `-00:00` |
| `TooLong` | Input exceeds 35 bytes; length is checked before parsing fields |

Allocation failure follows Goose runtime behavior; it is not a recoverable `Error`.

## Operations

- `duration(i64, Unit) -> Duration, Error`
- `add(Duration, Duration)`, `subtract(Duration, Duration) -> Duration, Error`
- `add(Instant, Duration)`, `subtract(Instant, Duration) -> Instant, Error`
- `difference(Instant, Instant) -> Duration, Error` — first minus second
- `add(Timestamp, Duration)`, `subtract(Timestamp, Duration) -> Timestamp, Error`
- `difference(Timestamp, Timestamp) -> Duration, Error` — first minus second
- `from_unix_nanoseconds(i64) -> Timestamp`
- `to_unix_nanoseconds(Timestamp) -> i64, Error`
- `from_calendar(Calendar) -> Timestamp, Error`
- `to_calendar(Timestamp) -> Calendar, Error`
- `parse_rfc3339(const u8[:]) -> Timestamp, Error`
- `append_rfc3339(u8[>..]&, Timestamp) -> Error`

Arithmetic checks representability before operations that could overflow,
including in release builds. Subtraction does not negate its second operand,
so `i64.min` can be used without negation overflow.

`from_unix_nanoseconds` accepts the full signed `i64` range and normalizes a
negative fraction. The reverse conversion can overflow: the supported calendar
range is much wider than signed `i64` nanoseconds. Similarly, the difference
between valid timestamps may be too large for `Duration`.

Calendar conversion uses arithmetic Gregorian cycles; it does not iterate over years.

## Timestamp text

The parser accepts this limited [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339)
profile, consuming the entire input:

```text
YYYY-MM-DDTHH:MM:SS[.1..9 digits](Z|+HH:MM|-HH:MM)
```

Lowercase `t` and `z` are accepted. Numeric offset hours are 00..23 and minutes
00..59. Both the input calendar date and the normalized UTC date must stay in
years 0001..9999. Spaces, NUL, non-ASCII, missing fields, trailing bytes, year
zero, 24:00, invalid dates and second 60 are rejected. More than nine fractional
digits and `-00:00` return `Unsupported` when the input is within the 35-byte limit.
The latter is rejected because the library does not preserve unknown-local-offset metadata.

Formatting appends 20..30 ASCII bytes with uppercase `T` and `Z`, normalizes to
UTC and removes trailing fractional zeroes. Whole seconds have no fraction.
It preserves the instant, not the input's spelling or offset.

The formatter validates before appending, so returned errors leave existing
output unchanged. The caller owns output; parsing retains no input. Goose's
lifetime rules prohibit borrowing an output builder while mutating it.
Formatting writes ASCII digits directly and does not call consumer-defined formatters.

`time_detail` is an unsupported implementation namespace. Its helpers require
validated inputs and must not be called by applications.
