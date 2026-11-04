// SPDX-License-Identifier: Apache-2.0
import std;
import os;
import time from "..";

fn parse_case(name: const u8[:], fixtures: (const u8[:])[:], iterations: i64, success: bool) {
    var checksum: i64 = 0;
    let start = clock_ns();
    for i in iterations {
        let stamp, error = time::parse_rfc3339(fixtures[i % fixtures.len]);
        assert((error == time::Error.None) == success);
        checksum += stamp.nanoseconds + stamp.seconds % 1000000;
    }
    let elapsed = clock_ns() - start;
    print(name, ",", iterations, ",", elapsed, ",", checksum);
}
fn main() {
    let arguments = args();
    var iterations: i64 = 100000;
    if arguments.len > 1 {
        let count, ok = parse_int(arguments[1]);
        assert(ok && count > 0 && count <= 100000000);
        iterations = count;
    }
    print("fixture,iterations,total_ns,checksum");
    parse_case("parse_utc", ["2026-11-04T12:34:56Z", "1969-12-31T23:59:59Z"], iterations, true);
    parse_case("parse_fraction", ["2026-11-04T12:34:56.123456789Z", "2000-02-29T00:00:00.987654321Z"], iterations, true);
    parse_case("parse_offset", ["2026-11-04T12:34:56.123456789+23:59", "1969-12-31T23:59:59.000000001-01:30"], iterations, true);
    parse_case("reject_early", ["x026-11-04T12:34:56Z", "2026/11-04T12:34:56Z"], iterations, false);
    parse_case("reject_late", ["2026-11-04T12:34:56.123456789+23:60", "2026-11-04T12:34:56.123456789Zx"], iterations, false);
    var checksum: i64 = 0;
    var start = clock_ns();
    for i in iterations {
        let value = time::Timestamp { (i % 100000) * 86400 - 2000000000, i % 1000000000 };
        let calendar, error = time::to_calendar(value);
        assert(error == time::Error.None);
        let back, back_error = time::from_calendar(calendar);
        assert(back_error == time::Error.None);
        checksum += back.seconds % 1000000 + back.nanoseconds;
    }
    var elapsed = clock_ns() - start;
    print("calendar_roundtrip,", iterations, ",", elapsed, ",", checksum);
    checksum = 0;
    start = clock_ns();
    for i in iterations {
        let value, error = time::add(time::Duration { i }, time::Duration { i % 1000 });
        assert(error == time::Error.None);
        checksum += value.nanoseconds;
    }
    elapsed = clock_ns() - start;
    print("duration_add,", iterations, ",", elapsed, ",", checksum);
    var out: u8[>..] = []; out.resize(30, '0'); out.clear();
    checksum = 0;
    start = clock_ns();
    for i in iterations {
        out.clear();
        let value = time::Timestamp { 1700000000 + i % 86400, i % 1000000000 };
        assert(time::append_rfc3339(out, value) == time::Error.None);
        checksum += out.len + out[out.len - 2];
    }
    elapsed = clock_ns() - start;
    print("format_reused,", iterations, ",", elapsed, ",", checksum);
    checksum = 0;
    start = clock_ns();
    for i in iterations {
        var fresh: u8[>..] = [];
        let value = time::Timestamp { 1700000000 + i % 86400, i % 1000000000 };
        assert(time::append_rfc3339(fresh, value) == time::Error.None);
        checksum += fresh.len + fresh[fresh.len - 2];
    }
    elapsed = clock_ns() - start;
    print("format_fresh,", iterations, ",", elapsed, ",", checksum);
}
