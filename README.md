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
git clone flutter_study_track_furkan_kucuk
cd studytrack
```

3. Bağımlılıkları Yükleyin

Projenin ihtiyaç duyduğu paketleri indirmek için proje dizininde şu komutu çalıştırın:

```
flutter pub get
```

4. Firebase Yapılandırması (Önemli!)

Bu proje Firebase servislerini kullandığı için google-services.json dosyasına ihtiyaç duyar.

Firebase Konsolu'na gidin ve yeni bir proje oluşturun.

Authentication servisini başlatın ve "Email/Password" yöntemini etkinleştirin.

Cloud Firestore veritabanını oluşturun (Production mode önerilir) ve Kurallar (Rules) sekmesinden okuma/yazma izni verin:

```
allow read, write: if request.auth != null;
```


Proje Ayarları'ndan bir Android Uygulaması ekleyin. Paket adı olarak android/app/build.gradle içindeki applicationId'yi kullanın (Örn: com.example.studytrack).

İndirdiğiniz google-services.json dosyasını projenin android/app/ klasörünün içine yapıştırın.

5. Uygulamayı Çalıştırın

Emülatörünüzü veya fiziksel cihazınızı bağladıktan sonra aşağıdaki komutla uygulamayı başlatın:

```
flutter run
```


📂 Dosya Yapısı

lib/
├── main.dart             # Uygulama giriş noktası
├── models/               # Veri modelleri (User, Session, Post)
├── services/             # Firebase işlemleri (Auth, DB)
├── screens/              # Uygulama ekranları
│   ├── auth/             # Giriş ve Kayıt
│   ├── home/             # Ana sayfa, Sayaç, İstatistik, Topluluk
│   └── profile_screen.dart
└── widgets/              # Ortak bileşenler


⚠️ Karşılaşılabilecek Sorunlar ve Çözümleri

İstatistik Ekranı Açılmıyor: Terminalde çıkan mavi Firebase linkine tıklayarak Firestore İndeks'ini oluşturmanız gerekir.

Klavye Sorunu (Örn: i yerine ı): Emülatör ayarlarından fiziksel klavyeyi devre dışı bırakın veya main.dart içindeki Localization ayarlarının yüklendiğinden emin olun.
