// storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return null;

      final ref = _storage.ref().child('avatars/$userId.jpg');
      final uploadTask = await ref.putFile(imageFile);

      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      print('Erreur upload avatar: $e');
      return null;
    }
  }
}