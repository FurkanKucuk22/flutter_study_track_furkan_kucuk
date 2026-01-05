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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _sharePost() async {
    if (_messageCtrl.text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    await db.addPost(auth.currentUser!.uid, _messageCtrl.text, _selectedImage);

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
        title: const Text("Mesajı Sil"),
        content: const Text("Bu gönderiyi silmek istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silindi")));
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

  // --- GÜNCELLEME: Yorumlar Penceresinde Profil Resmi Gösterimi ---
  void _showCommentsDialog(Post post) {
    final commentCtrl = TextEditingController();
    final db = Provider.of<DBService>(context, listen: false); // DB servisine erişim

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: 500,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: post.comments.isEmpty
                      ? const Center(child: Text("Henüz yorum yok. İlk yorumu sen yaz!"))
                      : ListView.builder(
                    itemCount: post.comments.length,
                    itemBuilder: (context, index) {
                      var comment = post.comments[index];
                      DateTime date = (comment['createdAt'] as Timestamp).toDate();
                      String userId = comment['userId']; // Yorumu yapanın ID'si

                      // StreamBuilder ile anlık kullanıcı verisini çekiyoruz
                      return StreamBuilder<UserModel>(
                          stream: db.getUserData(userId),
                          builder: (context, userSnapshot) {
                            String displayName = comment['userName'];
                            ImageProvider? userPhotoProvider;

                            if (userSnapshot.hasData) {
                              // Güncel isim
                              displayName = userSnapshot.data!.name.isNotEmpty
                                  ? userSnapshot.data!.name
                                  : "İsimsiz";
                              // Güncel fotoğraf
                              if (userSnapshot.data!.photoUrl != null && userSnapshot.data!.photoUrl!.isNotEmpty) {
                                userPhotoProvider = _getImageProvider(userSnapshot.data!.photoUrl);
                              }
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.indigo[100],
                                backgroundImage: userPhotoProvider, // Fotoğrafı buraya koyuyoruz
                                child: userPhotoProvider == null
                                    ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo))
                                    : null,
                              ),
                              title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(comment['message']),
                              trailing: Text(DateFormat('HH:mm').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            );
                          }
                      );
                    },
                  ),
                ),
                // Yorum Yazma Alanı
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                            hintText: "Yorum yaz...",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.indigo),
                      onPressed: () {
                        if (commentCtrl.text.isNotEmpty) {
                          final auth = Provider.of<AuthService>(context, listen: false);
                          db.addComment(post.id, auth.currentUser!.uid, commentCtrl.text);
                          Navigator.pop(ctx);
                        }
                      },
                    )
                  ],
                )
              ],
            ),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _selectedImage = null),
                        )
                      ],
                    ),
                  ),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_a_photo, color: _selectedImage != null ? Colors.green : Colors.grey),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                        child: TextField(
                            controller: _messageCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              hintText: "Bir şeyler paylaş...",
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

          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: db.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Henüz paylaşım yok. İlk sen yaz! 👇"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data![index];
                    bool isMyPost = post.userId == currentUserId;
                    bool isLiked = post.likedBy.contains(currentUserId);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBuilder<UserModel>(
                                stream: db.getUserData(post.userId),
                                builder: (context, userSnapshot) {
                                  String displayName = post.userName;
                                  ImageProvider? userPhotoProvider;

                                  if (userSnapshot.hasData) {
                                    displayName = userSnapshot.data!.name.isNotEmpty
                                        ? userSnapshot.data!.name
                                        : "İsimsiz";
                                    if (userSnapshot.data!.photoUrl != null && userSnapshot.data!.photoUrl!.isNotEmpty) {
                                      userPhotoProvider = _getImageProvider(userSnapshot.data!.photoUrl);
                                    }
                                  }

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    onLongPress: isMyPost ? () => _confirmDelete(post.id) : null,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo[100],
                                      backgroundImage: userPhotoProvider,
                                      child: userPhotoProvider == null
                                          ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))
                                          : null,
                                    ),
                                    title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    trailing: Text(DateFormat('dd/MM HH:mm').format(post.createdAt),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  );
                                }
                            ),

                            if (post.message.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Text(post.message, style: const TextStyle(fontSize: 15)),
                              ),

                            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image(
                                    image: _getImageProvider(post.imageUrl),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                  ),
                                ),
                              ),

                            const Divider(),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextButton.icon(
                                  onPressed: () => db.toggleLike(post.id, currentUserId!),
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.grey,
                                  ),
                                  label: Text("${post.likes} Beğeni", style: TextStyle(color: isLiked ? Colors.red : Colors.grey)),
                                ),

                                TextButton.icon(
                                  onPressed: () => _showCommentsDialog(post),
                                  icon: const Icon(Icons.comment_outlined, color: Colors.indigo),
                                  label: Text("${post.comments.length} Yorum", style: const TextStyle(color: Colors.indigo)),
                                ),

                                if (isMyPost)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _confirmDelete(post.id),
                                  )
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