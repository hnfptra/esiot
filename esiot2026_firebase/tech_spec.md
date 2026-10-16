# Spesifikasi Teknis — ESIOT Monitoring

## 1. Tujuan dan cakupan

Aplikasi Android berbasis Flutter untuk melihat nilai suhu dan kelembapan secara real time dari Firebase Realtime Database serta mengendalikan nilai LED. Firebase diinisialisasi menggunakan konfigurasi FlutterFire yang sudah ada pada `lib/firebase_options.dart`.

## 2. Fitur inti

- **Autentikasi otomatis:** aplikasi login menggunakan Firebase Authentication metode Email/Password. Kredensial diterima melalui compile-time defines `FIREBASE_EMAIL` dan `FIREBASE_PASSWORD`; tidak ada form login. Aplikasi tidak membuat akun secara otomatis. Kredensial harus menunjuk akun yang telah dibuat dan diaktifkan pada Firebase Console.
- **Pemantauan sensor:** listener RTDB menampilkan `suhu` dalam °C dan `kelembapan` dalam %. Perubahan nilai ditampilkan tanpa refresh manual.
- **Kontrol LED:** status LED dibaca secara live. Tombol mengubah nilai 0 menjadi 1 (hidup), atau 1 menjadi 0 (mati), lalu menulis nilai integer ke RTDB. Tombol tidak aktif sebelum nilai status tersedia atau saat penulisan berlangsung.
- **Status kesalahan:** layar menampilkan langkah pemulihan untuk kegagalan autentikasi; error pembacaan dan penulisan ditampilkan pada dashboard.

## 3. Alur pengguna

1. Aplikasi menginisialisasi Flutter binding dan Firebase dengan konfigurasi platform Android.
2. Aplikasi mencoba login dengan kredensial yang diteruskan saat build/run.
3. Jika login gagal atau konstanta belum diisi, dashboard data tidak dibuka; pesan kesalahan dan tombol coba lagi ditampilkan.
4. Setelah login berhasil, listener membaca `/esiot-db/sensor` dan `/esiot-db/kontrol/led`.
5. User melihat kartu suhu/kelembapan dan status LED. Tekan tombol LED untuk menulis nilai kebalikan dari status terakhir yang diterima.
6. Listener LED mengonfirmasi nilai terbaru dari Firebase dan memperbarui label serta ikon.

## 4. Skema Realtime Database

```json
{
  "esiot-db": {
    "kontrol": { "led": 0 },
    "sensor": {
      "kelembapan": 60.0,
      "suhu": 25.5
    }
  }
}
```

| Path | Tipe | Arti |
|---|---|---|
| `/esiot-db/kontrol/led` | integer | `0` = mati, `1` = hidup |
| `/esiot-db/sensor/kelembapan` | number (float/double) | Kelembapan relatif, ditampilkan dalam persen |
| `/esiot-db/sensor/suhu` | number (float/double) | Suhu dalam derajat Celsius |

Nama root yang dipakai aplikasi adalah `esiot-db` (tanda hubung). Pastikan path tersebut sama dengan struktur di konsol RTDB.

## 5. Keamanan dan konfigurasi

Rule yang diberikan mengharuskan pengguna terautentikasi untuk membaca dan menulis pada `esiot-db`:

```json
{
  "rules": {
    "esiot-db": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

1. Aktifkan metode Email/Password di Firebase Authentication dan buat akun operasional.
2. Buat `firebase_secrets.json` berdasarkan `firebase_secrets.example.json`, lalu isi kredensial akun. File rahasia tersebut dikecualikan dari Git. Jalankan aplikasi dengan `flutter run --dart-define-from-file=../firebase_secrets.json` dari direktori `esiot2026_firebase`.
3. Konstanta yang ditanam di aplikasi dapat diekstrak dari paket APK; gunakan akun berhak minimum dan aturan keamanan RTDB yang lebih rinci untuk distribusi produksi. Autentikasi membuktikan identitas akun, sementara rule di atas memberi setiap akun terautentikasi akses baca/tulis ke seluruh node `esiot-db`.
4. File `google-services.json` Android dan `firebase_options.dart` harus menunjuk ke project Firebase/RTDB yang sama.

## 6. Dependensi dan platform

- Flutter + Material 3
- `firebase_core`, `firebase_auth`, `firebase_database`
- Target aplikasi yang diminta: Android
- Paket `fl_chart` yang sudah ada di proyek tidak lagi digunakan oleh dashboard ini.

## 7. Penanganan data

Nilai numerik Firebase diterima sebagai `num` lalu dikonversi ke `double` untuk tampilan. Data sensor atau status LED yang hilang ditampilkan sebagai belum tersedia; status LED tidak diasumsikan mati saat nilainya belum terbaca. Batas grafik/penyimpanan riwayat tidak diterapkan pada versi ini.
