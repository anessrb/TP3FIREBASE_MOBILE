import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> signUp(String username, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: "$username@quizapp.com",
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> signIn(String username, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: "$username@quizapp.com",
        password: password,
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}