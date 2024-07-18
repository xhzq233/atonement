import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadImage({required PlatformFile file}) async {
  final bytes = file.bytes;
  final filename = file.name;
  final ref = FirebaseStorage.instance.ref('images/$filename');

  await ref.putData(bytes!, SettableMetadata(contentType: 'image/jpeg'));
  return await ref.getDownloadURL();
}
