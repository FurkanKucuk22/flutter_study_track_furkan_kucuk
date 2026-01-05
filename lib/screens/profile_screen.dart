import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();

  bool _isLoading = false;
  // Bu değişken sayesinde veriyi sadece BİR KERE çekeceğiz
  bool _isDataInitialized = false;

  // Fotoğraf Seçme ve Yükleme İşlemi
  Future<void> _pickAndUploadImage(String userId, DBService dbService) async {
    final ImagePicker picker = ImagePicker();
    // imageQuality: 20 -> Resim boyutunu küçültüyoruz ki veritabanı şişmesin
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

  // Bilgileri Kaydetme İşlemi
  void _saveProfile(String userId, DBService dbService) async {
    // Boş alan kontrolü
    if (_nameController.text.isEmpty && _goalController.text.isEmpty) return;

    setState(() => _isLoading = true);

    // Hedefi güncelle
    if (_goalController.text.isNotEmpty) {
      await dbService.setGoal(userId, int.parse(_goalController.text));
    }

    // Profil bilgilerini güncelle (Sadece isim)
    await dbService.updateUserProfile(
        userId,
        _nameController.text
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler Kaydedildi!")));
    FocusScope.of(context).unfocus(); // Klavyeyi kapat
  }

  // Base64 metnini resme çeviren yardımcı fonksiyon
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

          // --- KLAVYE SORUNU ÇÖZÜMÜ ---
          // Verileri sadece sayfa ilk yüklendiğinde (henüz doldurulmadıysa) controller'a atıyoruz.
          // Böylece siz yazı yazarken Flutter tekrar tekrar veritabanındaki eski ismi kutucuğa yazmaya çalışmıyor.
          if (!_isDataInitialized) {
            _nameController.text = userData.name;
            // Eğer veritabanında hedef bilgisi varsa onu da burada doldurabilirsiniz
            _isDataInitialized = true; // Artık veriler yüklendi, bir daha dokunma.
          }
          // ----------------------------

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // --- PROFİL FOTOĞRAFI ALANI ---
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
                // İsim veritabanından geliyorsa göster
                Text(
                    userData.name.isNotEmpty ? userData.name : "İsimsiz Kullanıcı",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
                Text(userData.email, style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 30),
                const Divider(),
                const Text("Bilgileri Düzenle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),

                // Form Alanları

                // 1. Ad Soyad Alanı
                TextField(
                  // ARTIK BURADA "..text =" ATAMASI YOK!
                  // Sadece controller'ı veriyoruz. Veriyi yukarıdaki if bloğunda doldurduk.
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(labelText: "Ad Soyad", prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 16),

                // 2. Hedef Alanı
                TextField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Günlük Hedef (dk)", prefixIcon: Icon(Icons.timer)),
                ),

                const SizedBox(height: 24),
                CustomButton(text: "KAYDET", onPressed: () => _saveProfile(user.uid, dbService), isLoading: _isLoading),

                const SizedBox(height: 40),
                // Çıkış Butonu
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