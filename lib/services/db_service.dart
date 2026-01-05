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

  // GÜNCELLEME: Bölüm ve Sınıf parametreleri geri eklendi
  Future<void> updateUserProfile(String userId, String name, String department, String grade) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
      'department': department,
      'grade': grade,
    }, SetOptions(merge: true));
  }

  // --- FOTOĞRAF YÜKLEME (Base64) ---
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
  Future<void> saveGoals(String userId, int dailyGoal, int weeklyGoal, Map<String, int> subjectGoals) async {
    await _db.collection('goals').doc(userId).set({
      'dailyGoal': dailyGoal,
      'weeklyGoal': weeklyGoal,
      'subjectGoals': subjectGoals,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> getUserGoals(String userId) {
    return _db.collection('goals').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        var data = doc.data()!;
        return {
          'daily': data['dailyGoal'] ?? 60,
          'weekly': data['weeklyGoal'] ?? 300,
          'subjectGoals': Map<String, int>.from(data['subjectGoals'] ?? {}),
        };
      }
      return {
        'daily': 60,
        'weekly': 300,
        'subjectGoals': <String, int>{}
      };
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
        'likes': 0,
        'likedBy': [],
        'comments': [],
      });
    } catch (e) {
      print("Post atma hatası: $e");
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    DocumentReference postRef = _db.collection('posts').doc(postId);
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
      int likes = data['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likes -= 1;
      } else {
        likedBy.add(userId);
        likes += 1;
      }
      transaction.update(postRef, {'likes': likes, 'likedBy': likedBy});
    });
  }

  Future<void> addComment(String postId, String userId, String message) async {
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