import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
    return _uploadToAnyBucket(
      folder: folder,
      fileName: fileName,
      bytes: bytes,
    );
  }

  static Future<String> _uploadFile(
    XFile file, {
    required String folder,
    required String defaultExtension,
  }) async {
    final extension = _fileExtension(file.name, fallback: defaultExtension);
    final random = Random().nextInt(1 << 32);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$random.$extension';
    final localPath = file.path;
    if (localPath.isNotEmpty) {
      return _uploadToAnyBucket(
        folder: folder,
        fileName: fileName,
        localFile: File(localPath),
      );
    } else {
      return _uploadToAnyBucket(
        folder: folder,
        fileName: fileName,
        bytes: await file.readAsBytes(),
      );
    }
  }

  static Future<String> _uploadToAnyBucket({
    required String folder,
    required String fileName,
    Uint8List? bytes,
    File? localFile,
  }) async {
    if (bytes == null && localFile == null) {
      throw ArgumentError('Either bytes or localFile must be provided.');
    }

    final sanitizedFolder = _sanitizeFolder(folder);
    FirebaseException? lastError;

    for (final storage in _storageCandidates()) {
      final ref = storage.ref().child('$sanitizedFolder/$fileName');
      try {
        final TaskSnapshot snapshot = localFile != null
            ? await ref.putFile(localFile)
            : await ref.putData(bytes!);
        return await _getDownloadUrlWithRetry(snapshot.ref, attempts: 6);
      } on FirebaseException catch (error) {
        lastError = error;
        if (error.code == 'object-not-found' || error.code == 'bucket-not-found') {
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw StateError('Upload failed for all Firebase Storage buckets.');
  }

  static List<FirebaseStorage> _storageCandidates() {
    final base = FirebaseStorage.instance;
    final options = base.app.options;
    final buckets = <String>{};

    final configured = options.storageBucket ?? '';
    if (configured.isNotEmpty) {
      buckets.add(configured.startsWith('gs://') ? configured : 'gs://$configured');
    }

    final projectId = options.projectId;
    if (projectId.isNotEmpty) {
      buckets.add('gs://$projectId.appspot.com');
      buckets.add('gs://$projectId.firebasestorage.app');
    }

    return buckets.map((bucket) => FirebaseStorage.instanceFor(bucket: bucket)).toList();
  }

  static String _sanitizeFolder(String folder) {
    return folder
        .trim()
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');
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
