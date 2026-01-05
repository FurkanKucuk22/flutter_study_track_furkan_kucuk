import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../models/session_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;

    if (userId == null) return const Center(child: Text("Giriş yapılmamış"));

    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GÜNLÜK HEDEF TAMAMLAMA YÜZDESİ ---
            _buildDailyGoalSection(db, userId),

            const SizedBox(height: 30),

            // --- 2. HAFTALIK GRAFİK (SON 7 GÜN) ---
            const Text("Son 7 Gün", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 250, // Grafik yüksekliği sabitlendi
              child: _buildWeeklyChart(db, userId),
            ),

            const SizedBox(height: 30),

            // --- 3. DERS BAZLI ÇALIŞMA ÖZETİ ---
            const Text("Ders Performansı (Toplam)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSubjectSummary(db, userId),
          ],
        ),
      ),
    );
  }

  // Günlük Hedef Kartı Widget'ı
  Widget _buildDailyGoalSection(DBService db, String userId) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: db.getUserGoals(userId),
      builder: (context, goalSnapshot) {
        int dailyGoal = 60;
        if (goalSnapshot.hasData) dailyGoal = goalSnapshot.data!['daily'] ?? 60;

        return StreamBuilder<List<StudySession>>(
          stream: db.getTodaySessions(userId),
          builder: (context, sessionSnapshot) {
            int totalMinutes = 0;
            if (sessionSnapshot.hasData) {
              totalMinutes = sessionSnapshot.data!.fold(0, (sum, item) => sum + item.duration) ~/ 60;
            }
            double progress = (dailyGoal > 0) ? (totalMinutes / dailyGoal).clamp(0.0, 1.0) : 0.0;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Günlük Hedef", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text("%${(progress * 100).toInt()}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("$totalMinutes / $dailyGoal dk tamamlandı", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Haftalık Grafik Widget'ı
  Widget _buildWeeklyChart(DBService db, String userId) {
    return StreamBuilder<List<StudySession>>(
      stream: db.getWeeklySessions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Veri hatası"));

        final sessions = snapshot.data ?? [];
        List<double> weeklyMinutes = List.filled(7, 0.0);
        double maxMinutes = 0;

        for (var session in sessions) {
          int dayIndex = session.date.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyMinutes[dayIndex] += session.duration / 60.0;
            if (weeklyMinutes[dayIndex] > maxMinutes) maxMinutes = weeklyMinutes[dayIndex];
          }
        }

        // Tavan yüksekliği ayarı (En az 60 dk, yoksa max değerin %20 fazlası)
        double chartMaxY = maxMinutes < 60 ? 60 : maxMinutes * 1.2;
        final List<String> dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

        return BarChart(
          BarChartData(
            maxY: chartMaxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.orange,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toStringAsFixed(1)} dk',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                      return Padding(padding: const EdgeInsets.only(top: 8), child: Text(dayLabels[value.toInt()], style: const TextStyle(fontSize: 12)));
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: List.generate(7, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: weeklyMinutes[index],
                    color: Colors.amber, // İstenen renk
                    width: 12, // İstenen incelik
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  )
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Ders Bazlı Özet Listesi Widget'ı
  Widget _buildSubjectSummary(DBService db, String userId) {
    return StreamBuilder<List<StudySession>>(
      stream: db.getWeeklySessions(userId), // Haftalık verileri kullanıyoruz
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final sessions = snapshot.data!;
        Map<String, int> subjectTotals = {};

        // Derslere göre süreleri topla
        for (var session in sessions) {
          subjectTotals[session.subject] = (subjectTotals[session.subject] ?? 0) + session.duration;
        }

        if (subjectTotals.isEmpty) return const Text("Henüz veri yok.", style: TextStyle(color: Colors.grey));

        return Column(
          children: subjectTotals.entries.map((entry) {
            int totalMinutes = entry.value ~/ 60;
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Text(entry.key.isNotEmpty ? entry.key[0] : "?", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$totalMinutes dk", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}