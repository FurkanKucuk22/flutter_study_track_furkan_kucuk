import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // pubspec.yaml'a eklemeyi unutma
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';

import '../../widgets/custom_button.dart';

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
  final List<String> _subjects = ["Matematik", "Fizik", "Kimya", "Yazılım", "İngilizce", "Tarih"];

  void _startTimer() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  void _stopAndSave() async {
    _timer?.cancel();
    setState(() => _isActive = false);

    if (_seconds > 5) { // 5 saniyeden kısa çalışmaları kaydetme
      final db = Provider.of<DBService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      await db.saveSession(auth.currentUser!.uid, _selectedSubject, _seconds);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çalışma Kaydedildi!")));
    }

    setState(() => _seconds = 0);
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
    return Scaffold(
      appBar: AppBar(title: const Text("Zamanlayıcı")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _selectedSubject,
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 20)))).toList(),
              onChanged: _isActive ? null : (val) => setState(() => _selectedSubject = val!),
            ),
            const SizedBox(height: 40),
            Text(_formatTime(_seconds), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isActive ? null : _startTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  child: const Text("BAŞLAT", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isActive ? _stopAndSave : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  child: const Text("BİTİR", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}