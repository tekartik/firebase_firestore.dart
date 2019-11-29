import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore_rest/snapshot.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:test/test.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

class DocumentSnapshotMock implements DocumentSnapshot {
  @override
  Timestamp createTime;

  @override
  Map<String, dynamic> data;

  @override
  bool get exists => data != null;

  @override
  DocumentReference ref;

  @override
  Timestamp updateTime;
}

void main() {
  var firebase = FirebaseLocal();
  var firestoreService = firestoreServiceMemory;
  App app = firebase.initializeApp(options: AppOptions(projectId: 'my_app'));
  var firestore = firestoreService.firestore(app);

  tearDownAll(() {
    return app.delete();
  });
  group('snapshot', () {
    test('documentDataToJson', () {
      var data = DocumentDataMap();
      data.setString('string', 'text');
      data.setInt('int', 1);
      data.setBool('bool', true);
      data.setDateTime(
          'dateTime', DateTime.parse('2018-10-23T16:04:46.071Z').toLocal());
      data.setGeoPoint('geo', GeoPoint(23.03, 19.84));
      data.setBlob('blob', Blob.fromList([1, 2, 3]));
      data.setNum('double', 19.84);
      data.setDocumentReference('ref', firestore.doc('path'));
      data.setList('list', [2, 'item']);
      data.setData(
          'nested', DocumentData()..setString('nestedKey', 'much nested'));
      expect(documentDataToJson(app, data), {
        "fields": {
          "string": {"stringValue": "text"},
          'int': {'integerValue': '1'},
          "bool": {"booleanValue": true},
          'dateTime': {'timestampValue': '2018-10-23T16:04:46.071Z'},
          "geo": {
            "geoPointValue": {"latitude": 23.03, "longitude": 19.84}
          },
          "blob": {"bytesValue": "AQID"},
          "double": {"doubleValue": 19.84},
          "ref": {
            "referenceValue":
                "projects/my_app/databases/(default)/documents/path"
          },
          "list": {
            "arrayValue": {
              "values": [
                {"integerValue": "2"},
                {"stringValue": "item"}
              ]
            }
          },
          "nested": {
            "mapValue": {
              "fields": {
                "nestedKey": {"stringValue": "much nested"}
              }
            }
          },
        }
      });
    });
  });
}
