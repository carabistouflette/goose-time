// SPDX-License-Identifier: Apache-2.0
// Test-only line protocol; independent Python oracle supplies expectations.
import time from "..";
import std;
import os;

fn integer(text: const u8[:]) -> i64 {
    let value, ok = parse_int(text);
    assert(ok);
    value
}
fn emit_stamp(stamp: time::Timestamp, error: time::Error) {
    if error == time::Error.Overflow { print("O"); return; }
    assert(error == time::Error.None);
    print(stamp.seconds, "\t", stamp.nanoseconds);
}
fn emit_duration(value: time::Duration, error: time::Error) {
    if error == time::Error.Overflow { print("O"); return; }
    assert(error == time::Error.None);
    print(value.nanoseconds);
}
fn main() {
    while true {
        var line: u8[>..] = [];
        if !read_line(line) { break; }
        let fields = split(line, '\t');
        assert(fields.len >= 2);
        if fields[0] == "P" {
            assert(fields.len == 2);
            let stamp, error = time::parse_rfc3339(fields[1]);
            assert(error == time::Error.None);
            let calendar, calendar_error = time::to_calendar(stamp);
            assert(calendar_error == time::Error.None);
            let roundtrip, roundtrip_error = time::from_calendar(calendar);
            assert(roundtrip_error == time::Error.None);
            assert(roundtrip.seconds == stamp.seconds && roundtrip.nanoseconds == stamp.nanoseconds);
            var text: u8[>..] = [];
            assert(time::append_rfc3339(text, stamp) == time::Error.None);
            print(stamp.seconds, "\t", stamp.nanoseconds, "\t", text, "\t",
                calendar.year, "\t", calendar.month, "\t", calendar.day, "\t",
                calendar.hour, "\t", calendar.minute, "\t", calendar.second, "\t", calendar.nanosecond);
        } else if fields[0] == "U" {
            assert(fields.len == 2);
            let value = integer(fields[1]);
            let stamp = time::from_unix_nanoseconds(value);
            let roundtrip, error = time::to_unix_nanoseconds(stamp);
            assert(error == time::Error.None && roundtrip == value);
            print(stamp.seconds, "\t", stamp.nanoseconds);
        } else if fields[0] == "A" || fields[0] == "S" || fields[0] == "I" {
            assert(fields.len == 3);
            let a = integer(fields[1]);
            let b = integer(fields[2]);
            if fields[0] == "A" {
                let value, error = time::add(time::Duration { a }, time::Duration { b });
                emit_duration(value, error);
            } else if fields[0] == "S" {
                let value, error = time::subtract(time::Duration { a }, time::Duration { b });
                emit_duration(value, error);
            } else {
                let value, error = time::difference(time::Instant { a }, time::Instant { b });
                emit_duration(value, error);
            }
        } else if fields[0] == "T" || fields[0] == "B" {
            assert(fields.len == 4);
            let stamp = time::Timestamp { integer(fields[1]), integer(fields[2]) };
            let delta = time::Duration { integer(fields[3]) };
            if fields[0] == "T" {
                let value, error = time::add(stamp, delta);
                emit_stamp(value, error);
            } else {
                let value, error = time::subtract(stamp, delta);
                emit_stamp(value, error);
            }
        } else {
            assert(fields[0] == "X" && fields.len == 5);
            let a = time::Timestamp { integer(fields[1]), integer(fields[2]) };
            let b = time::Timestamp { integer(fields[3]), integer(fields[4]) };
            let value, error = time::difference(a, b);
            emit_duration(value, error);
        }
    }
}
