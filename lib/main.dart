import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:atonement/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'messaging.dart';

void main() {
  runApp(const MyApp());

  initFirebase();
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
                  backgroundImage: NetworkImage(currentUser.value?.photoUrl ?? ''),
                )),
            additionalInfo: Obx(() => Text(currentUser.value?.displayName ?? '未登录')),
            trailing: const CupertinoListTileChevron(),
            onTap: handleSignIn,
          ),
          CupertinoListTile.notched(
            title: const Text('FCM Token'),
            leading: const Icon(CupertinoIcons.bell, color: CupertinoColors.systemYellow),
            trailing: const Icon(CupertinoIcons.doc_on_doc, color: CupertinoColors.systemYellow),
            onTap: () => Clipboard.setData(ClipboardData(text: fcmToken.value.toString())),
          ),
          const CupertinoListTile.notched(
            title: Text('登出'),
            leading: Icon(CupertinoIcons.power, color: CupertinoColors.systemRed),
            onTap: handleSignOut,
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
            onPressed: currentUser.value == null ? null : () => pushMessage(vm.controller.text),
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
        stream: messageSource,
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
