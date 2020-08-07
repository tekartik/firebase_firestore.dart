import 'package:tekartik_firebase_firestore_browser/firestore_browser.dart';
import 'package:test/test.dart';
import 'package:tekartik_common_utils/env_utils.dart';

void main() {
  test('firestoreServiceBrowser', () {
    try {
      firestoreServiceBrowser;
      expect(isRunningAsJavascript, isTrue);
    } on UnimplementedError catch (_) {
      expect(isRunningAsJavascript, isFalse);
    }
  });
}
