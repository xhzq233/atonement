import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log.dart';

class ImagePageRoute extends PageRoute<void> {
  ImagePageRoute({required this.imageUrl});

  final String imageUrl;

  @override
  Color? get barrierColor => const Color(0x18000000);

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: _ImageDetail(imageUrl: imageUrl));
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

class _ImageDetail extends StatelessWidget {
  const _ImageDetail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('图片'),
        // Download
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_down_to_line),
          onPressed: () async {
            try {
              await launchUrl(Uri.parse(imageUrl));
              fireLogI('Downloaded $imageUrl');
            } catch (e) {
              fireLogE(e.toString());
              SmartDialog.showToast(e.toString());
            }
          },
        ),
      ),
      child: Align(
        child: Hero(tag: imageUrl, child: Image.network(imageUrl)),
      ),
    );
  }
}
