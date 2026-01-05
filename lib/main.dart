import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/stats_screen.dart';
import 'screens/home/timer_screen.dart';
import 'screens/home/community_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat (google-services.json dosyasını otomatik okur)
  await Firebase.initializeApp();

  // Tarih formatlaması için Türkçe yerel ayarını yükle
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DBService>(create: (_) => DBService()),
      ],
      // Klavye kapatma özelliği: Ekranın boş bir yerine tıklayınca klavyeyi indirir
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
          title: 'StudyTrack',
          debugShowCheckedModeBanner: false,

          // --- TÜRKÇE DİL DESTEĞİ ---
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'), // Türkçe
            Locale('en', 'US'), // İngilizce (Yedek)
          ],
          // --------------------------

          theme: ThemeData(
            primarySwatch: Colors.indigo,
            primaryColor: Colors.indigo,
            useMaterial3: true,
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          // Uygulama açılışında yönlendirme yapan wrapper
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

// Kullanıcının giriş yapıp yapmadığını kontrol eden ara katman
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Bağlantı aktifse kontrol et
        if (snapshot.connectionState == ConnectionState.active) {
          // Kullanıcı varsa Ana Sayfa'ya, yoksa Giriş Ekranı'na git
          return snapshot.data == null ? const LoginScreen() : const MainLayout();
        }
        // Bağlantı bekleniyorsa yükleniyor göster
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// Alt navigasyon çubuğunu (BottomNavigationBar) yöneten ana iskelet
class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TimerScreen(),
    const StatsScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Zamanlayıcı'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'İstatistik'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Topluluk'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}