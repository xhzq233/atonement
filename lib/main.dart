import 'package:atonement/log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:atonement/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/state_manager.dart';
import 'account.dart';
import 'firebase_options.dart';
import 'platform/sign_in_button.dart';
import 'messaging.dart';

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack));
    return true;
  };

  runApp(const MyApp());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initMessaging();
  initAccount();
  initLog();
}

final navigatorKey = GlobalKey<NavigatorState>();

NavigatorState get navigator => navigatorKey.currentState!;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightThemeData,
      darkTheme: darkThemeData,
      title: 'Atonement',
      scrollBehavior: const CupertinoScrollBehavior(),
      routes: {
        '/': (context) => const _Home(),
        '/posts': (context) => const _Posts(),
      },
      builder: FlutterSmartDialog.init(),
      navigatorKey: navigatorKey,
      initialRoute: '/',
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _Drawer(),
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('写点什么'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => navigator.pushNamed('/posts'),
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
            onTap: kIsWeb ? null : handleNoWebGoogleSignIn,
            leading: Obx(() => CircleAvatar(
                foregroundImage: NetworkImage(currentUser.value.photoUrl),
                onForegroundImageError: (exception, stackTrace) {})),
            trailing: Obx(() => hasAccount ? Text(displayName) : buildSignInButton(onPressed: handleNoWebGoogleSignIn)),
          ),
          CupertinoListTile.notched(
            title: const Text('FCM Token'),
            leading: const Icon(Icons.key_rounded, color: CupertinoColors.systemIndigo),
            trailing: const Icon(CupertinoIcons.doc_on_doc, color: CupertinoColors.systemIndigo),
            onTap: () => Clipboard.setData(ClipboardData(text: fcmToken.value.toString())),
          ),
          const CupertinoListTile.notched(
            title: Text('初始化通知'),
            leading: Icon(CupertinoIcons.bell, color: CupertinoColors.systemYellow),
            trailing: CupertinoListTileChevron(),
            onTap: initNotification,
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

class _TextField extends StatelessWidget {
  const _TextField();

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, minHeight: 200),
          child: CupertinoTextField(
            placeholder: "写点什么",
            controller: controller,
            clearButtonMode: OverlayVisibilityMode.editing,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
        ),
        Obx(
          () => CupertinoButton(
            onPressed: hasAccount && !pushingMessage.value ? () => pushMessage(controller.text) : null,
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
                widthFactor: 0.07,
                heightFactor: 0.07,
                child: FittedBox(child: CupertinoActivityIndicator()),
              ),
            );
          }

          // Empty
          if (snapshot.data!.docs.isEmpty) {
            return const Align(child: Text('No data'));
          }

          return _PostList(snapshot: snapshot);
        },
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({required this.snapshot});

  final AsyncSnapshot<QuerySnapshot> snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (BuildContext context, int index) {
        final document = snapshot.data!.docs[index];
        Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
        final String sender = data['send'];
        final String content = data['content'];
        final datetime = DateTime.fromMillisecondsSinceEpoch(data['time']);
        final String? avatar = data['avatar'];
        final formattedDate = datetime.toString();

        Widget avatarWidget;
        if (avatar != null) {
          avatarWidget = CircleAvatar(
            backgroundImage: NetworkImage(avatar),
            onBackgroundImageError: (exception, stackTrace) {},
          );
        } else {
          avatarWidget = const Icon(CupertinoIcons.person);
        }

        avatarWidget = SizedBox(width: 32, height: 32, child: avatarWidget);

        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleMedium!,
                child: Row(
                  children: [
                    avatarWidget,
                    const SizedBox(width: 8),
                    Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(formattedDate, style: TextStyle(color: CupertinoColors.systemGrey.resolveFrom(context))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(content),
            ],
          ),
        );
      },
    );
  }
}
