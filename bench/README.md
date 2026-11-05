# Benchmarks

These microbenchmarks exercise this API. They do not rank libraries or predict
whole-application performance. The [historical month-prefix comparison](results/month-prefix/README.md)
retains every sample, including slower results. Its [source and toolchain check](CURRENTNESS.md)
explains which parts still match v0.1.1 and which binary identities are unknown.

## Record a run

After [compiler setup](../README.md#try-it), Linux measurement also needs Python 3,
`lscpu` and a C compiler. Use a new or empty output directory for every capture:

```sh
python3 bench/measure.py --goose /absolute/path/to/goose --cc gcc \
  --iterations 1000000 --runs 7 --output .build/measure-new
```

The recorder builds with `-O2`, discards one complete warmup batch, then keeps
seven batches of all nine fixtures. It records each CSV, five source-file hashes,
Git commit/dirty status, the declared compiler pin, reported compiler versions,
build command, OS and CPU. It rejects a nonempty output directory. It does not
verify the selected Goose compiler's full source checkout or hash tool binaries
and shared libraries; record those separately for a new performance claim.

For a single unretained batch, use `make bench BENCH_ITERATIONS=1000000 BENCH_CC=gcc`.
`BENCH_CC` controls Make; the recorder's independent `--cc` option defaults to `gcc`.
There are no timing thresholds. Match sources, compilers, flags, workload and
machine conditions when comparing versions, and retain all batches, not just the fastest.

## What the numbers include

Nine fixtures cover UTC parsing, fractional seconds, numeric offsets, early/late
rejection, calendar roundtrips, checked duration addition, and formatting with
reused and fresh output buffers. Inputs vary inside loops. Checksums consume
results, including every formatted byte.

`total_ns` is whole-batch elapsed time from Goose's monotonic clock. Divide it by
`iterations` for ns/op. Loop, validation/assertion and checksum costs are included.
The C compiler can simplify duration arithmetic, so a very small result is not an
isolated operation cost. Fresh buffers include allocation/destruction; reused
buffers exclude their initial capacity growth.

Keep raw samples, compare checksums, and report dispersion alongside a median.
Profile before changing code. Shared-machine scheduling, clock/thermal changes
and batch order can affect results; report those limitations with the numbers.
