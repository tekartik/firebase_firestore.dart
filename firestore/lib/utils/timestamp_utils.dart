@Deprecated('Should not be public')
library;

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/timestamp_utils.dart' as impl;

/// Date time has micros.
@Deprecated('Should not be public')
bool get dateTimeHasMicros => impl.dateTimeHasMicros;

/// Update time key.
@Deprecated('Should not be public')
const updateTimeKey = impl.updateTimeKey;

/// Create time key.
@Deprecated('Should not be public')
const createTimeKey = impl.createTimeKey;

/// Min update time.
@Deprecated('Should not be public')
const minUpdateTime = impl.minUpdateTime;

/// Min create time.
@Deprecated('Should not be public')
const minCreateTime = impl.minCreateTime;

/// Map update time.
@Deprecated('Should not be public')
Timestamp mapUpdateTime(Map<String, Object?> recordMap) =>
    impl.mapUpdateTime(recordMap);

/// Map create time.
@Deprecated('Should not be public')
Timestamp mapCreateTime(Map<String, Object?> recordMap) =>
    impl.mapCreateTime(recordMap);
