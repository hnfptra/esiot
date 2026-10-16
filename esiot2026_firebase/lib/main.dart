import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

// Set kedua nilai ini ke akun yang sudah dibuat pada Firebase Authentication.
const String firebaseEmail = 'GANTI_DENGAN_EMAIL';
const String firebasePassword = 'GANTI_DENGAN_PASSWORD';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EsiotApp());
}

class EsiotApp extends StatelessWidget {
  const EsiotApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ESIOT Monitoring',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B87)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F7F8),
    ),
    home: const DashboardScreen(),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _root = FirebaseDatabase.instance.ref('esiot-db');
  String? _authError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (firebaseEmail == 'GANTI_DENGAN_EMAIL' ||
        firebasePassword == 'GANTI_DENGAN_PASSWORD') {
      setState(
        () => _authError = 'Atur firebaseEmail dan firebasePassword di lib/main.dart dengan akun Firebase Authentication.',
      );
      return;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: firebaseEmail,
        password: firebasePassword,
      );
      if (mounted) setState(() => _authError = null);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _authError =
              'Autentikasi gagal (${error.code}). Periksa akun, password, dan metode Email/Password di Firebase.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _authError = 'Gagal terhubung: $error');
    }
  }

  Future<void> _toggleLed(int currentValue) async {
    setState(() => _busy = true);
    try {
      await _root.child('kontrol/led').set(currentValue == 1 ? 0 : 1);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengubah LED: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ESIOT Monitoring')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 52),
                const SizedBox(height: 16),
                Text(_authError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESIOT Monitoring'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: const [
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 6),
                Text('Terhubung'),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _root.child('sensor').onValue,
        builder: (context, snapshot) {
          final values = _asMap(snapshot.data?.snapshot.value);
          final suhu = _asDouble(values?['suhu']);
          final kelembapan = _asDouble(values?['kelembapan']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Pemantauan perangkat',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Data sensor diperbarui secara langsung dari Firebase.'),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                _MessageCard(message: 'Gagal membaca sensor: ${snapshot.error}')
              else if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.data?.snapshot.value == null)
                const _MessageCard(message: 'Data sensor belum tersedia.')
              else
                Row(
                  children: [
                    Expanded(
                      child: _SensorCard(
                        title: 'Suhu',
                        value: suhu == null ? '--' : suhu.toStringAsFixed(1),
                        unit: '°C',
                        icon: Icons.thermostat,
                        color: const Color(0xFFE76F51),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SensorCard(
                        title: 'Kelembapan',
                        value: kelembapan == null
                            ? '--'
                            : kelembapan.toStringAsFixed(1),
                        unit: '%',
                        icon: Icons.water_drop_outlined,
                        color: const Color(0xFF2878A5),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              StreamBuilder<DatabaseEvent>(
                stream: _root.child('kontrol/led').onValue,
                builder: (context, ledSnapshot) {
                  final value = _asInt(ledSnapshot.data?.snapshot.value);
                  final isOn = value == 1;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_rounded,
                                size: 38,
                                color: isOn ? Colors.amber : Colors.blueGrey,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kontrol LED',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      value == null
                                          ? 'Status belum tersedia'
                                          : isOn
                                          ? 'Menyala · nilai 1'
                                          : 'Mati · nilai 0',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy || value == null
                                  ? null
                                  : () => _toggleLed(value),
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isOn
                                          ? Icons.power_settings_new
                                          : Icons.lightbulb_outline,
                                    ),
                              label: Text(
                                isOn ? 'Matikan LED' : 'Hidupkan LED',
                              ),
                            ),
                          ),
                          if (ledSnapshot.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'Gagal membaca LED: ${ledSnapshot.error}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Sumber data: /esiot-db/sensor dan /esiot-db/kontrol',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey),
              ),
            ],
          );
        },
      ),
    );
  }
}

Map? _asMap(Object? value) => value is Map ? value : null;

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

int? _asInt(Object? value) => value is num ? value.toInt() : null;

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$value $unit',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
