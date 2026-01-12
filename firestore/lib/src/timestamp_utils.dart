import 'package:tekartik_firebase_firestore/firestore.dart';

bool get _runningAsJavascript => identical(1, 1.0);

/// Date time has micros.
bool get dateTimeHasMicros => !_runningAsJavascript;

// Copied from sembast

/// Update time key
const updateTimeKey = r'$updateTime';

/// Create time key
const createTimeKey = r'$createTime';

/// Min update time (arbitrary, set when the project was created)
const minUpdateTime = '2018-10-23T00:00:00.000000Z';

/// Min create time (arbitrary, set when the project was created)
const minCreateTime = '2018-10-23T00:00:00.000000Z';

/// Map update time.
Timestamp mapUpdateTime(Map<String, Object?> recordMap) =>
    Timestamp.parse(recordMap[updateTimeKey] as String? ?? minUpdateTime);

/// Map create time.
Timestamp mapCreateTime(Map<String, Object?> recordMap) =>
    Timestamp.parse(recordMap[createTimeKey] as String? ?? minCreateTime);
