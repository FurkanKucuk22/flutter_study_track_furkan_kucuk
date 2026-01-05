import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../models/session_model.dart';
import '../../widgets/custom_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DBService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Ana Sayfa")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hoş Geldin! 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Hedef Kartı
            StreamBuilder<int>(
              stream: dbService.getUserGoal(userId),
              builder: (context, goalSnapshot) {
                int goal = goalSnapshot.data ?? 60;

                return StreamBuilder<List<StudySession>>(
                  stream: dbService.getTodaySessions(userId),
                  builder: (context, sessionSnapshot) {
                    if (!sessionSnapshot.hasData) return const LinearProgressIndicator();

                    int totalSeconds = sessionSnapshot.data!.fold(0, (sum, item) => sum + item.duration);
                    int totalMinutes = totalSeconds ~/ 60;
                    double progress = (totalMinutes / goal).clamp(0.0, 1.0);

                    return Card(
                      color: Colors.indigo,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text("Bugünkü İlerlemen", style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 10),
                            Text("$totalMinutes / $goal dk", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, color: Colors.greenAccent),
                            const SizedBox(height: 10),
                            Text("%${(progress * 100).toInt()} Tamamlandı", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text("Son Çalışmalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<List<StudySession>>(
                stream: dbService.getTodaySessions(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Bugün henüz çalışmadın."));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var session = snapshot.data![index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.book)),
                        title: Text(session.subject),
                        subtitle: Text("${(session.duration / 60).toStringAsFixed(1)} dk"),
                        trailing: Text(DateFormat('HH:mm').format(session.date)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}