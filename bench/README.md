# Benchmarks

Run `make bench BENCH_ITERATIONS=1000000` or retain seven full batches with
`python3 bench/measure.py --goose /path/to/goose --output .build/measure`.
Use a new or empty output directory for each capture; nonempty paths are rejected.
The measure script builds with the selected C compiler at -O2, warms one batch,
then retains every fixture's raw CSV and source hashes, exact library/compiler
revision, dirty status, compiler flags, OS and CPU metadata. It does not enforce
performance thresholds. Python 3 and Linux `lscpu` are measurement prerequisites.

Fixtures cover UTC, nanosecond fractions, numeric offsets, early/late rejection,
calendar conversion, checked duration addition, and canonical formatting with
reused and fresh builders. Inputs vary inside loops; checksums consume results;
validation/assertion and loop overhead are included. Formatting consumes every
output byte in its checksum; checksum work is included too. Durations can be optimized
by the downstream C compiler, so a very small timing is not a standalone cost
measurement. Fresh builders measure allocation/destruction along with formatting;
reused builders exclude initial capacity growth. Times are whole-batch wall time
from Goose's monotonic clock. Divide total_ns by iterations for ns/op.

Retain all batches, check distributions and checksums, and profile before adding
an optimization. These are microbenchmarks of this interface, not comparative
rankings or end-to-end application performance claims. Published samples identify
actual source hashes even when benchmark tooling was uncommitted during capture.

See [retained month-prefix samples](results/month-prefix/README.md) for the
initial profiled optimization and all unchanged-path results.
