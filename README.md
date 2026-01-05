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
cd flutter_study_track_furkan_kucu
```

3. Bağımlılıkları Yükleyin

Projenin ihtiyaç duyduğu paketleri indirmek için proje dizininde şu komutu çalıştırın:

```
flutter pub get
```
4. Çalıştırın
```
flutter run
```
Yazdıktan sonra normalde kullandığınız emülatörü seçebilirsiniz.

5. Uygulamayı Çalıştırın

Emülatörünüzü veya fiziksel cihazınızı bağladıktan sonra aşağıdaki komutla uygulamayı başlatın:

```
flutter run
```


📂 Dosya Yapısı
```
lib/
├── main.dart           # Uygulama giriş noktası
├── models/             # Veri modelleri (User, Session, Post)
├── services/           # Firebase işlemleri (Auth, DB)
├── screens/            # Uygulama ekranları
│   ├── auth/           # Giriş ve Kayıt ekranları
│   ├── home/           # Ana sayfa, Sayaç, İstatistik, Topluluk
│   └── profile_screen.dart
└── widgets/            # Ortak kullanılan bileşenler
```
