// SPDX-License-Identifier: Apache-2.0
// Deliberately hostile consumer hooks must not affect canonical time bytes.
import time from "..";
import std;

const LOWEST:  i64 = -9223372036854775808;
const HIGHEST: i64 = 9223372036854775807;

fn format(out: u8[>..]&, value: const u8[:]) { out.append("hostile text"); }
fn format(out: u8[>..]&, value: i64) { out.append("hostile integer"); }
fn format(out: u8[>..]&, value: u64) { out.append("hostile unsigned"); }
fn format(out: u8[>..]&, value: bool) { out.append("hostile boolean"); }

fn main() {
    for source in ["0001-01-01T00:00:00Z", "1969-12-31T23:59:59.999999999Z",
                   "1970-01-01T00:00:00Z", "2000-02-29T12:34:56.000000001Z",
                   "9999-12-31T23:59:59.123456789Z"] {
        let value, error = time::parse_rfc3339(source);
        assert(error == time::Error.None);
        var out: u8[>..] = []; out.append("prefix:");
        assert(time::append_rfc3339(out, value) == time::Error.None);
        assert(out[..7] == "prefix:" && out[7..] == source);
    }
    let shifted, shifted_error = time::parse_rfc3339("2000-03-01T01:00:00.123400000+01:00");
    assert(shifted_error == time::Error.None);
    var canonical: u8[>..] = [];
    assert(time::append_rfc3339(canonical, shifted) == time::Error.None);
    assert(canonical == "2000-03-01T00:00:00.1234Z");
    let invalid = time::Timestamp { seconds: HIGHEST, nanoseconds: HIGHEST };
    assert(time::append_rfc3339(canonical, invalid) == time::Error.Invalid);
    assert(canonical == "2000-03-01T00:00:00.1234Z");
    let rejected, rejected_error = time::parse_rfc3339("not a timestamp");
    assert(rejected_error != time::Error.None && rejected.seconds == 0 && rejected.nanoseconds == 0);
}
