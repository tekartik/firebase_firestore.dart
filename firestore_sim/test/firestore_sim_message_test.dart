import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_message.dart';
import 'package:test/test.dart';

void main() {
  group('message', () {
    test('DocumentSnapshotData', () {
      var map = {
        'path': 'path',
        'data': {'test': 1},
        'createTime': '1234-01-23T01:23:45.123Z',
        'updateTime': '1234-12-01T01:23:45.456Z',
      };
      var snapshotData = DocumentSnapshotData.fromMessageMap(map);
      expect(snapshotData.toMap(), map);
    });
  });
}
