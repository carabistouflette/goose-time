// SPDX-License-Identifier: Apache-2.0
import std;
import os;
import time from "..";

fn main() {
    let stamp, parsed = time::parse_rfc3339("2026-11-04T18:30:00.125+01:00");
    assert(parsed == time::Error.None);
    let delay, scaled = time::duration(90, time::Unit.Second);
    assert(scaled == time::Error.None);
    let later, added = time::add(stamp, delay);
    assert(added == time::Error.None);
    var out: u8[>..] = [];
    assert(time::append_rfc3339(out, later) == time::Error.None);
    assert(out == "2026-11-04T17:31:30.125Z");
    print(out);
    // Applications supply clocks; nanosecond storage does not guarantee clock resolution.
    let started = time::Instant { clock_ns() };
    let now = time::from_unix_nanoseconds(time_ns());
    let elapsed, error = time::difference(time::Instant { clock_ns() }, started);
    assert(error == time::Error.None && elapsed.nanoseconds >= 0);
    assert(now.nanoseconds >= 0 && now.nanoseconds < 1000000000);
}
