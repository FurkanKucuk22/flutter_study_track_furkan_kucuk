import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durumunu dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Şu anki kullanıcı
  User? get currentUser => _auth.currentUser;

  // Giriş Yap
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Kayıt Ol
  Future<String?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // Firestore'a kullanıcı kaydet
      if (result.user != null) {
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,
        );
        await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
