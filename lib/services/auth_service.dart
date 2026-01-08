import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      if (e.code == 'user-not-found') return 'Kullanıcı bulunamadı.';
      if (e.code == 'wrong-password') return 'Şifre hatalı.';
      if (e.code == 'invalid-email') return 'Geçersiz e-posta formatı.';
      return 'Giriş hatası: ${e.message}';
    } catch (e) {
      return 'Beklenmedik bir hata oluştu.';
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
        // Modeli kullanarak veriyi hazırlayalım
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,
        );
        // User modelindeki toMap() fonksiyonunu kullanmak daha temiz olur ama
        // burada hızlıca map olarak yazıyoruz.
        await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'email': newUser.email,
          'name': newUser.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Bu e-posta zaten kullanımda.';
      if (e.code == 'weak-password') return 'Şifre çok zayıf.';
      return 'Kayıt hatası: ${e.message}';
    } catch (e) {
      return 'Beklenmedik bir hata oluştu.';
    }
  }

  // --- YENİ EKLENEN: Şifre Sıfırlama ---
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Hata yok, başarılı
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Bu e-posta adresiyle kayıtlı kullanıcı yok.';
      if (e.code == 'invalid-email') return 'Geçersiz e-posta adresi.';
      return e.message;
    } catch (e) {
      return 'Bir hata oluştu.';
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}