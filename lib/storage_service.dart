import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> choisirEtUploaderImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (photo == null) return null;
    return uploaderFichier(File(photo.path));
  }

  Future<String> uploaderFichier(File file) async {
    final String fileName = "menu_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = _storage.ref().child("menu_images").child(fileName);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
