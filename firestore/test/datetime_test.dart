import 'package:test/test.dart';

bool get _runningAsJavascript => identical(1, 1.0);

void main() {
  group('timestamp', () {
    test('DateTime', () {
      void _checkParse(String text, String expected) {
        expect(DateTime.parse(text).toIso8601String(), expected);
      }

      _checkParse('2018-10-20T05:13:45.98Z', '2018-10-20T05:13:45.980Z');
      _checkParse('2018-10-20', '2018-10-20T00:00:00.000');
      // DateTime cannot parse firestore timestamp
      var text = '2018-10-20T05:13:45.985343Z';
      var dateTime = DateTime.tryParse(text);
      expect(dateTime, isNotNull);
      // VM: 2018-10-20T05:13:45.985343Z
      // Browser 2018-10-20T05:13:45.985Z
      // Node 2018-10-20T05:13:45.985Z
      expect(
          dateTime.toIso8601String(),
          _runningAsJavascript
              ? '2018-10-20T05:13:45.985Z'
              : '2018-10-20T05:13:45.985343Z');
      // print(dateTime.toIso8601String());

      text = '2018-10-20T05:13:45.985Z';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNotNull);
      expect(dateTime.toIso8601String(), '2018-10-20T05:13:45.985Z');
      // 2018-10-20T05:13:45.985Z
      // print(dateTime.toIso8601String());

      text = '2018-10-20T05:13:45Z';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNotNull);
      // 2018-10-20T05:13:45.000Z
      // print(dateTime.toIso8601String());

      text = '2018-10-20T05:13Z';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNotNull);
      // 2018-10-20T05:13:00.000Z
      // print(dateTime.toIso8601String());

      text = '2018-10-20T05Z';
      dateTime = DateTime.tryParse(text);
      // expect(dateTime, isNotNull);
      // 2018-10-20T05:00:00.000Z
      // print(dateTime.toIso8601String());

      text = '2018-10-20Z';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNull);

      text = '2018-10-20';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNotNull);
      // 2018-10-20T00:00:00.000
      // print(dateTime.toIso8601String());

      text = '2018-10';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNull);
      // 2018-10-20T00:00:00.000

      /*
      // Cannot parse this
      // This works as of dart dev 2.7.1
      text = '2018-10-20T05:13:45.985343123Z';
      dateTime = DateTime.tryParse(text);
      expect(dateTime, isNull);
       */
    });
  });
}
