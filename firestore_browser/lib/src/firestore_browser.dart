import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_browser/firestore_browser.dart';

import 'firestore_browser_stub.dart'
    if (dart.library.html) 'firestore_browser_web.dart';

export 'firestore_browser_stub.dart'
    if (dart.library.html) 'firestore_browser_web.dart'
    show firestoreServiceBrowser;

@Deprecated('Use firestoreServiceBrowser')
FirestoreService get firestoreService => firestoreServiceBrowser;
