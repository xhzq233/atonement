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

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference<Map<String, dynamic>> message = firestore.collection('messages');
GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: '80750108764-kfjd619q2e4cchruateg3uv0j32ncnrc.apps.googleusercontent.com',
  scopes: ['email'],
);
final Rx<GoogleSignInAccount?> _currentUser = null.obs;

Future<void> _new(String content) {
  // Call the user's CollectionReference to add a new user
  return message.add({
    'content': content,
    'time': DateTime.now().millisecondsSinceEpoch,
    'send': _currentUser.value!.displayName,
    'read': 0,
  }).then((DocumentReference doc) {
    print('Message added with ID: ${doc.id}');
    SmartDialog.showToast('Message added');
  }).catchError((error) {
    print("Failed to add messasge: $error");
    SmartDialog.showToast(error.toString());
  });
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

  _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) => _currentUser.value = account);
  _googleSignIn.signInSilently();

  () async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken(
          vapidKey: "BJOH1yndL3f6ZACCOjd20QpM8SNpSdWDAZMKSsMLWMdnivi_9hBeIgzCkvjWhXSrM76M1B561lZ7dHrcEf1zpig");
      print(fcmToken.toString());
    } catch (e) {
      print(e.toString());
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
            largeTitle: const Text('New'),
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
            leading: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.activeGreen,
            ),
            additionalInfo: Text(_currentUser.value?.displayName ?? '未登录'),
            trailing: const CupertinoListTileChevron(),
            onTap: _handleSignIn,
          ),
          CupertinoListTile.notched(
            title: const Text('登出'),
            leading: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.systemRed,
            ),
            trailing: const Icon(CupertinoIcons.delete),
            onTap: _googleSignIn.signOut,
          ),
        ],
      ),
    );
  }
}

class _TextFieldViewModel extends GetxController {
  final controller = TextEditingController();
  RxBool isEditing = false.obs;
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
            onPressed: _currentUser.value == null ? null : () => _new(vm.controller.text),
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
        stream: message.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CupertinoActivityIndicator();
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
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
