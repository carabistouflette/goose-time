# Changelog

## Unreleased

- Distinct signed-nanosecond Duration and monotonic Instant values; checked unit
  conversion, arithmetic and differences.
- Validated Unix timestamps with normalized fractional nanoseconds, UTC Gregorian
  calendar conversion for years 0001..9999, and checked i64 Unix-nanosecond conversion.
- Bounded RFC 3339 profile parser and canonical UTC builder formatter, independent
  of consumer formatting overloads. Explicitly unsupported leap seconds,
  unknown-local-offset metadata, and precision beyond nanoseconds.
- Independent differential/mutation/calendar validation and reproducible profiled
  benchmarks. Experimental interface; no compatibility promise or published release.
