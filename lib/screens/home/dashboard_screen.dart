
import 'package:flutter/material.dart';
import 'package:flutter_study_track_furkan_kucuk/screens/home/stats_screen.dart';
import 'package:flutter_study_track_furkan_kucuk/screens/home/timer_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../models/session_model.dart';
import 'community_screen.dart';
import 'goal_setting_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DBService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return const Center(child: Text("Hata: Oturum Yok"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("StudyTrack"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Hoş Geldin! 👋",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const Text(
              "Bugünkü hedeflerine odaklan.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // --- DÜZELTME BURADA: Veri tipi Map<String, dynamic> yapıldı ---
            StreamBuilder<Map<String, dynamic>>(
              stream: dbService.getUserGoals(userId),
              builder: (context, goalSnapshot) {
                int dailyGoal = 60;
                if (goalSnapshot.hasData) {
                  dailyGoal = goalSnapshot.data!['daily'] ?? 60;
                }

                return StreamBuilder<List<StudySession>>(
                  stream: dbService.getTodaySessions(userId),
                  builder: (context, sessionSnapshot) {
                    if (!sessionSnapshot.hasData) {
                      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                    }

                    int totalSeconds = sessionSnapshot.data!.fold(0, (sum, item) => sum + item.duration);
                    int totalMinutes = totalSeconds ~/ 60;
                    double progress = (dailyGoal > 0) ? (totalMinutes / dailyGoal).clamp(0.0, 1.0) : 0.0;
                    int percent = (progress * 100).toInt();

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.indigo, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bugünkü Çalışman", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("$totalMinutes", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6, left: 4),
                                child: Text("/ $dailyGoal dk", style: const TextStyle(fontSize: 16, color: Colors.white70)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("%$percent Tamamlandı", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            // -------------------------------------------------------------

            const SizedBox(height: 30),

            const Text("Hızlı Erişim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShortcutBtn(context, Icons.timer, "Başla", Colors.orange, const TimerScreen()),
                _buildShortcutBtn(context, Icons.flag, "Hedef", Colors.purple, const GoalSettingScreen()),
                _buildShortcutBtn(context, Icons.bar_chart, "Analiz", Colors.blue, const StatsScreen()),
                _buildShortcutBtn(context, Icons.people, "Topluluk", Colors.teal, const CommunityScreen()),
              ],
            ),

            const SizedBox(height: 30),

            const Text("Son Oturumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            StreamBuilder<List<StudySession>>(
              stream: dbService.getTodaySessions(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                    child: const Text("Bugün henüz kayıt yok. Çalışmaya başla! 🚀", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  );
                }

                var sessions = snapshot.data!.take(3).toList();

                return Column(
                  children: sessions.map((session) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.book, color: Colors.indigo),
                        ),
                        title: Text(session.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${(session.duration / 60).toStringAsFixed(1)} dakika"),
                        trailing: Text(DateFormat('HH:mm').format(session.date), style: const TextStyle(color: Colors.grey)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutBtn(BuildContext context, IconData icon, String label, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}