# Security

Report suspected vulnerabilities through
[GitHub private vulnerability reporting](https://github.com/carabistouflette/goose-time/security/advisories/new).
Include the affected commit, compiler/platform and a small reproducer. Avoid
publishing exploit details before a fix is available.

Timestamp/calendar operations validate public fields, and arithmetic checks for
overflow before performing unsafe operations. Parsing reads at most 35 bytes and
retains no input. Formatting validates before appending at most 30 bytes;
returned errors leave the existing output unchanged. Allocation failure follows
Goose runtime behavior rather than returning a recoverable `Error`.

The library contains no native code and performs no process, network, filesystem
or clock operations. Callers must keep monotonic readings in the same clock
domain; the library cannot verify that identity. Do not treat wall-clock dates
as monotonic deadlines. Trust and expiry decisions belong to applications.

Parsing and formatting change the original spelling and offset. Verify an
original-text signature against the original bytes, not reformatted text.
See [API limits](docs/API.md) and [validation results](docs/VALIDATION.md).
