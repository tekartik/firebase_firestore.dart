// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:tekartik_firebase_firestore/firestore.dart';

/// Utility class for generating Firebase child node keys.
///
/// Since the Flutter plugin API is asynchronous, there's no way for us
/// to use the native SDK to generate the node key synchronously and we
/// have to do it ourselves if we want to be able to reference the
/// newly-created node synchronously.
///
/// This code is based largely on the Android implementation and ported to Dart.

class AutoIdGenerator {
  static const int _autoIdLength = 20;

  static const String _autoIdAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  static final Random _random = Random();

  /// Automatically Generates a random new Id
  static String autoId() {
    final stringBuffer = StringBuffer();
    const maxRandom = _autoIdAlphabet.length;

    for (var i = 0; i < _autoIdLength; ++i) {
      stringBuffer.write(_autoIdAlphabet[_random.nextInt(maxRandom)]);
    }

    return stringBuffer.toString();
  }
}

/// Collection reference extension to generate unique id
extension TekartikCollectionReferenceUniqueId on CollectionReference {
  /// Safe unique id generation
  Future<String> txnGenerateUniqueId(
    Transaction txn, {
    String Function()? customGenerator,
  }) async {
    String uniqueId;
    while (true) {
      uniqueId = customGenerator?.call() ?? AutoIdGenerator.autoId();
      if (!(await txn.get(doc(uniqueId))).exists) {
        break;
      }
    }
    return uniqueId;
  }
}
