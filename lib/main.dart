import 'dart:developer';
import 'firebase_options.dart';

import 'package:atonement/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  runApp(const MyApp());

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
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        // TODO: If necessary send token to application server.

        // Note: This callback is fired at each app startup and whenever a new
        // token is generated.
        log(fcmToken.toString());
        log('aaaaaa');
      }).onError((err) {
        // Error getting token.
        log(err.toString());
      });
      log(fcmToken.toString());
    } catch (e) {
      log(e.toString());
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
        '/drafts': (context) => const _Drafts(),
      },
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
              onPressed: () => Get.toNamed('/drafts'),
              child: const Icon(CupertinoIcons.bookmark),
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
            title: const Text('Github'),
            leading: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.activeGreen,
            ),
            additionalInfo: const Text('用户名'),
            trailing: const CupertinoListTileChevron(),
          ),
          CupertinoListTile.notched(
            title: const Text('这是一个草稿'),
            leading: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.activeGreen,
            ),
            trailing: const CupertinoListTileChevron(),
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
        CupertinoButton(
          child: const Text('发布'),
          onPressed: () {
            log(vm.controller.text);
          },
        ),
      ],
    );
  }
}

class _Drafts extends StatelessWidget {
  const _Drafts();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('草稿'),
      ),
      child: CupertinoListSection.insetGrouped(
        header: const Text('草稿'),
        children: [
          CupertinoListTile.notched(
            title: const Text('这是一个草稿'),
            leading: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.activeGreen,
            ),
            trailing: const CupertinoListTileChevron(),
          ),
          CupertinoListTile.notched(
            title: const Text('这是一个草稿'),
            leading: Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoColors.activeGreen,
            ),
            trailing: const CupertinoListTileChevron(),
          ),
        ],
      ),
    );
  }
}
