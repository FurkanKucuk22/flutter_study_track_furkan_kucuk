import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isActive = false;
  String _selectedSubject = "Matematik";
  final List<String> _subjects = ["Matematik", "Fizik", "Kimya", "Yazılım", "İngilizce", "Tarih", "Edebiyat", "Diğer"];

  // Hedefleri tutacak değişkenler
  Map<String, int> _subjectGoals = {};
  int _currentTargetSeconds = 0; // Seçili dersin saniye cinsinden hedefi

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında hedefleri çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoals();
    });
  }

  Future<void> _loadGoals() async {
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;

    if (userId != null) {
      // Stream'den ilk veriyi alıp kapatıyoruz (tek seferlik okuma)
      try {
        var goalsMap = await db.getUserGoals(userId).first;
        if (mounted) {
          setState(() {
            if (goalsMap['subjectGoals'] != null) {
              _subjectGoals = Map<String, int>.from(goalsMap['subjectGoals']);
              _updateCurrentTarget(); // İlk açılışta hedefi güncelle
            }
          });
        }
      } catch (e) {
        print("Hedef yükleme hatası: $e");
      }
    }
  }

  // Seçili derse göre hedefi günceller
  void _updateCurrentTarget() {
    if (_subjectGoals.containsKey(_selectedSubject)) {
      setState(() {
        _currentTargetSeconds = _subjectGoals[_selectedSubject]! * 60; // Dakikayı saniyeye çevir
      });
    } else {
      setState(() {
        _currentTargetSeconds = 0; // Hedef yok
      });
    }
  }

  // --- ZAMANLAYICI FONKSİYONLARI ---

  void _startTimer() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });

      // HEDEF KONTROLÜ (OTOMATİK DURDURMA)
      if (_currentTargetSeconds > 0 && _seconds >= _currentTargetSeconds) {
        _stopAndSave(autoStop: true); // Hedef tamamlandı, kaydet
      }
    });
  }

  void _stopAndSave({bool autoStop = false}) async {
    _timer?.cancel();
    setState(() => _isActive = false);

    // 10 saniyeden kısa çalışmaları kaydetme (yanlışlık önlemi)
    if (_seconds > 10) {
      final db = Provider.of<DBService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);

      await db.saveSession(auth.currentUser!.uid, _selectedSubject, _seconds);

      if (mounted) {
        String message = "Oturum Kaydedildi! 🎉";
        if (autoStop) {
          message = "Tebrikler! $_selectedSubject hedefini tamamladın! 🎯";
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: autoStop ? Colors.green : null,
          duration: const Duration(seconds: 4),
        ));

        // İsteğe bağlı: Kayıttan sonra süreyi sıfırla
        setState(() => _seconds = 0);
      }
    } else if (_seconds > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Süre çok kısa, kaydedilmedi.")));
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isActive = false;
    });
  }

  // --- MANUEL EKLEME FONKSİYONU ---
  void _showManualEntryDialog() {
    final durationCtrl = TextEditingController();
    String manualSubject = _selectedSubject;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Manuel Çalışma Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Zamanlayıcıyı açmayı unuttun mu? Sorun değil, süreyi kendin gir."),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: manualSubject,
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => manualSubject = val!,
              decoration: const InputDecoration(labelText: "Ders", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Süre (Dakika)",
                  border: OutlineInputBorder(),
                  hintText: "Örn: 45"
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (durationCtrl.text.isEmpty) return;

              int minutes = int.tryParse(durationCtrl.text) ?? 0;
              if (minutes > 0) {
                final db = Provider.of<DBService>(context, listen: false);
                final auth = Provider.of<AuthService>(context, listen: false);

                // Dakikayı saniyeye çevirip kaydediyoruz
                await db.saveSession(auth.currentUser!.uid, manualSubject, minutes * 60);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manuel kayıt eklendi!")));
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text("KAYDET"),
          )
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hedef bilgisini ekranda göstermek için metin hazırla
    String targetText = _currentTargetSeconds > 0
        ? "Hedef: ${(_currentTargetSeconds / 60).toStringAsFixed(0)} dk"
        : "Hedef yok";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zamanlayıcı"),
        actions: [
          // Manuel Ekleme Butonu
          TextButton.icon(
            onPressed: _showManualEntryDialog,
            icon: const Icon(Icons.edit_note),
            label: const Text("Manuel Ekle"),
            style: TextButton.styleFrom(foregroundColor: Colors.indigo),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Hangi derse çalışıyorsun?", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 10),

            // Ders Seçimi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSubject,
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 18)))).toList(),
                  onChanged: _isActive ? null : (val) {
                    setState(() {
                      _selectedSubject = val!;
                      _updateCurrentTarget(); // Ders değişince yeni hedefe bak
                    });
                  },
                ),
              ),
            ),

            // Hedef Bilgisi (Varsa göster)
            if (_currentTargetSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    "$targetText (Otomatik duracak)",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)
                ),
              ),

            const Spacer(),

            // Sayaç Göstergesi
            Text(
                _formatTime(_seconds),
                style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontFeatures: [FontFeature.tabularFigures()]
                )
            ),
            Text(
                _isActive ? "Odaklan... 🎯" : "Hazır mısın?",
                style: TextStyle(color: _isActive ? Colors.green : Colors.grey, fontSize: 16)
            ),

            const Spacer(),

            // Kontrol Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BAŞLAT
                if (!_isActive && _seconds == 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      child: const Text("BAŞLAT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                if (_isActive || (_seconds > 0 && !_isActive)) ...[
                  // BİTİR & KAYDET
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _stopAndSave(autoStop: false),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      child: const Text("BİTİR & KAYDET", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // SIFIRLA / DURAKLAT
                  if (_isActive)
                    InkWell(
                      onTap: () {
                        _timer?.cancel();
                        setState(() => _isActive = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.pause, color: Colors.orange, size: 30),
                      ),
                    )
                  else
                    InkWell(
                      onTap: _resetTimer,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.refresh, color: Colors.red, size: 30),
                      ),
                    ),
                ]
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}