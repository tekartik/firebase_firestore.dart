@Deprecated('Should not be public')
library;

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/timestamp_utils.dart' as impl;

@Deprecated('Should not be public')
bool get dateTimeHasMicros => impl.dateTimeHasMicros;

@Deprecated('Should not be public')
const updateTimeKey = impl.updateTimeKey;
@Deprecated('Should not be public')
const createTimeKey = impl.createTimeKey;

@Deprecated('Should not be public')
const minUpdateTime = impl.minUpdateTime;
@Deprecated('Should not be public')
const minCreateTime = impl.minCreateTime;

@Deprecated('Should not be public')
Timestamp mapUpdateTime(Map<String, Object?> recordMap) =>
    impl.mapUpdateTime(recordMap);

@Deprecated('Should not be public')
Timestamp mapCreateTime(Map<String, Object?> recordMap) =>
    impl.mapCreateTime(recordMap);
