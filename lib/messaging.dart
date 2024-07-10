/// atonement - messaging
/// Created by xhz on 6/28/24
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'firebase_options.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
CollectionReference<Map<String, dynamic>> _messageDb = _firestore.collection('messages');
CollectionReference<Map<String, dynamic>> _logDb = _firestore.collection('logs');

void fireLogI(String message) {
  _logDb.add({
    'message': message,
    'type': 'Info',
    'user': currentUser.value?.displayName ?? 'Unknown',
    'time': DateTime.now().millisecondsSinceEpoch,
  });
}

void fireLogE(String message) {
  _logDb.add({
    'message': message,
    'type': 'Error',
    'user': currentUser.value?.displayName ?? 'Unknown',
    'time': DateTime.now().millisecondsSinceEpoch,
  });
}

Stream<QuerySnapshot<Map<String, dynamic>>> get messageSource =>
    _messageDb.orderBy('time', descending: true).snapshots();

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class GoogleSignInAccountStore {
  final String displayName;
  final String email;
  final String photoUrl;
  final String id;
  String? idToken;

  GoogleSignInAccountStore({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.id,
    this.idToken,
  });
}

final Rx<GoogleSignInAccountStore?> currentUser = null.obs;
final Rx<String?> fcmToken = null.obs;
late final Box<String> _userBox;

void initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _userBox = await Hive.openBox<String>('user');

  _signInGoogle();
}

void _signInGoogle() async {
  final signedIn = await _googleSignIn.isSignedIn();

  _googleSignIn.onCurrentUserChanged.listen(_handleGoogleAccount);
  if (_googleSignIn.currentUser != null && signedIn) {
    _handleGoogleAccount(_googleSignIn.currentUser);
  } else {
    final localUser = _userBox.containsKey('displayName');
    if (localUser) {
      _handleLocalAccount();
    } else {
      _googleSignIn.signInSilently(reAuthenticate: true);
    }
  }
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
    fcmToken.value = await FirebaseMessaging.instance
        .getToken(vapidKey: "BJOH1yndL3f6ZACCOjd20QpM8SNpSdWDAZMKSsMLWMdnivi_9hBeIgzCkvjWhXSrM76M1B561lZ7dHrcEf1zpig");
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

    fireLogI('Message added with ID: ${doc.id}, response: ${resp.body}');
    SmartDialog.showToast('Message added');
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

Future<void> _pushToken(String? token) async {
  if (token == null) {
    return Future.value();
  }
  if (currentUser.value == null) {
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
        'name': currentUser.value!.displayName,
      }),
    );
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

Future<void> handleSignOut() async {
  try {
    await _googleSignIn.signOut();
  } catch (error) {
    fireLogE(error.toString());
    SmartDialog.showToast(error.toString());
  }
}

Future<void> handleNoWebSignIn() async {
  try {
    await _googleSignIn.signIn();
  } catch (error) {
    fireLogE(error.toString());
    SmartDialog.showToast(error.toString());
  }
}

void _handleGoogleAccount(GoogleSignInAccount? account) async {
  if (account == null) return;
  String? idToken;
  try {
    final GoogleSignInAuthentication signInAuthentication = await account.authentication;
    idToken = signInAuthentication.idToken;
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
  _userBox.put('displayName', account.displayName ?? 'Unknown');
  _userBox.put('email', account.email);
  _userBox.put('photoUrl', account.photoUrl ?? '');
  _userBox.put('id', account.id);
  if (idToken != null) _userBox.put('idToken', idToken);
  _handleLocalAccount();
}

void _handleLocalAccount() {
  currentUser.value = GoogleSignInAccountStore(
    displayName: _userBox.get('displayName')!,
    email: _userBox.get('email') ?? 'Unknown',
    photoUrl: _userBox.get('photoUrl') ?? '',
    id: _userBox.get('id') ?? 'Unknown',
    idToken: _userBox.get('idToken'),
  );
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
