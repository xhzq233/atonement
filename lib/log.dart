/// atonement - log
/// Created by xhz on 7/10/24
library;

import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'account.dart';

final deviceInfoPlugin = DeviceInfoPlugin();
late final Map<String, dynamic> deviceInfo;
late final String device;
CollectionReference<Map<String, dynamic>> _logDb = FirebaseFirestore.instance.collection('logs');

Future<void> initLog() async {
  deviceInfo = (await deviceInfoPlugin.deviceInfo).data;
  if (kIsWeb) {
    device = deviceInfo['platform'].toString();
  } else {
    device = 'NoneWeb';
  }
}

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
      'time': DateTime.now().millisecondsSinceEpoch,
      'device': device,
    });
  }
  log('$type: $message');
}
