class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String? department; // EKLENDİ
  final String? grade;      // EKLENDİ

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.department,
    this.grade,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      department: data['department'],
      grade: data['grade'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'department': department,
      'grade': grade,
    };
  }
}