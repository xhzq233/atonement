/// atonement - log
/// Created by xhz on 7/10/24
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:framework/platform.dart';
import 'account.dart';

CollectionReference<Map<String, dynamic>> _logDb = FirebaseFirestore.instance.collection('logs');

void fireLogI(String message) {
  _log(message, 'Info');
}

void fireLogE(String message) {
  _log(message, 'Error');
}

void _log(String message, String type) {
  if (hasAccount) {
    _logDb.add({
      'message': message,
      'type': type,
      'user': displayName,
      'time': DateTime.now().toString(),
      'device': deviceName,
    });
  }
  debugPrint('$type: $message');
}
