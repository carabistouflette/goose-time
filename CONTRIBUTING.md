# Contributing

Keep the interface small, pure and explicit. Prefer straightforward checked
integer arithmetic and bounded byte operations. Applications own clocks, I/O,
timezone and scheduling policy. Never trade validation or ownership for speed.

Use focused branches (`feat/...`, `fix/...`, `docs/...`) and Conventional Commits:
imperative subjects, one coherent change per commit. No compatibility promise
before 1.0. Tag only independently reviewed releases.

Behavior changes need meaningful public-interface regressions for malformed
input and range edges. Run `make format`, `make check test test-debug`,
`make differential fuzz`, `make test-portable`, and `git diff --check`. Request
independent reviews, fix actionable findings, and keep CI passing. Compiler
changes require a reviewed full upstream commit and full validation. Never
commit credentials, generated compiler output, or private coordination notes.

Profile before optimizing. Run `make bench`; keep raw samples with source,
compiler, flags, platform and CPU provenance. Report all fixtures and regressions;
CI checks benchmark execution, never timing thresholds. Microbenchmarks do not
establish a universal ranking.
