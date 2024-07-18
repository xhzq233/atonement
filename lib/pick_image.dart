import 'package:atonement/log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'platform/upload_image.dart';

class PickedImage extends StatefulWidget {
  const PickedImage({super.key, this.child});

  final Widget? child;

  static PickedImageState read(BuildContext context) {
    final PickedImageState? state = context.findAncestorStateOfType<PickedImageState>();
    if (state == null) {
      assert(false, 'PickedImage.read(context) called with a context that does not contain a PickedImage.');
    }
    return state!;
  }

  static PickedImageState watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PickedImageState>()!.state;
  }

  @override
  State<PickedImage> createState() => PickedImageState();
}

class PickedImageState extends State<PickedImage> with ChangeNotifier {
  String? imageUrl;
  PickImageState loading = PickImageState.none;

  void setPickImageState(PickImageState state, {String? url}) {
    if (state == loading) {
      return;
    }
    loading = state;
    imageUrl = url;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _PickedImageState(imageUrl, loading, state: this, child: widget.child ?? const SizedBox());
  }
}

class _PickedImageState extends InheritedWidget {
  const _PickedImageState(this.imageUrl, this.loading, {required super.child, required this.state});

  final PickedImageState state;
  final String? imageUrl;
  final PickImageState loading;

  @override
  bool updateShouldNotify(covariant _PickedImageState oldWidget) {
    return oldWidget.imageUrl != imageUrl || oldWidget.loading != loading;
  }
}

class PickImageWidget extends StatelessWidget {
  const PickImageWidget({super.key});

  Future<void> _pickImage(context) async {
    PickedImage.read(context).setPickImageState(PickImageState.loading);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'gif'],
      );
      if (result != null && result.files.isNotEmpty) {
        final url = await uploadImage(file: result.files.single);
        PickedImage.read(context).setPickImageState(PickImageState.done, url: url);
      } else {
        // throw "User canceled the picker";
        PickedImage.read(context).setPickImageState(PickImageState.error);
      }
    } catch (e) {
      PickedImage.read(context).setPickImageState(PickImageState.error);
      fireLogE(e.toString());
      SmartDialog.showToast(e.toString());
    }
  }

  Widget _getImage(BuildContext context) {
    final String? url = PickedImage.read(context).imageUrl;
    if (url == null || url.isEmpty) {
      return const Icon(CupertinoIcons.exclamationmark_circle);
    }
    return SizedBox(
      width: 100,
      height: 100,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey.resolveFrom(context), width: 1),
          image: DecorationImage(image: ResizeImage(NetworkImage(url), width: 100, height: 100), fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;

    final loading = PickedImage.watch(context).loading;

    widget = switch (loading) {
      PickImageState.loading => const CupertinoActivityIndicator(),
      PickImageState.done => _getImage(context),
      PickImageState.none || PickImageState.error => const Icon(CupertinoIcons.photo_on_rectangle),
    };

    VoidCallback? function;
    if (loading == PickImageState.error || loading == PickImageState.none) {
      function = () => _pickImage(context);
    }

    widget = CupertinoButton(onPressed: function, child: widget);

    return widget;
  }
}

enum PickImageState {
  none,
  loading,
  done,
  error,
}
