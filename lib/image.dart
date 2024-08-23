import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:framework/cupertino.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:framework/route.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log.dart';
import 'main.dart';

class ImagePageRoute extends PhotoPageRoute {
  ImagePageRoute({required String imageUrl, String? tag})
      : super(draggableChild: Hero(tag: tag ?? imageUrl, child: NNImage(imageUrl)));
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
              onPressed: () async {
                navigator.pop();
                await Future.delayed(const Duration(milliseconds: 300));
                navigator.push(ImagePageRoute(imageUrl: imageUrl));
              },
            ),
          ],
          child: Hero(tag: imageUrl, child: NNImage(imageUrl, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

final CacheManager imageCacheManager = CacheManager(Config(
  'image_cache',
  maxNrOfCacheObjects: 500,
  stalePeriod: const Duration(days: 999),
));

class NNImage extends CachedNetworkImage {
  static Widget defaultErrorWidgetBuilder(BuildContext context, String url, dynamic error) =>
      const Icon(CupertinoIcons.exclamationmark_circle);

  static Widget defaultPlaceHolderWidgetBuilder(BuildContext context, String url) => const CupertinoActivityIndicator();

  NNImage(
    String imageUrl, {
    super.key,
    super.width,
    super.height,
    super.fit,
    super.placeholder = defaultPlaceHolderWidgetBuilder,
    super.errorWidget = defaultErrorWidgetBuilder,
    super.fadeInDuration,
    super.fadeOutDuration,
    super.placeholderFadeInDuration,
    super.cacheKey,
    super.imageBuilder,
  }) : super(cacheManager: imageCacheManager, imageUrl: imageUrl);
}

class NNImageProvider extends CachedNetworkImageProvider {
  NNImageProvider(
    super.url, {
    super.maxWidth,
    super.maxHeight,
    super.cacheKey,
    super.errorListener,
  }) : super(cacheManager: imageCacheManager);
}

class NNAvatar extends StatelessWidget {
  const NNAvatar({super.key, required this.imageUrl, this.size = 32});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scaledSize = MediaQuery.textScalerOf(context).scale(size);
    final tag = imageUrl + hashCode.toString();
    return CustomCupertinoButton(
      onTap: () => navigator.push(ImagePageRoute(imageUrl: imageUrl, tag: tag)),
      child: SizedBox(
        width: scaledSize,
        height: scaledSize,
        child: FittedBox(
          child: Hero(
            tag: tag,
            child: ClipOval(child: NNImage(imageUrl, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }
}
