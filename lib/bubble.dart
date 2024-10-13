import 'package:atonement/image.dart';
import 'package:boxy/flex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:framework/widgets.dart';

import 'messaging.dart';

class PostBubble extends StatelessWidget {
  const PostBubble({super.key, required this.data});

  final Post data;

  @override
  Widget build(BuildContext context) {
    final time = data.time;

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

    return _Bubble(time: time, sender: data.send, avatar: data.avatar, child: body);
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
        Dominant.expanded(
          flex: 4,
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: body),
        ),
        if (imageUrl != null)
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: WrapImage(imageUrl: imageUrl),
            ),
          )
      ],
    );

    return _Bubble(time: time, sender: sender, avatar: avatar, child: body);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.child, required this.time, required this.sender, required this.avatar});

  final Widget child;
  final DateTime time;
  final String sender;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}';
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
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
            child: Row(
              children: [
                NNAvatar(imageUrl: avatar),
                const SizedBox(width: 8),
                Text(sender),
                const Spacer(),
                Text(formattedDate, style: TextStyle(color: CupertinoColors.systemGrey.resolveFrom(context))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child
        ],
      ),
    );
  }
}
