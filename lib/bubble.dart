import 'package:atonement/main.dart';
import 'package:atonement/platform/download_file.dart';
import 'package:boxy/flex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String sender = data['send'];
    final String content = data['content'];
    final datetime = DateTime.fromMillisecondsSinceEpoch(data['time']);
    final String? avatar = data['avatar'];
    final String? imageUrl = data['imageUrl'];
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

    Widget body = SelectableText(content, style: Theme.of(context).textTheme.titleMedium!);
    if (imageUrl != null) {
      body = BoxyRow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Dominant(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: body)),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => navigator.pushNamed('/image', arguments: imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(tag: imageUrl, child: Image.network(imageUrl, fit: BoxFit.contain)),
            ),
          ),
        ],
      );
    }

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
            style: Theme.of(context).textTheme.titleLarge!,
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
          body
        ],
      ),
    );
  }
}

class ImageDetail extends StatelessWidget {
  const ImageDetail({super.key, required this.imageUrl});

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
          onPressed: () => download(url: imageUrl),
        ),
      ),
      child: Align(
        child: Hero(tag: imageUrl, child: Image.network(imageUrl)),
      ),
    );
  }
}
