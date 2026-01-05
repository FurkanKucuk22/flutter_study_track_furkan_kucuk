import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/db_service.dart';
import '../../services/auth_service.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _dailyCtrl = TextEditingController();
  final _weeklyCtrl = TextEditingController();

  final _subjectGoalCtrl = TextEditingController();
  String _selectedSubject = "Matematik";
  final List<String> _subjects = ["Matematik", "Fizik", "Kimya", "Yazılım", "İngilizce", "Tarih", "Edebiyat", "Diğer"];
  Map<String, int> _subjectGoals = {};

  bool _isLoading = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _loadCurrentGoals();
      _isInit = true;
    }
  }

  Future<void> _loadCurrentGoals() async {
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;

    if (userId != null) {
      var goalsMap = await db.getUserGoals(userId).first;
      if (mounted) {
        setState(() {
          _dailyCtrl.text = goalsMap['daily'].toString();
          _weeklyCtrl.text = goalsMap['weekly'].toString();

          if (goalsMap['subjectGoals'] != null) {
            _subjectGoals = Map<String, int>.from(goalsMap['subjectGoals']);
          }
        });
      }
    }
  }

  void _addSubjectGoal() {
    if (_subjectGoalCtrl.text.isEmpty) return;
    int minutes = int.tryParse(_subjectGoalCtrl.text) ?? 0;

    if (minutes > 0) {
      setState(() {
        _subjectGoals[_selectedSubject] = minutes;
        _subjectGoalCtrl.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _removeSubjectGoal(String subject) {
    setState(() {
      _subjectGoals.remove(subject);
    });
  }

  Future<void> _saveGoals() async {
    if (_dailyCtrl.text.isEmpty || _weeklyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen genel hedefleri doldurun")));
      return;
    }

    setState(() => _isLoading = true);
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    await db.saveGoals(
      auth.currentUser!.uid,
      int.parse(_dailyCtrl.text),
      int.parse(_weeklyCtrl.text),
      _subjectGoals,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tüm Hedefler Kaydedildi! 🎯")));

      // EĞER BU EKRAN BAŞKA YERDEN AÇILDIYSA KAPAT, YOKSA KAL (NAVIGASYON İÇİN)
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekranda geri butonu (AppBar) olmasın, çünkü artık ana menüde
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hedef Belirle"),
        automaticallyImplyLeading: false, // Geri butonunu gizler
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Genel Hedefler 🎯",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 16),

            // Günlük Hedef
            TextField(
              controller: _dailyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Günlük Toplam Hedef (dk)",
                prefixIcon: const Icon(Icons.today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Haftalık Hedef
            TextField(
              controller: _weeklyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Haftalık Toplam Hedef (dk)",
                prefixIcon: const Icon(Icons.calendar_month),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              "Ders Bazlı Hedefler 📚",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const Text("Hangi derse ne kadar çalışmak istersin?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // Ders Seçimi ve Dakika Girişi
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) => setState(() => _selectedSubject = val!),
                    decoration: const InputDecoration(labelText: "Ders", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _subjectGoalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Dakika", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addSubjectGoal,
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                )
              ],
            ),

            const SizedBox(height: 20),

            // Eklenen Ders Hedefleri Listesi
            if (_subjectGoals.isNotEmpty)
              const Text("Eklenen Hedefler:", style: TextStyle(fontWeight: FontWeight.bold)),

            Wrap(
              spacing: 8.0,
              children: _subjectGoals.entries.map((entry) {
                return Chip(
                  label: Text("${entry.key}: ${entry.value} dk"),
                  backgroundColor: Colors.indigo.shade50,
                  deleteIcon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                  onDeleted: () => _removeSubjectGoal(entry.key),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("TÜM HEDEFLERİ KAYDET", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}