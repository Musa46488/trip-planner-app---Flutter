import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getImageUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL();
      print('Image URL: $url');
      return url;
    } catch (e) {
      print('Error fetching image URL: $e');
      return 'https://via.placeholder.com/400x200';
    }
  }
}