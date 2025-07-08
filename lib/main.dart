import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'history_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Layanan Cuci Helm',
      home: const MainPage(),
      routes: {
        '/history': (context) => HistoryPage(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Cuci Helm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lihat History',
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ServiceCard(
              title: 'Standar',
              description: 'Layanan cuci helm standar.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderForm(serviceType: 'Standar'),
                  ),
                );
              },
            ),
            ServiceCard(
              title: 'Advanced',
              description: 'Layanan cuci helm dengan fitur tambahan.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderForm(serviceType: 'Advanced'),
                  ),
                );
              },
            ),
            ServiceCard(
              title: 'Pro',
              description: 'Layanan cuci helm paling lengkap dan detail.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderForm(serviceType: 'Pro'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;

  const ServiceCard({
    required this.title,
    required this.description,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Pesan'),
        ),
      ),
    );
  }
}

class OrderForm extends StatefulWidget {
  final String serviceType;
  const OrderForm({required this.serviceType, super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahHelmController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  DateTime? _tanggalAmbil;
  String? _tipePembayaran;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form Pemesanan (${widget.serviceType})')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _jumlahHelmController,
                decoration: const InputDecoration(labelText: 'Jumlah Helm'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_tanggalAmbil == null
                    ? 'Pilih Tanggal Ambil'
                    : 'Tanggal Ambil: ${_tanggalAmbil!.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalAmbil = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noHpController,
                decoration: const InputDecoration(labelText: 'No HP'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipePembayaran,
                decoration: const InputDecoration(labelText: 'Tipe Pembayaran'),
                items: const [
                  DropdownMenuItem(value: 'Tunai', child: Text('Tunai')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipePembayaran = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Pilih tipe pembayaran' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      _tanggalAmbil != null) {
                    await FirebaseFirestore.instance.collection('orders').add({
                      'serviceType': widget.serviceType,
                      'jumlahHelm': int.parse(_jumlahHelmController.text),
                      'tanggalAmbil': Timestamp.fromDate(_tanggalAmbil!),
                      'nama': _namaController.text,
                      'noHp': _noHpController.text,
                      'tipePembayaran': _tipePembayaran,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryPage()),
                        (route) => route.isFirst,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pemesanan berhasil!')),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}