import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaUploadService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndUploadImage({
    required String folder,
  }) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return null;
    }
    return _uploadFile(file, folder: folder, defaultExtension: 'jpg');
  }

  static Future<String?> pickAndUploadVideo({
    required String folder,
  }) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) {
      return null;
    }
    return _uploadFile(file, folder: folder, defaultExtension: 'mp4');
  }

  static Future<String?> pickAndUploadDocument({
    required String folder,
  }) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (picked == null) {
      return null;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    final extension = _fileExtension(picked.name, fallback: 'pdf');
    final random = Random().nextInt(1 << 32);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$random.$extension';
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

    final snapshot = await ref.putData(bytes);
    return _getDownloadUrlWithRetry(snapshot.ref);
  }

  static Future<String> _uploadFile(
    XFile file, {
    required String folder,
    required String defaultExtension,
  }) async {
    final extension = _fileExtension(file.name, fallback: defaultExtension);
    final random = Random().nextInt(1 << 32);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$random.$extension';
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

    final localPath = file.path;
    dynamic snapshot;
    if (localPath.isNotEmpty) {
      snapshot = await ref.putFile(File(localPath));
    } else {
      snapshot = await ref.putData(await file.readAsBytes());
    }
    return _getDownloadUrlWithRetry(snapshot.ref);
  }

  static Future<String> _getDownloadUrlWithRetry(
    Reference reference, {
    int attempts = 3,
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        return await reference.getDownloadURL();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found' || attempt == attempts - 1) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw StateError('Unable to resolve download URL after upload.');
  }

  static String _fileExtension(String fileName, {required String fallback}) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) {
      return fallback;
    }
    return fileName.substring(dot + 1).toLowerCase();
  }
}
