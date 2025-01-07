import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserAvatarManager extends StatelessWidget {
  final String? currentAvatarUrl;
  final Function(String) onAvatarUpdated;

  const UserAvatarManager({
    Key? key,
    this.currentAvatarUrl,
    required this.onAvatarUpdated,
  }) : super(key: key);

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      // Sélectionner l'image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Uploader vers Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Mettre à jour l'URL de l'avatar
      onAvatarUpdated(downloadUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar mis à jour avec succès!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialogue de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: currentAvatarUrl != null
              ? NetworkImage(currentAvatarUrl!) as ImageProvider
              : const AssetImage('assets/default_avatar.png'),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => _pickAndUploadImage(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _pickAndUploadImage(context),
          child: const Text('Changer l\'avatar'),
        ),
      ],
    );
  }
}