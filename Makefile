GOOSE ?= .toolchain/goose/build/goose
BENCH_ITERATIONS ?= 100000
BENCH_CC ?= gcc

.PHONY: setup format check test test-debug test-portable differential fuzz test-calendar bench
setup:
	./scripts/setup-goose.sh
format:
	"$(GOOSE)" format time.goose detail.goose tests examples bench
check:
	"$(GOOSE)" format --check time.goose detail.goose tests examples bench
	"$(GOOSE)" check tests/core.goose
	"$(GOOSE)" check tests/formatting.goose
	"$(GOOSE)" check examples/timestamps.goose
	"$(GOOSE)" check bench/bench.goose
test:
	mkdir -p .build
	"$(GOOSE)" run tests/core.goose
	"$(GOOSE)" run tests/formatting.goose
	"$(GOOSE)" build tests/core.goose -o .build/core
	./.build/core
	"$(GOOSE)" build tests/formatting.goose -o .build/formatting
	./.build/formatting
	"$(GOOSE)" run examples/timestamps.goose
	"$(GOOSE)" run bench/bench.goose -- 10
test-debug:
	mkdir -p .build
	"$(GOOSE)" run tests/core.goose --debug
	"$(GOOSE)" run tests/formatting.goose --debug
	"$(GOOSE)" build tests/core.goose --debug -o .build/core-debug
	./.build/core-debug
	"$(GOOSE)" build tests/formatting.goose --debug -o .build/formatting-debug
	./.build/formatting-debug
test-portable:
	mkdir -p .build
	"$(GOOSE)" build tests/core.goose --cc gcc --debug --standalone -o .build/core-gcc
	./.build/core-gcc
	"$(GOOSE)" build tests/formatting.goose --cc gcc --debug --standalone -o .build/formatting-gcc
	./.build/formatting-gcc
	"$(GOOSE)" build tests/core.goose --cc clang --debug --standalone -o .build/core-clang
	./.build/core-clang
	"$(GOOSE)" build tests/formatting.goose --cc clang --debug --standalone -o .build/formatting-clang
	./.build/formatting-clang
	python3 tests/differential.py --goose "$(GOOSE)" --cc gcc --standalone --mode build-debug
	python3 tests/differential.py --goose "$(GOOSE)" --cc clang --standalone --mode build-debug
differential:
	python3 tests/differential.py --goose "$(GOOSE)" --mode run --mode debug --mode build --mode build-debug
fuzz:
	python3 tests/parser_fuzz.py --goose "$(GOOSE)" --cc clang --standalone
bench:
	mkdir -p .build
	"$(GOOSE)" build bench/bench.goose --cc "$(BENCH_CC)" -O2 -o .build/bench
	./.build/bench $(BENCH_ITERATIONS)
test-calendar:
	mkdir -p .build
	"$(GOOSE)" build tests/calendar.goose --cc gcc --debug --standalone -o .build/calendar-gcc
	./.build/calendar-gcc
	"$(GOOSE)" build tests/calendar.goose --cc clang --debug --standalone -o .build/calendar-clang
	./.build/calendar-clang
