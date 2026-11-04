# Experimental time interface

Pure Goose; no runtime dependency beyond `std`, no native code. Deterministic
and allocation-free except formatter builder growth. Applications sample `os`
clocks and pass values; tests pass fixed values. No global clocks, locale,
timezone database, daylight saving or leap seconds.

## Values and errors

`Duration { nanoseconds: i64 }` is a signed nanosecond interval (~292 years).
`Instant { nanoseconds: i64 }` is a caller-supplied monotonic reading. Only
subtract readings from the same clock domain; values must not be persisted
across processes or interpreted as wall-clock times.

`Timestamp { seconds: i64, nanoseconds: i64 }` is Unix seconds excluding leap
seconds, with fraction 0..999999999. UTC date must lie in years 0001..9999:
`MIN_SECONDS = -62135596800`, `MAX_SECONDS = 253402300799`. Thus {-1,500000000}
is half a second before the epoch. No implicit normalization of public fields.

`Calendar { year, month, day, hour, minute, second, nanosecond }` uses i64 fields,
the proleptic Gregorian calendar, year 1..9999, month 1..12, valid day-of-month,
hour 0..23, minute/second 0..59, nanosecond 0..999999999.

Public structs are forgeable; all timestamp/calendar operations validate them.
`Error { None, Invalid, Overflow, Syntax, Unsupported, TooLong }` follows a
returned value. Failure values are zero/default structs and must be discarded.
Invalid denotes invalid public fields, Overflow an unrepresentable result.

## Operations

- `duration(i64, Unit) -> Duration, Error`; units Nanosecond, Microsecond,
  Millisecond, Second, Minute, Hour, Day (fixed 86400 seconds).
- `add(Duration, Duration)`, `subtract(Duration, Duration) -> Duration, Error`.
- `add(Instant, Duration)`, `subtract(Instant, Duration) -> Instant, Error`.
- `difference(Instant, Instant) -> Duration, Error`: first minus second.
- `add(Timestamp, Duration)`, `subtract(Timestamp, Duration) -> Timestamp, Error`.
- `difference(Timestamp, Timestamp) -> Duration, Error`: first minus second;
  valid timestamps can differ by more than Duration can hold.
- `from_unix_nanoseconds(i64) -> Timestamp`: full signed i64 range accepted.
- `to_unix_nanoseconds(Timestamp) -> i64, Error`: narrower i64 ns range checked.
- `from_calendar(Calendar) -> Timestamp, Error`, `to_calendar(Timestamp) -> Calendar, Error`.
- `parse_rfc3339(const u8[:]) -> Timestamp, Error`.
- `append_rfc3339(u8[>..]&, Timestamp) -> Error`.

Subtraction never negates a duration, so i64.min remains usable. Arithmetic
never wraps, including release builds. Calendar conversion is constant work.

## Bounded RFC 3339 profile

Consumes complete input, max 35 bytes, exact form
`YYYY-MM-DDTHH:MM:SS[.1..9 digits](Z|+HH:MM|-HH:MM)`; lowercase t/z accepted.
Offset hours 00..23, minutes 00..59. Convert to UTC before checking UTC year
bounds. Reject spaces, NUL, non-ASCII, missing fields, trailing bytes, year 0000,
24:00, invalid dates, and second 60. More than nine fractional digits and
`-00:00` return Unsupported if within max length. This deliberately restricted
profile is not all RFC 3339. The unknown-local-offset marker is rejected because
the interface does not preserve its metadata, not because UTC itself is unknown.

Formatting appends canonical UTC with uppercase T/Z and no trailing fractional
zeroes (no fraction for whole seconds), 20..30 bytes. Validate before mutation:
any error leaves existing output unchanged. Explicit ASCII digit writes are
independent of caller formatting overloads. Output is caller-owned; no input is
retained. Allocation failure follows Goose runtime behavior, not recoverable
Error. Goose lifetime rules prohibit inputs borrowing a mutating output builder.

See [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339), sections 4.3, 5.6 and 5.7.
No RFC source or third-party implementation is vendored.
