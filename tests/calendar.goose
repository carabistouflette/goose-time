// SPDX-License-Identifier: Apache-2.0
// Independent day enumeration across the complete supported calendar.
import time from "..";
import std;
fn main() {
    let lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var seconds: i64 = -62135596800;
    for year in 1..10000 {
        for month in 1..13 {
            var count = lengths[month - 1];
            if month == 2 && year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) { count = 29; }
            for day in 1..count + 1 {
                let stamp, e = time::from_calendar(time::Calendar { year, month, day, 23, 59, 59, 999999999 });
                assert(e == time::Error.None && stamp.seconds == seconds + 86399 && stamp.nanoseconds == 999999999);
                let cal, ee = time::to_calendar(time::Timestamp { seconds, 0 });
                assert(ee == time::Error.None && cal.year == year && cal.month == month && cal.day == day);
                assert(cal.hour == 0 && cal.minute == 0 && cal.second == 0 && cal.nanosecond == 0);
                seconds += 86400;
            }
        }
    }
    assert(seconds == 253402300800);
    print("full Gregorian calendar sweep passed");
}
