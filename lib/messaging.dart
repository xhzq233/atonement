/// atonement - messaging
/// Created by xhz on 6/28/24
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'account.dart';
import 'log.dart';

CollectionReference<Map<String, dynamic>> _messageDb = FirebaseFirestore.instance.collection('messages');

Stream<QuerySnapshot<Map<String, dynamic>>> get messageSource =>
    _messageDb.orderBy('time', descending: true).snapshots();

final RxString fcmToken = 'null'.obs;

final RxBool pushingMessage = false.obs;

void initMessaging() async {
  setupInteractedMessage();
}

void initNotification() async {
  NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();

  if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  fireLogI('Notification permission: ${settings.authorizationStatus}');
  SmartDialog.showToast('Notification permission: ${settings.authorizationStatus}');

  fcmToken.listen(_pushToken);
  try {
    fcmToken.value = await FirebaseMessaging.instance.getToken(
            vapidKey: "BJOH1yndL3f6ZACCOjd20QpM8SNpSdWDAZMKSsMLWMdnivi_9hBeIgzCkvjWhXSrM76M1B561lZ7dHrcEf1zpig") ??
        'null';
  } catch (e) {
    fireLogE('Failed to get fcm token: $e');
  }

  try {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      fireLogI('Token refreshed: $token');
      fcmToken.value = token;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      fireLogI('Got a message whilst in the foreground! Data: ${message.data}');

      if (message.notification != null) {
        fireLogI('Message also contained a notification: ${message.notification}');
        SmartDialog.showToast(message.notification?.title ?? 'New message');
      }
    });
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

Future<void> pushMessage(String content, {String? imageUrl}) async {
  if (content.isEmpty) {
    SmartDialog.showToast('内容为空');
    return Future.value();
  }
  pushingMessage.value = true;
  try {
    final time = DateTime.now().millisecondsSinceEpoch;
    final avatar = currentUser.value.photoUrl;
    final DocumentReference doc = await _messageDb.add({
      'content': content,
      'time': time,
      'send': displayName,
      'avatar': avatar,
      'read': 0,
      'imageUrl': imageUrl,
    });
    final resp = await http.post(
      Uri.parse('https://at.mar1sa.icu/push'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'sender': displayName,
          'content': content,
          'avatar': avatar,
        },
      ),
    );

    fireLogI('Message added with ID: ${doc.id}, response: ${resp.body}');
    SmartDialog.showToast('Message added');
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
  pushingMessage.value = false;
}

Future<void> _pushToken(String token) async {
  if (token == 'null') {
    return Future.value();
  }
  if (currentUser.value == LocalAccount.empty) {
    SmartDialog.showToast('User not signed in');
    fireLogE('User not signed in');
    return Future.value();
  }
  try {
    await http.post(
      Uri.parse('https://at.mar1sa.icu/pushToken'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'token': token,
        'name': '$displayName@$device',
      }),
    );
    fireLogI('Token pushed: $token, $displayName@$device');
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

// It is assumed that all messages contain a data field with the key 'type'
Future<void> setupInteractedMessage() async {
  // Get any messages which caused the application to open from
  // a terminated state.
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  // If the message also contains a data property with a "type" of "chat",
  // navigate to a chat screen
  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }

  // Also handle any interaction when the app is in the background via a
  // Stream listener
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

void _handleMessage(RemoteMessage message) {
  fireLogI('A message caused the application to open: ${message.data}');
  if (message.data['path'] == '/posts') {
    Get.toNamed('/post');
  }
}
