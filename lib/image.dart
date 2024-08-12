import 'package:flutter/cupertino.dart';
import 'package:framework/cupertino.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:framework/route.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log.dart';
import 'main.dart';

class ImagePageRoute extends PhotoPageRoute {
  ImagePageRoute({required String imageUrl})
      : super(draggableChild: Hero(tag: imageUrl, child: Image.network(imageUrl)));
}

class WrapImage extends StatelessWidget {
  const WrapImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => navigator.push(ImagePageRoute(imageUrl: imageUrl)),
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
              onPressed: () => navigator.push(ImagePageRoute(imageUrl: imageUrl)),
            ),
          ],
          child: Hero(tag: imageUrl, child: Image.network(imageUrl, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
