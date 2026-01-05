import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../models/session_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    if (auth.currentUser == null) return const Center(child: Text("Giriş yapılmamış"));

    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler")),
      body: StreamBuilder<List<StudySession>>(
        stream: db.getWeeklySessions(auth.currentUser!.uid),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final sessions = snapshot.data ?? [];

          // --- GÜNCELLEME: Verileri ve Maksimum Değeri Hazırla ---
          List<double> weeklyMinutes = List.filled(7, 0.0);
          double maxMinutes = 0; // En yüksek çalışma süresini takip et

          for (var session in sessions) {
            int dayIndex = session.date.weekday - 1;

            if (dayIndex >= 0 && dayIndex < 7) {
              weeklyMinutes[dayIndex] += session.duration / 60.0;
              // Max değeri güncelle
              if (weeklyMinutes[dayIndex] > maxMinutes) {
                maxMinutes = weeklyMinutes[dayIndex];
              }
            }
          }

          // --- ÖNEMLİ: Grafik Ölçeği Ayarı ---
          // Eğer o haftaki en yüksek çalışma 1 saatten (60 dk) azsa, grafiğin tavanını 60 yap.
          // Böylece 1 dakikalık çalışma tüm grafiği kaplamaz, dipte küçük görünür.
          // Eğer 60'tan büyükse, max değerin %20 fazlasını tavan yap (grafik sıkışmasın).
          double chartMaxY = maxMinutes < 60 ? 60 : maxMinutes * 1.2;

          final List<String> dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Haftalık Çalışma Grafiği", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,

                      // --- TAVAN YÜKSEKLİĞİNİ BURADA BELİRLİYORUZ ---
                      maxY: chartMaxY,
                      // ----------------------------------------------

                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.orange,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toStringAsFixed(2)} dk',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),

                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < dayLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(dayLabels[index], style: const TextStyle(fontSize: 12)),
                                );
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
                              color: Colors.amber, // Renk Amber olarak sabitlendi
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            )
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}