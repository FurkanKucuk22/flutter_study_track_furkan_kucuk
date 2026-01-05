import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;
  final String? imageUrl;
  final int likes;
  final List<String> likedBy; // Kimlerin beğendiğini tutar
  final List<Map<String, dynamic>> comments; // Yorumları tutar

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.imageUrl,
    this.likes = 0,
    this.likedBy = const [],
    this.comments = const [],
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
    );
  }
}