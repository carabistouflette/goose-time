# Security

Report suspected vulnerabilities through
[GitHub private vulnerability reporting](https://github.com/carabistouflette/goose-time/security/advisories/new).
Include the affected commit, exact compiler/platform, and a minimal reproducer;
avoid public exploit details before a fix is available.

All documented timestamp/calendar operations validate public fields. Arithmetic
checks representability before operations that can overflow in release builds.
Parsing examines at most 35 bytes and retains no input. Formatting validates
before mutation and writes at most 30 bytes. Pure Goose, no native adapter,
processes, network, filesystem or global clocks. Allocation failure is a runtime
failure, not a recoverable Error. Instants cannot validate clock-domain identity.

The RFC 3339 profile deliberately rejects unsupported precision and metadata.
Do not use wall-clock timestamps as monotonic deadlines or assume signed source
bytes survive parse/format normalization. Trust and expiry policy belong to callers.

Tests cover forged records, malformed byte input, arithmetic endpoints,
independent calendar fixtures, and consumer formatting overloads in runner,
native and debug builds. See docs/VALIDATION.md for checks actually performed.
