# Contributing

Keep the public API small. Use checked integer arithmetic and bounded byte
access. Applications own clocks, I/O, timezone and scheduling policy. Do not
trade input validation or ownership checks for speed.

Use focused branches and Conventional Commits with imperative subjects. Keep
each commit to one coherent change. Do not commit credentials, generated
compiler output or private coordination notes. Releases need independent review;
there is no compatibility promise before 1.0.

Behavior changes need public-interface tests for valid input, errors and range
boundaries. Format with `make format`, run the [validation commands](docs/VALIDATION.md),
and check `git diff --check`. Calendar changes must pass both full-calendar
sweeps. Compiler updates need a reviewed full upstream commit and validation on
each maintained platform. Address review findings and keep CI passing.

Profile before optimizing. Follow the [measurement method](bench/README.md),
retain every raw result, and record source/toolchain identities and the machine.
Include slower results and dispersion. CI benchmark smoke checks execution;
it does not establish performance or enforce a timing threshold.
