import 'dart:async';

import 'package:atonement/bubble.dart';
import 'package:atonement/pick_image.dart';
import 'package:atonement/log.dart';
import 'package:atonement/platform/change_pwa_bar_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:framework/cupertino.dart';
import 'package:atonement/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:framework/route.dart';
import 'package:framework/widgets.dart';
import 'package:get/state_manager.dart';
import 'account.dart';
import 'firebase_options.dart';
import 'platform/sign_in_button.dart';
import 'messaging.dart';
import 'package:framework/base.dart';

part 'drawer.dart';

part 'main_body.dart';

class _CatcherDelegate with Catcher {
  @override
  void handleException(String name, String reason, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.recordError(reason, stackTrace, reason: name, printDetails: true);
  }

  @override
  void handleFlutterError(FlutterErrorDetails errorDetails) {
    FlutterError.presentError(errorDetails);
    FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  }

  @override
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const _MyApp());

    await initLog();
    SmartDialog.config.toast = SmartConfigToast(displayTime: const Duration(milliseconds: 2500));

    initMessaging();
    initAccount();
  }
}

void main() async {
  Catcher.init(delegate: _CatcherDelegate());
}

class _MyApp extends StatelessWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      changePWABarColorTo(brightness == Brightness.dark ? darkThemeData.primaryColor : lightThemeData.primaryColor);
    }
    return MaterialApp(
      theme: lightThemeData,
      darkTheme: darkThemeData,
      title: 'Atonement',
      scrollBehavior: const CupertinoScrollBehavior(),
      routes: {
        '/': (context) => const _Home(),
        '/posts': (context) => const _Posts(),
        '/todos': (context) => const _Todos(),
      },
      builder: FlutterSmartDialog.init(),
      navigatorKey: rootNavigatorKey,
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => rootNavigator.pushNamed('/todos'),
                  child: const Icon(CupertinoIcons.text_badge_checkmark),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => rootNavigator.pushNamed('/posts'),
                  child: const Icon(CupertinoIcons.chat_bubble_2),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).appBarTheme.foregroundColor,
            leading: Builder(
              builder: (context) => CustomCupertinoButton(
                onTap: Scaffold.of(context).openDrawer,
                child: Obx(() => NNImage(currentUser.value.photoUrl)),
              ),
            ),
          ),
          SliverFillRemaining(
            child: ProviderWidget.owned(
              provider: (ctx) => PickedImageProvider(),
              child: const _Content(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  double page = 0;
  int index = 0;

  late final PageController _controller = PageController(initialPage: 0);
  final tfController = TextEditingController();

  ThemeDataTween? _tween;

  ThemeDataTween _getTween() {
    final Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final ThemeData begin, end;
    if (brightness == Brightness.light) {
      begin = lightThemeData;
      end = ThemeData.lerp(lightThemeData, darkThemeData, 0.9);
    } else {
      begin = darkThemeData;
      end = ThemeData.lerp(darkThemeData, lightThemeData, 0.9);
    }
    return ThemeDataTween(
      begin: begin,
      end: end,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tween = _getTween();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      page = _controller.page ?? 0;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _tween ??= _getTween();
    return Theme(
      data: _tween!.transform(page),
      child: Builder(
        builder: (context) => Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: PageView.builder(
                  controller: _controller,
                  itemCount: 2,
                  onPageChanged: (i) => index = i,
                  itemBuilder: (BuildContext context, int index) => const SizedBox.expand()),
            ),
            Align(
              alignment: const Alignment(0, -0.2),
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: _TextField(index == 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
