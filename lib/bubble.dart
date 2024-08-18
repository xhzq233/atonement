import 'package:atonement/image.dart';
import 'package:boxy/flex.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'messaging.dart';

class PostBubble extends StatelessWidget {
  const PostBubble({super.key, required this.data});

  final Post data;

  @override
  Widget build(BuildContext context) {
    final time = data.time;

    final formattedDate = '${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}';

    final Widget avatarWidget = SizedBox(
      width: 32,
      height: 32,
      child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(data.avatar)),
    );

    Widget body = SelectableText(data.content, style: Theme.of(context).textTheme.titleSmall!.apply(fontSizeDelta: 2));
    if (data.imageUrl != null) {
      body = BoxyRow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Dominant(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: body)),
          WrapImage(imageUrl: data.imageUrl!)
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
                Text(data.send),
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

  final Todo data;

  @override
  Widget build(BuildContext context) {
    final String sender = data.send;
    final String content = data.content;
    final time = data.time;
    final String avatar = data.avatar;
    final bool complete = data.complete;
    final String? imageUrl = data.imageUrl;

    final formattedDate = '${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}';

    Widget avatarWidget;
    avatarWidget = CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatar));

    avatarWidget = SizedBox(width: 32, height: 32, child: avatarWidget);

    Widget body = SelectableText(content, style: Theme.of(context).textTheme.titleSmall!.apply(fontSizeDelta: 2));
    body = BoxyRow(
      children: [
        CupertinoCheckbox(
            value: complete,
            onChanged: !complete
                ? (bool? val) {
                    completeTodo(data);
                  }
                : null),
        Dominant(
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: body),
        ),
        if (imageUrl != null) const Spacer(),
        if (imageUrl != null) WrapImage(imageUrl: imageUrl)
      ],
    );

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
