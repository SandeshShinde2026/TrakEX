import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Upload a profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference storageRef = _storage.ref().child('profile_images/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload an expense image
  Future<String> uploadExpenseImage(String userId, File imageFile) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference storageRef = _storage.ref().child('expense_images/$userId/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload multiple expense images
  Future<List<String>> uploadExpenseImages(String userId, List<File> imageFiles) async {
    try {
      final List<String> downloadUrls = [];
      
      for (var imageFile in imageFiles) {
        final String url = await uploadExpenseImage(userId, imageFile);
        downloadUrls.add(url);
      }
      
      return downloadUrls;
    } catch (e) {
      rethrow;
    }
  }

  // Delete an image by URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Delete multiple images by URL
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (var imageUrl in imageUrls) {
        await deleteImage(imageUrl);
      }
    } catch (e) {
      rethrow;
    }
  }
}
