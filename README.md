# flutter_study_track_furkan_kucuk

🚀 Kurulum ve Çalıştırma Adımları

Bu projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyin.

1. Gereksinimler

* **Flutter SDK:** 3.0.0 veya üzeri
* **Dart SDK**
* **IDE:** VS Code veya Android Studio
* **Cihaz:** Android Emülatör veya Fiziksel Cihaz

Android Emülatör veya Fiziksel Cihaz

2. Projeyi Klonlayın

Terminali açın ve projeyi bilgisayarınıza indirin:

```
git clone https://github.com/FurkanKucuk22/flutter_study_track_furkan_kucuk.git
cd flutter_study_track_furkan_kucuk
```

3. Bağımlılıkları Yükleyin

Projenin ihtiyaç duyduğu paketleri indirmek için proje dizininde şu komutu çalıştırın:

```
flutter pub get
```
4. Uygulamayı Çalıştırın

Emülatörünüzü veya fiziksel cihazınızı bağladıktan sonra aşağıdaki komutla uygulamayı başlatın:

```
flutter run
```


📂 Dosya Yapısı
```
lib/

├── main.dart # Uygulama giriş noktası
├── models/ # Veri modelleri
│ ├── post_model.dart
│ ├── session_model.dart
│ └── user_model.dart
├── screens/ # Uygulama ekranları
│ ├── auth/
│ │ ├── login_screen.dart
│ │ └── register_screen.dart
│ ├── home/
│ │ ├── community_screen.dart
│ │ ├── dashboard_screen.dart
│ │ ├── stats_screen.dart
│ │ ├── timer_screen.dart
│ │ └── goal_setting_screen.dart
│ └── profile_screen.dart
├── services/ # Firebase işlemleri
│ ├── auth_service.dart
│ └── db_service.dart
├── widgets/ # Tekrar kullanılan bileşenler
│ ├── custom_button.dart
```
