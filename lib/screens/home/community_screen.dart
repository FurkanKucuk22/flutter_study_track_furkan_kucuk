import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _messageCtrl = TextEditingController();
  File? _selectedImage;
  bool _isSending = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30); // Kalite optimize edildi

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _sharePost() async {
    if (_messageCtrl.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    await db.addPost(auth.currentUser!.uid, _messageCtrl.text.trim(), _selectedImage);

    if (mounted) {
      setState(() {
        _messageCtrl.clear();
        _selectedImage = null;
        _isSending = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sil"),
        content: const Text("Bu gönderiyi silmek istiyor musun?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gönderi silindi.")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
                }
              },
              child: const Text("Sil", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // Tarihi "X dakika önce" formatına çeviren yardımcı fonksiyon
  String _formatTimeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 7) {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} gün önce';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} dk önce';
    } else {
      return 'Az önce';
    }
  }

  void _showCommentsDialog(Post post) {
    final commentCtrl = TextEditingController();
    final db = Provider.of<DBService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
              ),
              Text("Yorumlar (${post.comments.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: post.comments.isEmpty
                    ? const Center(child: Text("İlk yorumu sen yaz! 💬", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    var comment = post.comments[index];
                    DateTime date = (comment['createdAt'] as Timestamp).toDate();
                    String userId = comment['userId'];

                    return StreamBuilder<UserModel>(
                        stream: db.getUserData(userId),
                        builder: (context, userSnapshot) {
                          String displayName = comment['userName'];
                          ImageProvider? userPhotoProvider;

                          if (userSnapshot.hasData) {
                            displayName = userSnapshot.data!.name.isNotEmpty ? userSnapshot.data!.name : "İsimsiz";
                            if (userSnapshot.data!.photoUrl != null && userSnapshot.data!.photoUrl!.isNotEmpty) {
                              userPhotoProvider = _getImageProvider(userSnapshot.data!.photoUrl);
                            }
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.indigo[50],
                              backgroundImage: userPhotoProvider,
                              child: userPhotoProvider == null
                                  ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo))
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Text(_formatTimeAgo(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            subtitle: Text(comment['message'], style: const TextStyle(color: Colors.black87)),
                          );
                        }
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                            hintText: "Yorum ekle...",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: () {
                          if (commentCtrl.text.isNotEmpty) {
                            final auth = Provider.of<AuthService>(context, listen: false);
                            db.addComment(post.id, auth.currentUser!.uid, commentCtrl.text);
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
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
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUserId = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Topluluk")),
      backgroundColor: Colors.grey[100], // Arka planı hafif gri yaptık, kartlar öne çıksın
      body: Column(
        children: [
          // --- GÖNDERİ PAYLAŞMA ALANI ---
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))]
            ),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    ),
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.white54, radius: 15, child: Icon(Icons.close, size: 18, color: Colors.black)),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_a_photo, color: _selectedImage != null ? Colors.green : Colors.grey[600]),
                      onPressed: _pickImage,
                      tooltip: "Fotoğraf Ekle",
                    ),
                    Expanded(
                        child: TextField(
                            controller: _messageCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: "Bugün hedefin ne? Motive et! 🚀",
                              border: InputBorder.none,
                            )
                        )
                    ),
                    IconButton(
                        icon: _isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.indigo),
                        onPressed: _isSending ? null : _sharePost
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- GÖNDERİ LİSTESİ ---
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: db.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Henüz paylaşım yok. İlk sen yaz! 👇", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data![index];
                    bool isMyPost = post.userId == currentUserId;
                    bool isLiked = post.likedBy.contains(currentUserId);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. ÜST KISIM (Kullanıcı Bilgileri)
                            StreamBuilder<UserModel>(
                                stream: db.getUserData(post.userId),
                                builder: (context, userSnapshot) {
                                  String displayName = post.userName;
                                  ImageProvider? userPhotoProvider;

                                  if (userSnapshot.hasData) {
                                    displayName = userSnapshot.data!.name.isNotEmpty ? userSnapshot.data!.name : "İsimsiz";
                                    if (userSnapshot.data!.photoUrl != null && userSnapshot.data!.photoUrl!.isNotEmpty) {
                                      userPhotoProvider = _getImageProvider(userSnapshot.data!.photoUrl);
                                    }
                                  }

                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo[50],
                                        backgroundImage: userPhotoProvider,
                                        child: userPhotoProvider == null
                                            ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Text(_formatTimeAgo(post.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                      if (isMyPost)
                                        InkWell(
                                          onTap: () => _confirmDelete(post.id),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(Icons.more_horiz, color: Colors.grey),
                                          ),
                                        )
                                    ],
                                  );
                                }
                            ),

                            // 2. ORTA KISIM (Mesaj)
                            if (post.message.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(post.message, style: const TextStyle(fontSize: 15, height: 1.4)),
                              ),

                            // 3. FOTOĞRAF ALANI
                            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image(
                                    image: _getImageProvider(post.imageUrl),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 250,
                                    // Resim yüklenirken gösterilecek loading
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 250,
                                        color: Colors.grey[200],
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                                    ),
                                  ),
                                ),
                              ),

                            const Divider(height: 20),

                            // 4. ALT KISIM (Etkileşim)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () => db.toggleLike(post.id, currentUserId!),
                                  child: Row(
                                    children: [
                                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey[600], size: 22),
                                      const SizedBox(width: 6),
                                      Text("${post.likes}", style: TextStyle(color: isLiked ? Colors.red : Colors.grey[600], fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showCommentsDialog(post),
                                  child: Row(
                                    children: [
                                      Icon(Icons.comment_outlined, color: Colors.grey[600], size: 22),
                                      const SizedBox(width: 6),
                                      Text("${post.comments.length}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}