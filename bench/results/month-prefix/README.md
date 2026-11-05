# Historical month-prefix measurement

Captured November 4, 2026 on an Intel Core Ultra 7 258V, Linux
7.2.11-arch1-1 x86-64 with glibc 2.44, GCC 16.2.1 20260810 at `-O2`, and Goose
`eadca40` (runtime `3025e5810379`). See the [source/toolchain check](../../CURRENTNESS.md)
for the full compiler pin, the source match to v0.1.1 and the missing historical
binary identities. These are historical results for that machine and workload.

Each version used one discarded warmup batch followed by seven retained batches
of 1,000,000 iterations per fixture. Baseline batches ran first, then optimized
batches; they were not randomized or alternated. No CPU affinity or controlled
host load was recorded. Both use the same revised harness, which checksums every
formatted byte. The baseline production source matches `1ccea5a`; the optimized
version adds the 12-entry month-start table and leap adjustment. Captures preceded
the final performance commit: source hashes and dirty status identify measured
content rather than claiming that later commit was already checked out.

The retained [pre-change profile](baseline/profile.txt) attributes 14.70% of samples
to `from_calendar`. The original report described `perf record -e cycles:u`, an
earlier formatter checksum and 2,000,000 iterations. The profile lacks its own
source, command and executable identity, so those details cannot be independently
recovered from it. It was an investigation hint and is excluded from the table.

The table uses only the matched revised-harness captures. Values are median
[min,max] ns/op across all seven batches: whole-batch monotonic nanoseconds
divided by iterations, including checksum/assertion/loop costs. Fresh formatting
includes buffer allocation/destruction; reused formatting excludes initial growth.

| Fixture | Baseline ns/op | Prefix ns/op |
| --- | ---: | ---: |
| parse_utc | 73.01 [61.38, 79.36] | 34.09 [32.50, 34.88] |
| parse_fraction | 90.07 [86.43, 91.30] | 53.00 [50.76, 55.21] |
| parse_offset | 100.33 [98.48, 101.69] | 63.05 [60.81, 63.52] |
| reject_early | 6.15 [6.10, 6.49] | 6.36 [6.10, 6.59] |
| reject_late | 33.33 [33.16, 35.53] | 34.25 [33.36, 36.13] |
| calendar_roundtrip | 85.63 [84.30, 88.78] | 48.02 [46.71, 48.73] |
| duration_add | 6.44 [6.43, 6.82] | 6.59 [6.45, 6.90] |
| format_reused | 237.55 [236.84, 249.81] | 245.80 [240.28, 261.94] |
| format_fresh | 240.42 [237.04, 252.97] | 244.89 [238.96, 260.17] |

Four medians decreased and five increased. Every fixture is retained, including
slower rejection, duration and formatting results. Sequential microbenchmarks on
a shared machine cannot separate code layout, clock/thermal and scheduler effects;
these samples do not establish the cause of changes on unchanged code paths.
They do not establish a universal speed ranking or a performance guarantee.

The [baseline metadata](baseline/metadata.json) and [optimized metadata](optimized/metadata.json)
record flags, source hashes and reported tools; their adjacent `run-1.csv` through
`run-7.csv` files retain every raw sample. The [recorder instructions](../../README.md)
show the protocol and compiler selection. CI checks execution, without timing thresholds.
