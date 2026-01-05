import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController(); // EKLENDİ
  final _gradeController = TextEditingController();      // EKLENDİ

  bool _isLoading = false;

  Future<void> _pickAndUploadImage(String userId, DBService dbService) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);

    if (image != null) {
      setState(() => _isLoading = true);

      File file = File(image.path);
      await dbService.uploadProfilePhoto(userId, file);

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil fotoğrafı güncellendi!")));
    }
  }

  void _saveProfile(String userId, DBService dbService) async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    await dbService.updateUserProfile(
        userId,
        _nameController.text,
        _departmentController.text, // Bölüm kaydediliyor
        _gradeController.text       // Sınıf kaydediliyor
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler Kaydedildi!")));
    FocusScope.of(context).unfocus();
  }

  ImageProvider _getImageProvider(String? photoData) {
    if (photoData == null || photoData.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }
    try {
      if (photoData.startsWith('http')) {
        return NetworkImage(photoData);
      }
      return MemoryImage(base64Decode(photoData));
    } catch (e) {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DBService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("Hata: Oturum kapalı"));

    return Scaffold(
      appBar: AppBar(title: const Text("Profilim")),
      body: StreamBuilder<UserModel>(
        stream: dbService.getUserData(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          UserModel userData = snapshot.data!;
          bool hasPhoto = userData.photoUrl != null && userData.photoUrl!.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      _isLoading
                          ? const CircleAvatar(radius: 60, child: CircularProgressIndicator())
                          : CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.indigo[100],
                        backgroundImage: hasPhoto ? _getImageProvider(userData.photoUrl) : null,
                        child: !hasPhoto
                            ? const Icon(Icons.person, size: 60, color: Colors.indigo)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            onPressed: () => _pickAndUploadImage(user.uid, dbService),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                    userData.name.isNotEmpty ? userData.name : "İsimsiz Kullanıcı",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
                Text(userData.email, style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 30),
                const Divider(),
                const Text("Bilgileri Düzenle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),

                // Ad Soyad
                TextField(
                  controller: _nameController..text = (_nameController.text.isEmpty ? userData.name : _nameController.text),
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(labelText: "Ad Soyad", prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),

                // Bölüm (EKLENDİ)
                TextField(
                  controller: _departmentController..text = (_departmentController.text.isEmpty ? (userData.department ?? '') : _departmentController.text),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: "Bölüm", prefixIcon: Icon(Icons.school)),
                ),
                const SizedBox(height: 16),

                // Sınıf (EKLENDİ)
                TextField(
                  controller: _gradeController..text = (_gradeController.text.isEmpty ? (userData.grade ?? '') : _gradeController.text),
                  decoration: const InputDecoration(labelText: "Sınıf", prefixIcon: Icon(Icons.class_outlined)),
                ),

                const SizedBox(height: 24),
                CustomButton(text: "KAYDET", onPressed: () => _saveProfile(user.uid, dbService), isLoading: _isLoading),

                const SizedBox(height: 40),

                // Oturumu Kapat (logout) - Gereksinim
                TextButton.icon(
                  onPressed: () => authService.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("ÇIKIŞ YAP", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}