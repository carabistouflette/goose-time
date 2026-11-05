# Changelog

## Unreleased

- Add native macOS ARM64 CI with explicit GNU GCC/Apple Clang compiler selection
  and the existing full validation workload. Hosted macOS results are pending;
  production sources, API, compiler pin and release tags are unchanged.

- Run the full maintained validation suite on native Linux ARM64 alongside
  x86-64, with architecture checks, compiler provenance and architecture-specific
  caches. Production sources, API, compiler pin and the v0.1.0 tag are unchanged.

## 0.1.0 — experimental

- Distinct signed-nanosecond Duration and monotonic Instant values; checked unit
  conversion, arithmetic and differences.
- Validated Unix timestamps with normalized fractional nanoseconds, UTC Gregorian
  calendar conversion for years 0001..9999, and checked i64 Unix-nanosecond conversion.
- Bounded RFC 3339 profile parser and canonical UTC builder formatter, independent
  of consumer formatting overloads. Explicitly unsupported leap seconds,
  unknown-local-offset metadata, and precision beyond nanoseconds.
- Independent differential/mutation/calendar validation and reproducible profiled
  benchmarks. Experimental interface; no compatibility promise before 1.0.
