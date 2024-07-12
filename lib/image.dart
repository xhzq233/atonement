import 'package:atonement/log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class PickedImage extends StatefulWidget {
  const PickedImage({super.key, this.child});

  final Widget? child;

  static PickedImageState? of(BuildContext context) {
    return context.findAncestorStateOfType<PickedImageState>();
  }

  @override
  State<PickedImage> createState() => PickedImageState();
}

class PickedImageState extends State<PickedImage> {
  String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

class PickImageWidget extends StatefulWidget {
  const PickImageWidget({super.key});

  @override
  State<PickImageWidget> createState() => _PickImageWidgetState();
}

enum PickImageState {
  none,
  loading,
  done,
  error,
}

class _PickImageWidgetState extends State<PickImageWidget> {
  PickImageState loading = PickImageState.none;

  void _setState(PickImageState state, {String? url}) {
    if (state == loading) {
      return;
    }
    setState(() {
      loading = state;
      PickedImage.of(context)?.imageUrl = url;
    });
  }

  Future<void> _pickImage() async {
    _setState(PickImageState.loading);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'gif'],
      );
      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          final filename = result.files.single.name;
          final ref = FirebaseStorage.instance.ref('images/$filename');

          await ref.putData(bytes!, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();
          _setState(PickImageState.done, url: url);
        } else {
          throw "Platform not supported";
        }
      } else {
        throw "User canceled the picker";
      }
    } catch (e) {
      _setState(PickImageState.error);
      fireLogE(e.toString());
      SmartDialog.showToast(e.toString());
    }
  }

  Widget _getImage() {
    final String? url = PickedImage.of(context)?.imageUrl;
    if (url == null || url.isEmpty) {
      return const Icon(CupertinoIcons.exclamationmark_circle);
    }
    return Image.network(url);
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;

    widget = switch (loading) {
      PickImageState.loading => const CupertinoActivityIndicator(),
      PickImageState.done => ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100, minHeight: 100),
          child: _getImage(),
        ),
      PickImageState.error => const Icon(CupertinoIcons.refresh_thick),
      PickImageState.none => const Icon(CupertinoIcons.photo_on_rectangle),
    };

    VoidCallback? function;
    if (loading == PickImageState.error || loading == PickImageState.none) {
      function = _pickImage;
    }

    widget = CupertinoButton(onPressed: function, child: widget);

    return widget;
  }
}
