/// atonement - messaging
/// Created by xhz on 6/28/24
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:framework/route.dart';
import 'package:get/get_rx/get_rx.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'account.dart';
import 'log.dart';

final CollectionReference<Map<String, dynamic>> _messageDb = FirebaseFirestore.instance.collection('messages');

final CollectionReference<Map<String, dynamic>> _todoDb = FirebaseFirestore.instance.collection('todos');

// send
// content
// time
// avatar
// imageUrl
// read
Stream<QuerySnapshot<Post>> get postSource => _messageDb
    .withConverter(fromFirestore: Post.fromFirestore, toFirestore: (value, _) => value.toJson())
    .orderBy('time', descending: true)
    .snapshots();

// send
// content
// time
// avatar
// imageUrl
// complete
Stream<QuerySnapshot<Todo>> get todoSource => _todoDb
    .withConverter(fromFirestore: Todo.fromFirestore, toFirestore: (value, _) => value.toJson())
    .orderBy('time', descending: true)
    .snapshots();

class _Message {
  final String id;
  final String send;
  final String content;
  final DateTime time;
  final String avatar;
  final String? imageUrl;

  _Message({
    required this.id,
    required this.send,
    required this.content,
    required this.time,
    required this.avatar,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'send': send,
        'content': content,
        'time': time.millisecondsSinceEpoch,
        'avatar': avatar,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

class Post extends _Message {
  final bool read;

  Post({
    required super.id,
    required super.send,
    required super.content,
    required super.time,
    required super.avatar,
    required super.imageUrl,
    required this.read,
  });

  factory Post.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Post(
      id: snapshot.id,
      send: data?['send'] ?? 'Unknown',
      content: data?['content'] ?? 'NA',
      time: DateTime.fromMillisecondsSinceEpoch(data?['time'] ?? 0),
      avatar: data?['avatar'] ?? '',
      imageUrl: data?['imageUrl'],
      read: data?['read'] == 1,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'read': read ? 1 : 0,
      };
}

class Todo extends _Message {
  final bool complete;

  Todo({
    required super.id,
    required super.send,
    required super.content,
    required super.time,
    required super.avatar,
    required super.imageUrl,
    required this.complete,
  });

  factory Todo.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Todo(
      id: snapshot.id,
      send: data?['send'] ?? 'Unknown',
      content: data?['content'] ?? 'NA',
      time: DateTime.fromMillisecondsSinceEpoch(data?['time'] ?? 0),
      avatar: data?['avatar'] ?? '',
      imageUrl: data?['imageUrl'],
      complete: data?['complete'] == 1,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'complete': complete ? 1 : 0,
      };
}

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

Future<void> completeTodo(Todo todo) async {
  final DocumentReference<Map<String, dynamic>> doc = _todoDb.doc(todo.id);
  if (pushingMessage.value) {
    fireLogE('try completeTodo${todo.toJson()} twice');
    return;
  }
  pushingMessage.value = true;
  try {
    await doc.update({'complete': 1});

    final resp = await http.post(
      Uri.parse('https://at.mar1sa.icu/push'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'sender': displayName,
          'content': '「${todo.content}」 已完成',
          'avatar': currentUser.value.photoUrl,
        },
      ),
    );

    fireLogI('${todo.content} completed: ${todo.id}, response: ${resp.body}');
    SmartDialog.showToast('${todo.content} completed');
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }

  pushingMessage.value = false;
}

Future<void> pushMessage(String content, {String? imageUrl, bool todo = false}) async {
  if (content.isEmpty) {
    SmartDialog.showToast('内容为空');
    return Future.value();
  }
  String readKey = 'read';
  final CollectionReference<Map<String, dynamic>> targetDb = todo ? _todoDb : _messageDb;
  if (todo) {
    fireLogI('pushing todo:$content');
    readKey = 'complete';
  }
  if (pushingMessage.value) {
    fireLogE('try pushing "$content" twice');
    return;
  }
  pushingMessage.value = true;
  try {
    final time = DateTime.now().millisecondsSinceEpoch;
    final avatar = currentUser.value.photoUrl;
    final DocumentReference doc = await targetDb.add({
      'content': content,
      'time': time,
      'send': displayName,
      'avatar': avatar,
      readKey: 0,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    final resp = await http.post(
      Uri.parse('https://at.mar1sa.icu/push'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          'sender': displayName,
          'content': todo ? '愿望：$content' : content,
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
  if (message.data['path'] != null) {
    rootNavigator.pushNamed(message.data['path']);
  }
}
