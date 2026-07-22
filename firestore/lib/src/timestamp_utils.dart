import 'package:tekartik_firebase_firestore/firestore.dart';

bool get _runningAsJavascript => identical(1, 1.0);

/// Date time has micros.
bool get dateTimeHasMicros => !_runningAsJavascript;

// Copied from sembast

/// The reserved key used within a record map to store its last-update time.
const updateTimeKey = r'$updateTime';

/// The reserved key used within a record map to store its creation time.
const createTimeKey = r'$createTime';

/// Min update time (arbitrary, set when the project was created)
const minUpdateTime = '2018-10-23T00:00:00.000000Z';

/// Min create time (arbitrary, set when the project was created)
const minCreateTime = '2018-10-23T00:00:00.000000Z';

/// Returns the [Timestamp] stored in [recordMap] under [updateTimeKey], or
/// an arbitrary minimum timestamp if the key is absent.
Timestamp mapUpdateTime(Map<String, Object?> recordMap) =>
    Timestamp.parse(recordMap[updateTimeKey] as String? ?? minUpdateTime);

/// Returns the [Timestamp] stored in [recordMap] under [createTimeKey], or
/// an arbitrary minimum timestamp if the key is absent.
Timestamp mapCreateTime(Map<String, Object?> recordMap) =>
    Timestamp.parse(recordMap[createTimeKey] as String? ?? minCreateTime);
