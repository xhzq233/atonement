/// atonement - main_body
/// Created by xhz on 8/18/24

part of 'main.dart';

class _TextField extends StatelessWidget {
  const _TextField(this.todo);

  final bool todo;

  void _send(BuildContext context, TextEditingController controller) {
    pushMessage(
      controller.text,
      imageUrl: PickedImage.read(context).imageUrl,
      todo: todo,
    );
    controller.clear();
    PickedImage.read(context).setPickImageState(PickImageState.none);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.findAncestorStateOfType<_ContentState>()!.tfController;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, minHeight: 200),
          child: CupertinoTextField(
            placeholder: todo ? "Wishes" : "Posts",
            controller: controller,
            clearButtonMode: OverlayVisibilityMode.editing,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            autocorrect: false,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.fromBorderSide(
                BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.0,
                ),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PickImageWidget(),
            Obx(
              () {
                final enable = hasAccount && !pushingMessage.value;
                return Builder(builder: (context) {
                  final Color color;
                  final VoidCallback? voidCallback;
                  if (enable) {
                    color = Theme.of(context).colorScheme.primary;
                    voidCallback = () => _send(context, controller);
                  } else {
                    color = Theme.of(context).colorScheme.secondary;
                    voidCallback = null;
                  }
                  return CustomCupertinoButton(
                    onTap: voidCallback,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        CupertinoIcons.paperplane,
                        color: color,
                      ),
                    ),
                  );
                });
              },
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
      navigationBar: const CupertinoNavigationBar(middle: Text('Posts')),
      child: _StorageList(
        source: postSource,
        itemBuilder: (BuildContext context, Post data) => PostBubble(data: data),
      ),
    );
  }
}

class _Todos extends StatelessWidget {
  const _Todos();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Wishes')),
      child: _StorageList(
        source: todoSource,
        itemBuilder: (BuildContext context, data) => TodoBubble(data: data),
      ),
    );
  }
}

class _StorageList<T> extends StatelessWidget {
  const _StorageList({required this.itemBuilder, required this.source});

  final Widget Function(BuildContext context, T data) itemBuilder;

  final Stream<QuerySnapshot<T>> source;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: source,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<T>> snapshot) {
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

        final QuerySnapshot<T> data = snapshot.data!;

        return ListView.builder(
          itemCount: data.docs.length,
          itemBuilder: (BuildContext context, int index) => itemBuilder(context, data.docs[index].data()),
        );
      },
    );
  }
}
