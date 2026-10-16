# ESIOT: pemantauan sensor dan kontrol LED

Repositori ini berisi aplikasi Flutter Android untuk memantau suhu dan kelembapan melalui Firebase Realtime Database, serta sketch ESP32 untuk membaca sensor DHT dan mengendalikan LED.

## Struktur

- `esiot2026_firebase/` — aplikasi Flutter dan spesifikasi teknis (`tech_spec.md`).
- `folder_arduino/iot.ino` — sketch ESP32 untuk DHT dan Firebase RTDB.

## Konfigurasi

1. Konfigurasikan Firebase FlutterFire untuk project Anda. File `android/app/google-services.json` dan `lib/firebase_options.dart` harus berasal dari project Firebase yang sama.
2. Aktifkan Firebase Authentication Email/Password dan siapkan pengguna.
3. Isi konstanta `firebaseEmail` dan `firebasePassword` di `esiot2026_firebase/lib/main.dart`.
4. Isi kredensial Wi-Fi dan Firebase Authentication di bagian konfigurasi `folder_arduino/iot.ino`.
5. Pastikan URL RTDB dan path `esiot-db` sesuai dengan database yang digunakan.

Nilai kredensial pada source code adalah placeholder. Jangan commit password atau kredensial pribadi.

## Menjalankan aplikasi

Dari folder `esiot2026_firebase`, jalankan `flutter pub get`, lalu `flutter run`.

Detail fitur, alur, dan skema database ada di `esiot2026_firebase/tech_spec.md`.
