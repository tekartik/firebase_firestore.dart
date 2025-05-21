import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/utils/export_utils.dart';
import 'package:test/test.dart';

void main() {
  group('export_utils', () {
    test('export', () async {
      var firestore = newFirestoreMemory();
      var export = await firestore.exportLines(collections: []);
      expect(export, [
        {'sembast_export': 1, 'version': 1},
      ]);
      export = await firestore.exportLines();
      expect(export, [
        {'sembast_export': 1, 'version': 1},
      ]);
      await firestore.doc('test/doc').set({'test': 1});
      export = await firestore.exportLines(
        collections: [firestore.collection('test')],
      );
      expect(export, hasLength(3));
      expect(export[1], {'store': 'doc'});
      expect((export[2] as List)[0], 'test/doc');
      //             {'sembast_export': 1, 'version': 1},
      //             {'store': 'doc'},
      //             [
      //               'test/doc',
      //               {
      //                 'test': 1,
      //                 '$rev': 1,
      //                 '$createTime': '2023-08-22T17:45:34.489989Z',
      //                 '$updateTime': '2023-08-22T17:45:34.489989Z'
      //               }
      //             ]
      //           ]
    });
  });
}
