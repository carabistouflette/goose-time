// SPDX-License-Identifier: Apache-2.0
import time from "..";
import std;

const LOWEST:  i64 = -9223372036854775808;
const HIGHEST: i64 = 9223372036854775807;

fn equal(actual: time::Timestamp, seconds: i64, nanoseconds: i64) {
    assert(actual.seconds == seconds && actual.nanoseconds == nanoseconds);
}
fn parsed(source: const u8[:], seconds: i64, nanoseconds: i64) {
    let value, error = time::parse_rfc3339(source);
    if error != time::Error.None { print("unexpected rejection: ", source); }
    assert(error == time::Error.None);
    equal(value, seconds, nanoseconds);
}
fn rejected(source: const u8[:]) {
    let value, error = time::parse_rfc3339(source);
    if error == time::Error.None { print("unexpected acceptance: ", source); }
    assert(error != time::Error.None);
    equal(value, 0, 0);
}
fn formatted(source: const u8[:], expected: const u8[:]) {
    let value, error = time::parse_rfc3339(source);
    assert(error == time::Error.None);
    var out: u8[>..] = [];
    out.append("prefix:");
    assert(time::append_rfc3339(out, value) == time::Error.None);
    assert(out[..7] == "prefix:" && out[7..] == expected);
    let again, again_error = time::parse_rfc3339(out[7..]);
    assert(again_error == time::Error.None);
    equal(again, value.seconds, value.nanoseconds);
}
fn duration_arithmetic() {
    let units = [time::Unit.Nanosecond, time::Unit.Microsecond, time::Unit.Millisecond,
                 time::Unit.Second, time::Unit.Minute, time::Unit.Hour, time::Unit.Day];
    let scales: i64[7] = [1, 1000, 1000000, 1000000000, 60000000000, 3600000000000, 86400000000000];
    for unit, i in units {
        let scale = scales[i];
        let positive, pe = time::duration(3, unit);
        let negative, ne = time::duration(-3, unit);
        assert(pe == time::Error.None && positive.nanoseconds == 3 * scale);
        assert(ne == time::Error.None && negative.nanoseconds == -3 * scale);
        let high = HIGHEST / scale;
        let low = LOWEST / scale;
        let hv, he = time::duration(high, unit);
        let lv, le = time::duration(low, unit);
        assert(he == time::Error.None && hv.nanoseconds == high * scale);
        assert(le == time::Error.None && lv.nanoseconds == low * scale);
        if scale > 1 {
            let hbad, hbe = time::duration(high + 1, unit);
            let lbad, lbe = time::duration(low - 1, unit);
            assert(hbe == time::Error.Overflow && hbad.nanoseconds == 0);
            assert(lbe == time::Error.Overflow && lbad.nanoseconds == 0);
        }
    }
    let min = time::Duration { nanoseconds: LOWEST };
    let max = time::Duration { nanoseconds: HIGHEST };
    let zero = time::Duration { nanoseconds: 0 };
    let one = time::Duration { nanoseconds: 1 };
    let minus_one = time::Duration { nanoseconds: -1 };
    let sum, se = time::add(min, max);
    assert(se == time::Error.None && sum.nanoseconds == -1);
    let cancelled, ce = time::subtract(min, min);
    assert(ce == time::Error.None && cancelled.nanoseconds == 0);
    let negmax, nme = time::subtract(zero, max);
    assert(nme == time::Error.None && negmax.nanoseconds == -HIGHEST);
    let negmin, nle = time::subtract(zero, min);
    assert(nle == time::Error.Overflow && negmin.nanoseconds == 0);
    let hbad, hbe = time::add(max, one);
    let lbad, lbe = time::add(min, minus_one);
    assert(hbe == time::Error.Overflow && hbad.nanoseconds == 0);
    assert(lbe == time::Error.Overflow && lbad.nanoseconds == 0);
    let shbad, shbe = time::subtract(max, minus_one);
    let slbad, slbe = time::subtract(min, one);
    assert(shbe == time::Error.Overflow && shbad.nanoseconds == 0);
    assert(slbe == time::Error.Overflow && slbad.nanoseconds == 0);
    let instant = time::Instant { nanoseconds: LOWEST };
    let restored, re = time::subtract(instant, min);
    assert(re == time::Error.None && restored.nanoseconds == 0);
    let shifted, she = time::add(instant, max);
    assert(she == time::Error.None && shifted.nanoseconds == -1);
    let equal_readings, ere = time::difference(instant, instant);
    assert(ere == time::Error.None && equal_readings.nanoseconds == 0);
    let upper = time::Instant { nanoseconds: HIGHEST };
    let span, spe = time::difference(upper, instant);
    assert(spe == time::Error.Overflow && span.nanoseconds == 0);
    let reverse_span, rspe = time::difference(instant, upper);
    assert(rspe == time::Error.Overflow && reverse_span.nanoseconds == 0);
    let ibad, ibe = time::add(upper, one);
    assert(ibe == time::Error.Overflow && ibad.nanoseconds == 0);
    let isbad, isbe = time::subtract(instant, one);
    assert(isbe == time::Error.Overflow && isbad.nanoseconds == 0);
}
fn unix_and_timestamp_arithmetic() {
    for count in [LOWEST, LOWEST + 1, -1000000001, -1000000000, -999999999,
                  -1, 0, 1, 999999999, 1000000000, 1000000001, HIGHEST - 1, HIGHEST] {
        let stamp = time::from_unix_nanoseconds(count);
        assert(stamp.nanoseconds >= 0 && stamp.nanoseconds < 1000000000);
        let back, error = time::to_unix_nanoseconds(stamp);
        assert(error == time::Error.None && back == count);
    }
    equal(time::from_unix_nanoseconds(-1), -1, 999999999);
    equal(time::from_unix_nanoseconds(LOWEST), -9223372037, 145224192);
    equal(time::from_unix_nanoseconds(HIGHEST), 9223372036, 854775807);
    let lower = time::from_unix_nanoseconds(LOWEST);
    let upper = time::from_unix_nanoseconds(HIGHEST);
    let epoch = time::Timestamp { seconds: 0, nanoseconds: 0 };
    let cancel, ce = time::subtract(lower, time::Duration { nanoseconds: LOWEST });
    assert(ce == time::Error.None); equal(cancel, 0, 0);
    let minus_one, me = time::add(lower, time::Duration { nanoseconds: HIGHEST });
    assert(me == time::Error.None); equal(minus_one, -1, 999999999);
    let positive_min, pme = time::subtract(epoch, time::Duration { nanoseconds: LOWEST });
    assert(pme == time::Error.None); equal(positive_min, 9223372036, 854775808);
    let too_high, the = time::to_unix_nanoseconds(positive_min);
    assert(the == time::Error.Overflow && too_high == 0);
    let before_min = time::Timestamp { seconds: -9223372037, nanoseconds: 145224191 };
    let too_low, tle = time::to_unix_nanoseconds(before_min);
    assert(tle == time::Error.Overflow && too_low == 0);
    let min_diff, mde = time::difference(lower, epoch);
    let max_diff, xde = time::difference(upper, epoch);
    assert(mde == time::Error.None && min_diff.nanoseconds == LOWEST);
    assert(xde == time::Error.None && max_diff.nanoseconds == HIGHEST);
    let zero_diff, zde = time::difference(upper, upper);
    assert(zde == time::Error.None && zero_diff.nanoseconds == 0);
    let wide, we = time::difference(upper, lower);
    assert(we == time::Error.Overflow && wide.nanoseconds == 0);
    let reverse_min, rme = time::difference(epoch, lower);
    assert(rme == time::Error.Overflow && reverse_min.nanoseconds == 0);
    // A naive seconds*1e9 intermediate would overflow before this subtraction.
    let rescue_left = time::Timestamp { seconds: 9223372037, nanoseconds: 0 };
    let rescue_right = time::Timestamp { seconds: 0, nanoseconds: 145224193 };
    let rescued, rescued_error = time::difference(rescue_left, rescue_right);
    assert(rescued_error == time::Error.None && rescued.nanoseconds == HIGHEST);
    let reverse_rescue, reverse_rescue_error = time::difference(rescue_right, rescue_left);
    assert(reverse_rescue_error == time::Error.None && reverse_rescue.nanoseconds == -HIGHEST);
    let earliest = time::Timestamp { seconds: -62135596800, nanoseconds: 0 };
    let latest = time::Timestamp { seconds: 253402300799, nanoseconds: 999999999 };
    let late, late_error = time::add(latest, time::Duration { nanoseconds: 1 });
    let early, early_error = time::subtract(earliest, time::Duration { nanoseconds: 1 });
    assert(late_error == time::Error.Overflow); equal(late, 0, 0);
    assert(early_error == time::Error.Overflow); equal(early, 0, 0);
    let broad, broad_error = time::difference(latest, earliest);
    assert(broad_error == time::Error.Overflow && broad.nanoseconds == 0);
}
fn invalid_values() {
    let epoch = time::Timestamp { seconds: 0, nanoseconds: 0 };
    let zero = time::Duration { nanoseconds: 0 };
    for stamp in [time::Timestamp { seconds: LOWEST, nanoseconds: 0 },
                  time::Timestamp { seconds: HIGHEST, nanoseconds: 0 },
                  time::Timestamp { seconds: -62135596801, nanoseconds: 0 },
                  time::Timestamp { seconds: 253402300800, nanoseconds: 0 },
                  time::Timestamp { seconds: 0, nanoseconds: -1 },
                  time::Timestamp { seconds: 0, nanoseconds: 1000000000 },
                  time::Timestamp { seconds: 0, nanoseconds: LOWEST },
                  time::Timestamp { seconds: 0, nanoseconds: HIGHEST }] {
        let cal, calendar_error = time::to_calendar(stamp);
        assert(calendar_error == time::Error.Invalid && cal.year == 0 && cal.nanosecond == 0);
        let count, count_error = time::to_unix_nanoseconds(stamp);
        assert(count_error == time::Error.Invalid && count == 0);
        let added, add_error = time::add(stamp, zero);
        let subtracted, sub_error = time::subtract(stamp, zero);
        assert(add_error == time::Error.Invalid && sub_error == time::Error.Invalid);
        equal(added, 0, 0); equal(subtracted, 0, 0);
        let left, left_error = time::difference(stamp, epoch);
        let right, right_error = time::difference(epoch, stamp);
        assert(left_error == time::Error.Invalid && right_error == time::Error.Invalid);
        assert(left.nanoseconds == 0 && right.nanoseconds == 0);
        var out: u8[>..] = []; out.append("preserved\0\xff");
        assert(time::append_rfc3339(out, stamp) == time::Error.Invalid);
        assert(out == "preserved\0\xff");
    }
    // Mutate public fields independently, including hostile extremes.
    let first_invalid = [10000, 13, 32, 24, 60, 60, 1000000000];
    for field in 7 {
        for invalid in [LOWEST, -1, HIGHEST, first_invalid[field]] {
            var cal = time::Calendar { year: 2000, month: 2, day: 29,
                                      hour: 12, minute: 34, second: 56, nanosecond: 123 };
            if field == 0 { cal.year = invalid; }
            else if field == 1 { cal.month = invalid; }
            else if field == 2 { cal.day = invalid; }
            else if field == 3 { cal.hour = invalid; }
            else if field == 4 { cal.minute = invalid; }
            else if field == 5 { cal.second = invalid; }
            else { cal.nanosecond = invalid; }
            let stamp, error = time::from_calendar(cal);
            assert(error == time::Error.Invalid); equal(stamp, 0, 0);
        }
    }
    for source in ["0000-01-01T00:00:00Z", "1900-02-29T00:00:00Z", "2001-02-29T00:00:00Z",
                   "2000-04-31T00:00:00Z", "2000-00-01T00:00:00Z", "2000-13-01T00:00:00Z",
                   "2000-01-00T00:00:00Z", "2000-01-32T00:00:00Z", "2000-01-01T24:00:00Z",
                   "2000-01-01T00:60:00Z", "2000-01-01T00:00:60Z"] { rejected(source); }
}
fn calendar_cycle() {
    // Independent enumeration: known Unix epoch anchor, then one day at a time.
    // Cover every day in one complete 400-year Gregorian cycle.
    let lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var seconds: i64 = 946684800;
    var days = 0;
    for year in 2000..2400 {
        for month in 1..13 {
            var count = lengths[month - 1];
            if month == 2 && year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) { count++; }
            for day in 1..count + 1 {
                let cal = time::Calendar { year: year, month: month, day: day,
                    hour: 23, minute: 59, second: 59, nanosecond: 123456789 };
                let stamp, error = time::from_calendar(cal);
                assert(error == time::Error.None); equal(stamp, seconds + 86399, 123456789);
                let back, back_error = time::to_calendar(stamp);
                assert(back_error == time::Error.None);
                assert(back.year == year && back.month == month && back.day == day);
                assert(back.hour == 23 && back.minute == 59 && back.second == 59 && back.nanosecond == 123456789);
                seconds += 86400; days++;
            }
        }
    }
    assert(days == 146097 && seconds == 13569465600);
    parsed("0001-01-01T00:00:00Z", -62135596800, 0);
    parsed("9999-12-31T23:59:59.999999999Z", 253402300799, 999999999);
    formatted("0001-01-01T00:00:00Z", "0001-01-01T00:00:00Z");
    formatted("9999-12-31T23:59:59.999999999Z", "9999-12-31T23:59:59.999999999Z");
}
fn rfc3339() {
    parsed("1970-01-01T00:00:00Z", 0, 0);
    parsed("1969-12-31T23:59:59.999999999Z", -1, 999999999);
    parsed("1970-01-01t00:00:00.123456789z", 0, 123456789);
    parsed("1970-01-01T23:59:00+23:59", 0, 0);
    parsed("1969-12-31T00:01:00-23:59", 0, 0);
    parsed("2000-03-01T00:00:00+00:01", 951868740, 0);
    parsed("2000-02-29T23:59:00-00:01", 951868800, 0);
    parsed("0001-01-01T00:00:00-23:59", -62135510460, 0);
    parsed("9999-12-31T23:59:59+23:59", 253402214459, 0);
    for source in ["0001-01-01T00:00:00+00:01", "9999-12-31T23:59:59-00:01"] { rejected(source); }
    formatted("1970-01-01t00:00:00.100000000z", "1970-01-01T00:00:00.1Z");
    formatted("1970-01-01T00:00:00.000000001+00:00", "1970-01-01T00:00:00.000000001Z");
    formatted("1970-01-01T00:01:00.123400000+00:01", "1970-01-01T00:00:00.1234Z");
    formatted("1969-12-31T23:59:00-00:01", "1970-01-01T00:00:00Z");
    for fraction in ["1", "12", "123", "1234", "12345", "123456", "1234567", "12345678", "123456789"] {
        let text = str("1970-01-01T00:00:00.", fraction, "Z");
        formatted(text, text);
    }
    for source in ["", "1970-01-01", "1970-01-01 00:00:00Z", "1970-01-01T00:00:00",
                   "1970-1-01T00:00:00Z", "1970-01-1T00:00:00Z", "1970-01-01T0:00:00Z",
                   "1970/01/01T00:00:00Z", "1970-01-01T00-00:00Z", "1970-01-01T00:00-00Z",
                   "1970-01-01T00:00:00.Z", "1970-01-01T00:00:00,1Z", "1970-01-01T00:00:00.1",
                   "1970-01-01T00:00:00+24:00", "1970-01-01T00:00:00+00:60",
                   "1970-01-01T00:00:00+0000", "1970-01-01T00:00:00+00", "1970-01-01T00:00:00Zx",
                   "1970-01-01T00:00:00Z\n", "1970-01-01T00:00:00\0", "1970-01-01T00:00:00\xff",
                   "１９７０-01-01T00:00:00Z"] { rejected(source); }
    let unknown, ue = time::parse_rfc3339("1970-01-01T00:00:00-00:00");
    assert(ue == time::Error.Unsupported); equal(unknown, 0, 0);
    let excessive, ee = time::parse_rfc3339("1970-01-01T00:00:00.1234567890Z");
    assert(ee == time::Error.Unsupported); equal(excessive, 0, 0);
    var long: u8[>..] = []; long.resize(36, '0');
    let huge, he = time::parse_rfc3339(long);
    assert(he == time::Error.TooLong); equal(huge, 0, 0);
    let complete = "2000-02-29T12:34:56.123456789+01:23";
    for length in complete.len { rejected(complete[..length]); }
    // Every non-ASCII byte at every position must be rejected; no decoder fallback.
    for position in 20 {
        for byte in 128..256 {
            var mutated: u8[>..] = []; mutated.append("1970-01-01T00:00:00Z");
            mutated[position] = byte as! u8;
            rejected(mutated);
        }
    }
}
fn main() {
    duration_arithmetic();
    unix_and_timestamp_arithmetic();
    invalid_values();
    calendar_cycle();
    rfc3339();
    print("time public-interface tests passed");
}
