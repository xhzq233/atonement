import 'package:atonement/image.dart';
import 'package:atonement/log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:framework/cupertino.dart';

import 'platform/upload_image.dart';

class PickedImage extends StatefulWidget {
  const PickedImage({super.key, this.child});

  final Widget? child;

  static PickedImageState read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_PickedImageState>()!.notifier!;
  }

  static PickedImageState watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PickedImageState>()!.notifier!;
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
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return _PickedImageState(notifier: this, child: widget.child ?? const SizedBox());
  }
}

class _PickedImageState extends InheritedNotifier<PickedImageState> {
  const _PickedImageState({required super.child, super.notifier});
}

class PickImageWidget extends StatelessWidget {
  const PickImageWidget({super.key});

  Future<void> _pickImage(context) async {
    PickedImage.read(context).setPickImageState(PickImageState.loading);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        final url = await uploadImage(file: result.files.single);
        fireLogI('Uploaded image: $url');
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
      child: WrapImage(imageUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;

    final loading = PickedImage.watch(context).loading;
    final primary = Theme.of(context).colorScheme.primary;

    widget = switch (loading) {
      PickImageState.loading => CupertinoActivityIndicator(color: primary),
      PickImageState.done => _getImage(context),
      PickImageState.none || PickImageState.error => Icon(CupertinoIcons.photo_on_rectangle, color: primary),
    };

    VoidCallback? function;
    if (loading == PickImageState.error || loading == PickImageState.none) {
      function = () => _pickImage(context);
    }

    widget = CustomCupertinoButton(
      onTap: function,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget,
      ),
    );

    return widget;
  }
}

enum PickImageState {
  none,
  loading,
  done,
  error,
}
