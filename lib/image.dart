import 'package:flutter/cupertino.dart';
import 'package:framework/cupertino.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:framework/route.dart';
import 'package:framework/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log.dart';

class WrapImage extends StatelessWidget {
  const WrapImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final child = NNImage(imageUrl, fit: BoxFit.contain);
    final tag = hashCode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => rootNavigator.push(PhotoPageRoute(draggableChild: child, heroTag: tag)),
        child: CustomCupertinoContextMenu(
          previewMaxScale: 2.5,
          actions: [
            CustomCupertinoContextMenuAction(
              trailingIcon: const Icon(CupertinoIcons.arrow_down_to_line),
              child: const Text('下载'),
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
            CustomCupertinoContextMenuAction(
              trailingIcon: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill),
              child: const Text('详情'),
              onPressed: () async {
                rootNavigator.pop();
                await Future.delayed(const Duration(milliseconds: 300));
                rootNavigator.push(PhotoPageRoute(draggableChild: child, heroTag: tag));
              },
            ),
          ],
          child: Hero(tag: imageUrl, child: child),
        ),
      ),
    );
  }
}