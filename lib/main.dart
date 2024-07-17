import 'package:atonement/bubble.dart';
import 'package:atonement/pick_image.dart';
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
import 'disable_backswipe.dart';
import 'firebase_options.dart';
import 'platform/sign_in_button.dart';
import 'messaging.dart';

part 'drawer.dart';

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    fireLogE(details.exception.toString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack));
    return true;
  };

  runApp(const MyApp());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initLog();
  initMessaging();
  initAccount();
}

final navigatorKey = GlobalKey<NavigatorState>();

NavigatorState get navigator => navigatorKey.currentState!;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SmartDialog.config.toast = SmartConfigToast(displayTime: const Duration(milliseconds: 2500));
    return MaterialApp(
      theme: lightThemeData,
      darkTheme: darkThemeData,
      title: 'Atonement',
      scrollBehavior: const CupertinoScrollBehavior(),
      routes: {
        '/': (context) => const DisableBackSwipe(child: _Home()),
        '/posts': (context) => const DisableBackSwipe(child: _Posts()),
      },
      builder: FlutterSmartDialog.init(builder: (context, child) => child!),
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
            backgroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                child: PickedImage(child: _TextField()),
              ),
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PickImageWidget(),
            Obx(
              () => CupertinoButton(
                onPressed: hasAccount && !pushingMessage.value
                    ? () {
                        controller.clear();
                        PickedImage.read(context).setPickImageState(PickImageState.none);
                        pushMessage(
                          controller.text,
                          imageUrl: PickedImage.read(context).imageUrl,
                        );
                      }
                    : null,
                child: const Icon(CupertinoIcons.paperplane),
              ),
            ),
          ],
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
      navigationBar: const CupertinoNavigationBar(middle: Text('记录')),
      child: StreamBuilder(
        stream: messageSource,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
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
          if (snapshot.data!.docs.isEmpty || !snapshot.hasData) {
            return const Align(child: Text('No data'));
          }

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.docs.length,
            itemBuilder: (BuildContext context, int index) => Bubble(data: data.docs[index].data()),
          );
        },
      ),
    );
  }
}
