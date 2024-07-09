/// atonement - messaging
/// Created by xhz on 6/28/24
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'firebase_options.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
CollectionReference<Map<String, dynamic>> _messageDb = _firestore.collection('messages');

Stream<QuerySnapshot<Map<String, dynamic>>> get messageSource =>
    _messageDb.orderBy('time', descending: true).snapshots();

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

final Rx<GoogleSignInAccount?> currentUser = null.obs;
final Rx<String?> fcmToken = null.obs;

void _signIn() async {
  final signedIn = await _googleSignIn.isSignedIn();

  _googleSignIn.onCurrentUserChanged.listen(handleAccount);
  if (_googleSignIn.currentUser != null && signedIn) {
    handleAccount(_googleSignIn.currentUser);
  } else {
    _googleSignIn.signInSilently(reAuthenticate: true);
  }
}

void _initNotification() async {
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

  print('Notification permission: ${settings.authorizationStatus}');
  SmartDialog.showToast('Notification permission: ${settings.authorizationStatus}');

  fcmToken.listen(_pushToken);
  try {
    fcmToken.value = await FirebaseMessaging.instance
        .getToken(vapidKey: "BJOH1yndL3f6ZACCOjd20QpM8SNpSdWDAZMKSsMLWMdnivi_9hBeIgzCkvjWhXSrM76M1B561lZ7dHrcEf1zpig");
  } catch (e) {
    print('Failed to get fcm token: $e');
  }

  try {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      print('Token refreshed: $token');
      fcmToken.value = token;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        SmartDialog.showToast(message.notification?.title ?? 'New message');
      }
    });
  } catch (e) {
    print(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

void initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _signIn();
  _initNotification();
}

Future<void> pushMessage(String content) async {
  if (content.isEmpty) {
    SmartDialog.showToast('Content is empty');
    return Future.value();
  }
  try {
    final time = DateTime.now().millisecondsSinceEpoch;
    final sender = currentUser.value!.displayName;
    final avatar = currentUser.value!.photoUrl;
    final DocumentReference doc = await _messageDb.add({
      'content': content,
      'time': time,
      'send': sender,
      'avatar': avatar,
      'read': 0,
    });
    print('Message added with ID: ${doc.id}');
    SmartDialog.showToast('Message added');

    final resp = await http.post(
      Uri.parse('https://at.mar1sa.icu/push'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'sender': sender,
          'content': content,
          'avatar': avatar,
        },
      ),
    );
    print(resp.body);
  } catch (e) {
    print(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

Future<void> _pushToken(String? token) async {
  if (token == null) {
    return Future.value();
  }
  try {
    final resp = await http.post(
      Uri.parse('https://at.mar1sa.icu/pushToken'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{'token': token}),
    );

    print(resp.body);
  } catch (e) {
    print(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

Future<void> handleSignOut() async {
  try {
    await _googleSignIn.signOut();
  } catch (error) {
    print(error);
    SmartDialog.showToast(error.toString());
  }
}

Future<void> handleNoWebSignIn() async {
  try {
    await _googleSignIn.signIn();
  } catch (error) {
    print(error);
    SmartDialog.showToast(error.toString());
  }
}

void handleAccount(GoogleSignInAccount? account) async {
  currentUser.value = account;
  if (account == null) return;
  try {
    final GoogleSignInAuthentication signInAuthentication = await account.authentication;
    print('accessToken: ${signInAuthentication.accessToken}');
    print('idToken: ${signInAuthentication.idToken}');
  } catch (e) {
    print(e.toString());
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
  if (message.data['path'] == '/posts') {
    Get.toNamed('/post');
  }
}
