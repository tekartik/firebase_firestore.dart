import 'package:tekartik_firebase_firestore/firestore.dart';

/// Marker mixin for [Transaction] implementations that do not need any
/// shared bookkeeping beyond the interface itself.
mixin TransactionMixin implements Transaction {}
