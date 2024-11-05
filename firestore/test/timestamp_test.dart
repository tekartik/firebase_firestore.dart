import 'package:tekartik_firebase_firestore/src/timestamp.dart';
import 'package:test/test.dart';

import 'src_firestore_common_test.dart'
    show dateTimeSupportsMicroseconds, runningAsJavascript;

void main() {
  group('timestamp', () {
    test('equals', () {
      expect(Timestamp(1, 2), Timestamp(1, 2));
      expect(Timestamp(1, 2), isNot(Timestamp(1, 3)));
      expect(Timestamp(1, 2), isNot(Timestamp(0, 2)));
    });
    test('compareTo', () {
      expect(Timestamp(1, 2).compareTo(Timestamp(1, 2)), 0);
      expect(Timestamp(1, 2).compareTo(Timestamp(1, 3)), lessThan(0));
      expect(Timestamp(1, 2).compareTo(Timestamp(2, 2)), lessThan(0));
      expect(Timestamp(1, 2).compareTo(Timestamp(1, 1)), greaterThan(0));
      expect(Timestamp(1, 2).compareTo(Timestamp(0, 2)), greaterThan(0));
    });
    test('millisecondsSinceEpoch', () {
      var now = Timestamp(1, 1);
      expect(
          now.millisecondsSinceEpoch, now.toDateTime().millisecondsSinceEpoch);
      now = Timestamp.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);
      expect(
          now.millisecondsSinceEpoch, now.toDateTime().millisecondsSinceEpoch);

      // 2023-07-21T22:57:28.333Z
      var timestamp = Timestamp.parse('2023-07-21T22:57:28.333Z');
      var ms = timestamp.millisecondsSinceEpoch;
      expect(Timestamp.fromMillisecondsSinceEpoch(ms), timestamp);

      timestamp = Timestamp(1, 123000000);
      expect(
          Timestamp.fromMillisecondsSinceEpoch(
              timestamp.millisecondsSinceEpoch),
          timestamp);
    });

    test('equals', () {
      expect(Timestamp(1, 2), Timestamp(1, 2));
      expect(Timestamp(1, 2), isNot(Timestamp(1, 3)));
      expect(Timestamp(1, 2), isNot(Timestamp(0, 2)));
    });
    test('compareTo', () {
      expect(Timestamp(1, 2).compareTo(Timestamp(1, 2)), 0);
      expect(Timestamp(1, 2).compareTo(Timestamp(1, 3)), lessThan(0));
      expect(Timestamp(1, 2).compareTo(Timestamp(2, 2)), lessThan(0));
      expect(Timestamp(1, 2).compareTo(Timestamp(1, 1)), greaterThan(0));
      expect(Timestamp(1, 2).compareTo(Timestamp(0, 2)), greaterThan(0));
    });

    void checkToIso8601(
        Timestamp timestamp,
        String expectedTimestampToIso8601String,
        String expectedDateTimeToIso8601String) {
      var reason = '${timestamp.seconds} s ${timestamp.nanoseconds} ns';
      expect(timestamp.toIso8601String(), expectedTimestampToIso8601String,
          reason: 'timestamp $reason');
      expect(timestamp.toDateTime(isUtc: true).toIso8601String(),
          expectedDateTimeToIso8601String,
          reason: 'dateTime $reason');
    }

    test('toIso8601', () {
      checkToIso8601(Timestamp(0, 0), '1970-01-01T00:00:00.000Z',
          '1970-01-01T00:00:00.000Z');
      checkToIso8601(Timestamp(0, 100000000), '1970-01-01T00:00:00.100Z',
          '1970-01-01T00:00:00.100Z');
      checkToIso8601(
        Timestamp(0, 100000),
        '1970-01-01T00:00:00.000100Z',
        dateTimeSupportsMicroseconds
            ? '1970-01-01T00:00:00.000100Z'
            : '1970-01-01T00:00:00.000Z',
      );
      checkToIso8601(
        Timestamp(0, 100),
        '1970-01-01T00:00:00.000000100Z',
        '1970-01-01T00:00:00.000Z',
      );
      checkToIso8601(
        Timestamp(0, 999999999),
        '1970-01-01T00:00:00.999999999Z',
        dateTimeSupportsMicroseconds
            ? '1970-01-01T00:00:00.999999Z'
            : '1970-01-01T00:00:01.000Z' // Precision issue
        ,
      );
    });

    test('limit', () {
      Timestamp(-62135596800, 0);
      Timestamp(253402300799, 999999999);

      expect(() => Timestamp(-62135596801, 0), throwsArgumentError);
      expect(() => Timestamp(253402300800, 0), throwsArgumentError);
      expect(() => Timestamp(0, -1), throwsArgumentError);
      expect(() => Timestamp(0, 1000000000), throwsArgumentError);
    });
    test('parse', () {
      void checkParse(
        String text,
        String expectedTimestampToIso8601String,
        String expectedDateTimeToIso8601String,
      ) {
        var timestamp = Timestamp.parse(text);
        return checkToIso8601(timestamp, expectedTimestampToIso8601String,
            expectedDateTimeToIso8601String);
      }

      void checkParseSecondsNanos(
          String text, int expectedSeconds, int expectedNanos) {
        var timestamp = Timestamp.parse(text);
        expect(timestamp.seconds, expectedSeconds, reason: text);
        expect(timestamp.nanoseconds, expectedNanos, reason: text);
      }

      checkParse(
          '2018-10-20T05:13:45.985343123Z',
          '2018-10-20T05:13:45.985343123Z',
          dateTimeSupportsMicroseconds
              ? '2018-10-20T05:13:45.985343Z'
              : '2018-10-20T05:13:45.985Z');
      checkParse(
          '2018-10-20T05:13:45.98534312Z',
          '2018-10-20T05:13:45.985343120Z',
          dateTimeSupportsMicroseconds
              ? '2018-10-20T05:13:45.985343Z'
              : '2018-10-20T05:13:45.985Z');
      checkParse(
          '2018-10-20T05:13:45.985343Z',
          '2018-10-20T05:13:45.985343Z',
          dateTimeSupportsMicroseconds
              ? '2018-10-20T05:13:45.985343Z'
              : '2018-10-20T05:13:45.985Z');
      checkParse('2018-10-20T05:13:45.985Z', '2018-10-20T05:13:45.985Z',
          '2018-10-20T05:13:45.985Z');
      checkParse('1234-01-23T01:23:45.123Z', '1234-01-23T01:23:45.123Z',
          '1234-01-23T01:23:45.123Z');

      checkParse('2018-10-20T05:13:45Z', '2018-10-20T05:13:45.000Z',
          '2018-10-20T05:13:45.000Z');
      checkParse('2018-10-20T05:13Z', '2018-10-20T05:13:00.000Z',
          '2018-10-20T05:13:00.000Z');
      checkParse('2018-10-20T05Z', '2018-10-20T05:00:00.000Z',
          '2018-10-20T05:00:00.000Z');

      // 10 digits ignored!
      checkParse(
          '2018-10-20T05:13:45.9853431239Z',
          '2018-10-20T05:13:45.985343123Z',
          dateTimeSupportsMicroseconds
              ? '2018-10-20T05:13:45.985343Z'
              : '2018-10-20T05:13:45.985Z');

      // Limit
      checkParse('0001-01-01T00:00:00Z', '0001-01-01T00:00:00.000Z',
          '0001-01-01T00:00:00.000Z');
      if (!runningAsJavascript) {
        checkParse('9999-12-31T23:59:59.999999999Z',
            '9999-12-31T23:59:59.999999999Z', '9999-12-31T23:59:59.999999Z');
      } else {
        // Before 2.7.1
        // runningAsJavascript ? '+010000-01-01T00:00:00.000Z' // Precision issue
        // After 2.7.1
        // Invalid argument(s): invalid seconds part 10000-01-01 00:00:01.000Z
      }
      // Parse local converted to utc
      expect(Timestamp.tryParse('2018-10-20T05:13:45.985')!.toIso8601String(),
          endsWith('.985Z'));
      expect(
          Timestamp.tryParse('2018-10-20T05:13:45.985123')!.toIso8601String(),
          endsWith('.985123Z'));
      expect(
          Timestamp.tryParse('2018-10-20T05:13:45.985123100')!
              .toIso8601String(),
          endsWith('.985123100Z'));

      // Limit
      checkParseSecondsNanos('0001-01-01T00:00:00Z', -62135596800, 0);
      if (dateTimeSupportsMicroseconds) {
        checkParseSecondsNanos(
            '9999-12-31T23:59:59.999999999Z', 253402300799, 999999999);
      } else {
        // After 2.7.1
        // Invalid argument(s): invalid seconds part 10000-01-01 00:00:01.000Z
      }
      expect(Timestamp.tryParse(''), isNull);
    });

    test('anyAsTimestamp', () {
      expect(Timestamp.tryAnyAsTimestamp(1000)!.toIso8601String(),
          '1970-01-01T00:00:01.000Z');
      expect(
          Timestamp.tryAnyAsTimestamp('1970-01-01T00:00:01.000Z')!
              .toIso8601String(),
          '1970-01-01T00:00:01.000Z');
      expect(
          Timestamp.tryAnyAsTimestamp('1970-01-01T00:00:01.000000Z')!
              .toIso8601String(),
          '1970-01-01T00:00:01.000Z');
      expect(Timestamp.tryAnyAsTimestamp(Timestamp(1, 0))!.toIso8601String(),
          '1970-01-01T00:00:01.000Z');
      expect(
          Timestamp.tryAnyAsTimestamp(
                  DateTime.fromMillisecondsSinceEpoch(1000))!
              .toIso8601String(),
          '1970-01-01T00:00:01.000Z');
      expect(Timestamp.tryAnyAsTimestamp('dummy'), null);
    });
    test('addDuration', () {
      var timestamp = Timestamp(3, 300000);
      expect(timestamp.addDuration(const Duration(microseconds: 200)),
          Timestamp(3, 500000));
      expect(timestamp.substractDuration(const Duration(microseconds: 200)),
          Timestamp(3, 100000));
      expect(
          timestamp.addDuration(const Duration(seconds: 2, microseconds: 400)),
          Timestamp(5, 700000));
      expect(
          timestamp
              .substractDuration(const Duration(seconds: 2, microseconds: 400)),
          Timestamp(2, 999900000));
    });
    test('difference', () {
      expect(Timestamp(3, 1000).difference(Timestamp(3, 2000)),
          const Duration(microseconds: -1));
      expect(Timestamp(3, 2000).difference(Timestamp(3, 1000)),
          const Duration(microseconds: 1));
      expect(Timestamp(2, 1000).difference(Timestamp(3, 2000)),
          const Duration(microseconds: -1000001));
      expect(Timestamp(3, 1000).difference(Timestamp(2, 2000)),
          const Duration(microseconds: 999999));
      expect(Timestamp(62, 1000).difference(Timestamp(1, 2000)),
          const Duration(minutes: 1, microseconds: 999999));
      var now = DateTime.timestamp();
      expect(Timestamp.fromDateTime(now).difference(Timestamp.zero),
          now.difference(Timestamp.zero.toDateTime(isUtc: true)));
    });
    test('zero', () {
      expect(Timestamp.zero.toIso8601String(), '1970-01-01T00:00:00.000Z');
    });
  });
}
