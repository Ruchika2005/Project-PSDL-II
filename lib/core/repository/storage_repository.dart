import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final storageRepositoryProvider = Provider((ref) => StorageRepository(FirebaseStorage.instance));

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  Future<String> uploadFile({
    required String path,
    required String id,
    required File file,
  }) async {
    try {
      String ext = 'jpg';
      if (file.path.contains('.')) {
        ext = file.path.split('.').last.toLowerCase();
      }
      
      // Use child() chains for better reliability in some environments
      final ref = _storage.ref().child(path).child('$id.$ext');
      
      final metadata = SettableMetadata(
        contentType: 'image/$ext',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': file.path.split('/').last,
        },
      );

      final bytes = await file.readAsBytes();
      final uploadTask = ref.putData(bytes, metadata);
      
      // Monitor progress for debugging
      uploadTask.snapshotEvents.listen((event) {
        debugPrint('Upload progress: ${event.bytesTransferred}/${event.totalBytes}');
      }, onError: (e) {
        debugPrint('Snapshot Event Error: $e');
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      debugPrint('Upload successful. URL: $url');
      return url;
    } catch (e) {
      debugPrint('CRITICAL UPLOAD ERROR: $e');
      if (e is FirebaseException) {
        debugPrint('Firebase Error Code: ${e.code}');
        debugPrint('Firebase Error Message: ${e.message}');
        if (e.code == 'object-not-found') {
          debugPrint('HINT: This often means "Storage" is not enabled in your Firebase Console, or the Bucket name is wrong.');
        }
      }
      throw e.toString();
    }
  }
}
