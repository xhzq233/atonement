import 'package:atonement/image.dart';
import 'package:atonement/messaging.dart';
import 'package:boxy/flex.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PostBubble extends StatelessWidget {
  const PostBubble({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String sender = data['send'];
    final String content = data['content'];
    final datetime = DateTime.fromMillisecondsSinceEpoch(data['time']);
    final String? avatar = data['avatar'];
    final int read = data['read'];
    final String? imageUrl = data['imageUrl'];

    final formattedDate = '${datetime.year}-${datetime.month}-${datetime.day} ${datetime.hour}:${datetime.minute}';

    Widget avatarWidget;
    if (avatar != null) {
      avatarWidget = CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatar));
    } else {
      avatarWidget = const Icon(CupertinoIcons.person);
    }

    avatarWidget = SizedBox(width: 32, height: 32, child: avatarWidget);

    Widget body = SelectableText(content, style: Theme.of(context).textTheme.titleSmall!.apply(fontSizeDelta: 2));
    if (imageUrl != null) {
      body = BoxyRow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Dominant(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: body)),
          WrapImage(imageUrl: imageUrl)
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
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800),
            child: Row(
              children: [
                avatarWidget,
                const SizedBox(width: 8),
                Text(sender),
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

class TodoBubble extends StatelessWidget {
  const TodoBubble({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String sender = data['send'];
    final String content = data['content'];
    final datetime = DateTime.fromMillisecondsSinceEpoch(data['time']);
    final String? avatar = data['avatar'];
    final int complete = data['complete'];
    final String? imageUrl = data['imageUrl'];

    final formattedDate = '${datetime.year}-${datetime.month}-${datetime.day} ${datetime.hour}:${datetime.minute}';

    Widget avatarWidget;
    if (avatar != null) {
      avatarWidget = CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatar));
    } else {
      avatarWidget = const Icon(CupertinoIcons.person);
    }

    avatarWidget = SizedBox(width: 32, height: 32, child: avatarWidget);

    Widget body = SelectableText(content, style: Theme.of(context).textTheme.titleSmall!.apply(fontSizeDelta: 2));
    if (imageUrl != null) {
      body = BoxyRow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Dominant(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: body)),
          WrapImage(imageUrl: imageUrl)
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
      child: Row(
        children: [
          Checkbox(
              value: complete == 1,
              onChanged: (bool? val) {
                pushMessage(content, completeOrRead: val == true, todo: true);
              }),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800),
                child: Row(
                  children: [
                    avatarWidget,
                    const SizedBox(width: 8),
                    Text(sender),
                    const Spacer(),
                    Text(formattedDate, style: TextStyle(color: CupertinoColors.systemGrey.resolveFrom(context))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              body
            ],
          ),
        ],
      ),
    );
  }
}
