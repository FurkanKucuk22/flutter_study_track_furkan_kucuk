import 'package:cloud_firestore/cloud_firestore.dart';

class StudySession {
  final String id;
  final String userId;
  final String subject;
  final int duration; // Saniye cinsinden
  final DateTime date;

  StudySession({
    required this.id,
    required this.userId,
    required this.subject,
    required this.duration,
    required this.date,
  });

  factory StudySession.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return StudySession(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      duration: data['duration'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}