import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mime_type/mime_type.dart';
import 'package:flutter/foundation.dart';

Future<String?> uploadData(String path, Uint8List? data) async {
  if (data == null || data.isEmpty) {
    debugPrint('Error: Cannot upload null or empty data');
    return null;
  }

  try {
    // Use only the public directory which has permissive rules
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = path.split('/').last;
    final publicPath = 'public/${timestamp}_$fileName';

    debugPrint('======= STORAGE UPLOAD DEBUG =======');
    debugPrint('Attempting upload to public path: $publicPath');
    debugPrint('Firebase bucket: ${FirebaseStorage.instance.bucket}');
    final publicRef = FirebaseStorage.instance.ref().child(publicPath);

    try {
      final metadata = SettableMetadata(
        contentType: mime(path),
        customMetadata: {
          'originalName': fileName,
          'timestamp': timestamp.toString(),
        },
      );

      debugPrint('Starting upload with file size: ${data.length} bytes');
      final result = await publicRef.putData(data, metadata);

      if (result.state == TaskState.success) {
        final url = await result.ref.getDownloadURL();
        debugPrint('Upload successful!');
        debugPrint('Generated URL: $url');
        debugPrint('URL length: ${url.length}');
        debugPrint('====================================');
        return url;
      } else {
        debugPrint('Upload failed with state: ${result.state}');
        debugPrint('====================================');
        return null;
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      debugPrint('====================================');
      return null;
    }
  } catch (e) {
    debugPrint('Unexpected error in uploadData: $e');
    debugPrint('====================================');
    return null;
  }
}
