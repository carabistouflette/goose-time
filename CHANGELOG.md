# Changelog

## Unreleased

- Simplify the quickstart, API and validation docs; distinguish the tagged
  release from main and document the historical benchmark's source match and limits.

## 0.1.1 — 2026-11-05 (experimental maintenance release)

Runtime, public API and compiler pin are unchanged from v0.1.0. This release adds
platform validation and documentation; the v0.1.0 tag stays frozen.

- Add native macOS ARM64 CI with explicit GNU GCC/Apple Clang selection and
  record its tools and results.

- Run the full suite on native Linux ARM64 alongside x86-64, with architecture
  checks, recorded tools and separate compiler caches.

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
