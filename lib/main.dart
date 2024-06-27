import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

import 'package:atonement/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference<Map<String, dynamic>> message = firestore.collection('messages');
GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: '80750108764-kfjd619q2e4cchruateg3uv0j32ncnrc.apps.googleusercontent.com',
  scopes: ['email'],
);
final Rx<GoogleSignInAccount?> _currentUser = null.obs;
final Rx<String?> _fcmToken = null.obs;

// POST https://fcm.googleapis.com/v1/projects/myproject-b5ae1/messages:send HTTP/1.1
//
// Content-Type: application/json
// Authorization: Bearer ya29.ElqKBGN2Ri_Uz...HnS_uNreA
// {
//   "message":{
//     "topic" : "foo-bar",
//     "notification" : {
//       "body" : "This is a Firebase Cloud Messaging Topic Message!",
//       "title" : "FCM Message"
//       }
//    }
// }
Future<void> _newMessage(String content) async {
  if (content.isEmpty) {
    SmartDialog.showToast('Content is empty');
    return Future.value();
  }
  try {
    final DocumentReference doc = await message.add({
      'content': content,
      'time': DateTime.now().millisecondsSinceEpoch,
      'send': _currentUser.value!.displayName,
      'read': 0,
    });
    print('Message added with ID: ${doc.id}');
    SmartDialog.showToast('Message added');

    // Send http request to FCM
    http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/xhzq233-firebase-demo/messages:send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ya29.c.c0AY_VpZjji8FycSHT6gXh8GpjKZoTWGQCYLmelYz1vwKWM3niK-DB48GHd6EgkOepJNM4RZN9GGaYDyvQ03tRcQi6iNLHUiEhFXB7AVy3qk-ncqSIGoKpzymYPh-FC6AyzJh4SEaqm3xqCv7G6ICNFtV_-Zuvz8X0b3IrOg5RQdeHhTbxeCqM8zapZKIusnSqLyPRizZLLI-3DU7k3W6o55gDHGJJhUCPgkHv-esMJyl3aNUATD3Dww3PRoNh0QIsNSmNmCcWWB88s9qFOeviIIjRnjZwX3B8UQs0x0L21dIYrfGuAUcmYUPsIUTnTtXb7bCdA5NykxN1gXmT-Ox32RA4dTtvAiIRhUqFwGxe1qR3WygAiH0aUYYE384CldjgdQM8w7wimcZ28u595UiMhe4yh-RZRqmwaht6xMgWshhI1c0tQ6nex2Zg5Qjo4Sh8Y_dwsnZSd-sIO6gon4khYskgwuI-_9sVwo3fUyJ49eemUnMtaro5kaksBcZvWi1j01Mou44Qv7RFygpvpMU3xuMon8WsFyF3ZsZvXX7O-agQq3Uw74RkpSY9X_y7FxbJWv2F64x0MR_kRzgIJihWQ_Ucu2tdsVY_J3BalybtYBM6lQ8x_7US3dvoMybofpk-lo0qW8r4jsykleUlgQlmhUsR_Q-m0f_z8dkBmRJS7_WJYv1X6YM38Q6ym6SU47tvUpZ5WO-dJqkWhcpVcXRevgI_ZrJ5FzcRqRbB5FFg-b4l0F3g4I9UUSQbhias_MdV-lW3sZh2M5h43VVOnYOmspyams9_atQxex7i1nidQFRS4aIzB0MWIjJbiryYvnQVju2s-y1X_fpuhnOiergXRiqwkwm7j-k2oRw0kxlrjZcBfS_YBhORkJXjzs1qRw1_piQXh93l_0ye8Yyg07M9xbSB1vujqdfs3JJga6YMZk_8kWlY6qynhsO-u8k0kzzag7bcV_h4vcS2XrXoyYe7fdWhRe2IorJdeIObkU9QeyQZiB3BQX3aq7a',
      },
      body: <String, dynamic>{
        'message': <String, dynamic>{
          'topic': 'message',
          'notification': <String, dynamic>{
            'body': content,
            'title': 'New message',
          },
        },
      },
    );
  } catch (e) {
    print(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

Future<void> _handleSignIn() async {
  try {
    await _googleSignIn.signIn();
  } catch (error) {
    print(error);
    SmartDialog.showToast(error.toString());
  }
}

void main() {
  runApp(const MyApp());

  () async {
    final signedIn = await _googleSignIn.isSignedIn();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser.value = account;
    });
    if (_googleSignIn.currentUser != null && signedIn) {
      _currentUser.value = _googleSignIn.currentUser;
    } else {
      _googleSignIn.signInSilently();
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    }

    SmartDialog.showToast('User granted permission: ${settings.authorizationStatus}');

    try {
      _fcmToken.value = await FirebaseMessaging.instance.getToken(
          vapidKey: "BJOH1yndL3f6ZACCOjd20QpM8SNpSdWDAZMKSsMLWMdnivi_9hBeIgzCkvjWhXSrM76M1B561lZ7dHrcEf1zpig");
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
        print('Token refreshed: $token');
        _fcmToken.value = token;
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
  }();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: lightThemeData,
      darkTheme: darkThemeData,
      title: 'Atonement',
      scrollBehavior: const CupertinoScrollBehavior(),
      routes: {
        '/': (context) => const _Home(),
        '/posts': (context) => const _Posts(),
      },
      builder: FlutterSmartDialog.init(),
      initialRoute: '/',
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    Get.put(_TextFieldViewModel());
    return Scaffold(
      drawer: const _Drawer(),
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('写点什么'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Get.toNamed('/posts'),
              child: const Icon(CupertinoIcons.chat_bubble_2),
            ),
            leading: Builder(
                builder: (context) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      // open drawer
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      child: const Icon(CupertinoIcons.person),
                    )),
          ),
          const SliverFillRemaining(
            child: Align(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: _TextField(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: CupertinoListSection.insetGrouped(
        header: const Text('信息'),
        children: [
          CupertinoListTile.notched(
            title: const Text('Google 登录'),
            leading: Obx(() => CircleAvatar(
                  backgroundImage: NetworkImage(_currentUser.value?.photoUrl ?? ''),
                )),
            additionalInfo: Obx(() => Text(_currentUser.value?.displayName ?? '未登录')),
            trailing: const CupertinoListTileChevron(),
            onTap: _handleSignIn,
          ),
          CupertinoListTile.notched(
            title: const Text('FCM Token'),
            leading: const Icon(CupertinoIcons.bell, color: CupertinoColors.systemYellow),
            trailing: const Icon(CupertinoIcons.doc_on_doc, color: CupertinoColors.systemBlue),
            onTap: () => Clipboard.setData(ClipboardData(text: _fcmToken.value.toString())),
          ),
          CupertinoListTile.notched(
            title: const Text('登出'),
            leading: const Icon(CupertinoIcons.power, color: CupertinoColors.systemRed),
            onTap: _googleSignIn.signOut,
          ),
        ],
      ),
    );
  }
}

class _TextFieldViewModel extends GetxController {
  final controller = TextEditingController();
}

class _TextField extends GetView<_TextFieldViewModel> {
  const _TextField();

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<_TextFieldViewModel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, minHeight: 200),
          child: CupertinoTextField(
            placeholder: "写点什么",
            controller: vm.controller,
            clearButtonMode: OverlayVisibilityMode.editing,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
        ),
        Obx(
          () => CupertinoButton(
            onPressed: _currentUser.value == null ? null : () => _newMessage(vm.controller.text),
            child: const Text('发布'),
          ),
        ),
      ],
    );
  }
}

class _Posts extends StatelessWidget {
  const _Posts();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('记录'),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: message.orderBy('time', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Align(child: Text('Something went wrong ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Align(
              child: FractionallySizedBox(
                widthFactor: 0.1,
                heightFactor: 0.1,
                child: FittedBox(child: CupertinoActivityIndicator()),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              print(data);
              return CupertinoListTile(
                title: Text(data['content']),
                subtitle: Text(DateTime.fromMillisecondsSinceEpoch(data['time']).toIso8601String()),
                trailing: Text(
                  data['send'],
                  style: const TextStyle(
                    fontSize: 20,
                    color: CupertinoColors.systemGrey,
                    inherit: false,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
