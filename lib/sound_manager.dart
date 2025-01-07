import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _victoryUrl;
  String? _defeatUrl;

  Future<void> initializeSounds() async {
    try {
      // Obtenir les URLs depuis Firebase Storage
      final storage = FirebaseStorage.instance;
      _victoryUrl = await storage.ref('sounds/victory.mp3').getDownloadURL();
      _defeatUrl = await storage.ref('sounds/defeat.mp3').getDownloadURL();
    } catch (e) {
      print('Erreur lors du chargement des sons: $e');
    }
  }

  Future<void> playVictorySound() async {
    if (_victoryUrl != null) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(_victoryUrl!));
      } catch (e) {
        print('Erreur lors de la lecture du son de victoire: $e');
      }
    }
  }

  Future<void> playDefeatSound() async {
    if (_defeatUrl != null) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(_defeatUrl!));
      } catch (e) {
        print('Erreur lors de la lecture du son de défaite: $e');
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}