import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadImage({required PlatformFile file}) async {
  final filename = file.name;
  final ref = FirebaseStorage.instance.ref('images/$filename');

  await ref.putFile(File(file.path!));

  return await ref.getDownloadURL();
}
