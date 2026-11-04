# Month prefix measurement

Seven sequential batches per version, 1,000,000 iterations per fixture, one
warmup batch; same revised harness checksums every formatted byte. Baseline is
library source at 1ccea5a with the revised benchmark harness, optimized version
adds the validated 12-entry month prefix table and leap adjustment. Source hashes
and dirty status in each metadata file identify the measured content exactly.
The captures preceded the final performance commit; metadata does not claim a
later commit identity. Native GCC -O2, exact pinned Goose compiler, Linux x86-64;
full CPU/compiler/flags/platform details accompany each capture.

The pre-change `perf record -e cycles:u` profile attributed 14.70% of mixed batch
samples to from_calendar. That profile used the earlier formatter checksum and
2,000,000 iterations; it identifies a candidate, not a matched timing comparison.
The table below uses only revised-harness captures. Values are median [min,max]
ns/op across all seven batches. Checksum/assertion/loop costs are included.

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

Calendar-dependent parsing and roundtrip fixtures justify the small table. Keep
all fixtures visible, including unchanged-path variation. Sequential microbenchmarks
on a shared machine cannot separate code layout, clock/thermal and scheduler noise.
No universal speed ranking, CI timing threshold, or performance guarantee is made.
