import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'dart:io';


class DBService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- KULLANICI İŞLEMLERİ ---

  Stream<UserModel> getUserData(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return UserModel(uid: userId, email: '', name: 'Bilinmiyor');
    });
  }

  Future<void> updateUserProfile(String userId, String name) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
    }, SetOptions(merge: true));
  }

  // --- FOTOĞRAF YÜKLEME ---
  Future<void> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      await _db.collection('users').doc(userId).update({'photoUrl': base64Image});
    } catch (e) {
      print("Fotoğraf kaydetme hatası: $e");
    }
  }

  // --- ÇALIŞMA OTURUMLARI ---
  Future<void> saveSession(String userId, String subject, int duration) async {
    await _db.collection('study_sessions').add({
      'userId': userId,
      'subject': subject,
      'duration': duration,
      'date': FieldValue.serverTimestamp(),
      'dateStr': DateTime.now().toString().substring(0, 10),
    });
  }

  Stream<List<StudySession>> getTodaySessions(String userId) {
    String today = DateTime.now().toString().substring(0, 10);
    return _db.collection('study_sessions')
        .where('userId', isEqualTo: userId)
        .where('dateStr', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => StudySession.fromFirestore(doc)).toList());
  }

  Stream<List<StudySession>> getWeeklySessions(String userId) {
    return _db.collection('study_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      var sessions = snapshot.docs.map((doc) => StudySession.fromFirestore(doc)).toList();

      DateTime now = DateTime.now();
      int daysToSubtract = now.weekday - 1;
      DateTime monday = now.subtract(Duration(days: daysToSubtract));
      DateTime startOfWeek = DateTime(monday.year, monday.month, monday.day);

      var currentWeekSessions = sessions.where((s) {
        return s.date.isAfter(startOfWeek) || s.date.isAtSameMomentAs(startOfWeek);
      }).toList();

      return currentWeekSessions;
    });
  }

  // --- HEDEFLER ---
  Future<void> setGoal(String userId, int minutes) async {
    await _db.collection('goals').doc(userId).set({
      'dailyGoal': minutes,
    }, SetOptions(merge: true));
  }

  Stream<int> getUserGoal(String userId) {
    return _db.collection('goals').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data()!.containsKey('dailyGoal')) {
        return doc.data()!['dailyGoal'] as int;
      }
      return 60;
    });
  }

  // --- TOPLULUK ---
  Future<void> addPost(String userId, String message, File? imageFile) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      String currentUserName = "Anonim";
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        currentUserName = data['name'] ?? "Anonim";
      }

      String? base64Image;
      if (imageFile != null) {
        List<int> imageBytes = await imageFile.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      await _db.collection('posts').add({
        'userId': userId,
        'userName': currentUserName,
        'message': message,
        'imageUrl': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0, // Başlangıçta 0 beğeni
        'likedBy': [], // Beğenenler boş
        'comments': [], // Yorumlar boş
      });
    } catch (e) {
      print("Post atma hatası: $e");
    }
  }

  // Beğeni Yap / Geri Al
  Future<void> toggleLike(String postId, String userId) async {
    DocumentReference postRef = _db.collection('posts').doc(postId);

    // İşlem tutarlılığı için transaction kullanıyoruz
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
      int likes = data['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        // Zaten beğenmiş -> Beğeniyi kaldır
        likedBy.remove(userId);
        likes -= 1;
      } else {
        // Beğenmemiş -> Beğeni ekle
        likedBy.add(userId);
        likes += 1;
      }

      transaction.update(postRef, {'likes': likes, 'likedBy': likedBy});
    });
  }

  // Yorum Ekle
  Future<void> addComment(String postId, String userId, String message) async {
    // Yorum yapanın ismini bul
    DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
    String userName = "Anonim";
    if (userDoc.exists && userDoc.data() != null) {
      userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? "Anonim";
    }

    Map<String, dynamic> commentData = {
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': Timestamp.now(),
    };

    await _db.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([commentData])
    });
  }

  Stream<List<Post>> getPosts() {
    return _db.collection('posts')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      var posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }
}