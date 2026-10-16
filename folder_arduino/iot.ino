#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <DHT.h>

// === KONFIGURASI WIFI ===
#define WIFI_SSID "GANTI_DENGAN_NAMA_WIFI"
#define WIFI_PASSWORD "GANTI_DENGAN_PASSWORD_WIFI"

// === KONFIGURASI FIREBASE ===
#define API_KEY "AIzaSyB2JCgH_q7g01w8KjkiK7ahOtTtmtKe8Os"
#define DATABASE_URL "https://esiot2026-9d3e9-default-rtdb.firebaseio.com/"

#define USER_EMAIL "GANTI_DENGAN_EMAIL_FIREBASE"
#define USER_PASSWORD "GANTI_DENGAN_PASSWORD_FIREBASE"

// === KONFIGURASI PIN & SENSOR ===
#define LED_PIN 2       // Built-in LED ESP32 (GPIO 2)
#define DHT_PIN 4       // Pin Data Sensor DHT (GPIO 4)
#define DHT_TYPE DHT11  // Ubah ke DHT22 jika menggunakan DHT22

DHT dht(DHT_PIN, DHT_TYPE);

// Objek Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;

void setup() {
  Serial.begin(115200);
  
  // Inisialisasi Hardware
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  dht.begin();

  // Koneksi ke WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Menghubungkan ke Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nWi-Fi Terhubung!");

  // Konfigurasi Kredensial & URL Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  // Inisialisasi Koneksi Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // Jalankan sinkronisasi data setiap 5 detik
  if (Firebase.ready() && (millis() - sendDataPrevMillis > 1000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();

    // 1. Membaca Sensor DHT
    float suhu = dht.readTemperature();
    float kelembapan = dht.readHumidity();

    if (isnan(suhu) || isnan(kelembapan)) {
      Serial.println("Gagal membaca sensor DHT!");
    } else {
      Serial.printf("Suhu: %.2f Â°C | Kelembapan: %.2f %%\n", suhu, kelembapan);

      // Kirim Data Suhu ke Firebase
      if (Firebase.setFloat(fbdo, "/esiot-db/sensor/suhu", suhu)) {
        Serial.println("Suhu berhasil dikirim.");
      } else {
        Serial.println("Gagal kirim Suhu: " + fbdo.errorReason());
      }

      // Kirim Data Kelembapan ke Firebase
      if (Firebase.setFloat(fbdo, "/esiot-db/sensor/kelembapan", kelembapan)) {
        Serial.println("Kelembapan berhasil dikirim.");
      } else {
        Serial.println("Gagal kirim Kelembapan: " + fbdo.errorReason());
      }
    }

    // 2. Membaca Status LED dari Firebase
    if (Firebase.getInt(fbdo, "/esiot-db/kontrol/led")) {
      int ledStatus = fbdo.intData();
      Serial.printf("Status LED Firebase: %d\n", ledStatus);
      
      digitalWrite(LED_PIN, ledStatus == 1 ? HIGH : LOW);
    } else {
      Serial.println("Gagal membaca status LED: " + fbdo.errorReason());
    }

    Serial.println("------------------------------------");
  }
}
