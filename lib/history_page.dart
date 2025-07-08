import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Pemesanan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada pemesanan'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                      '${data['serviceType']} - ${data['jumlahHelm']} helm'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal Ambil: ${data['tanggalAmbil'] != null ? (data['tanggalAmbil'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : '-'}'),
                      Text('Nama: ${data['nama']}'),
                      Text('No HP: ${data['noHp']}'),
                      Text('Tipe Pembayaran: ${data['tipePembayaran']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditOrderPage(
                                docId: docs[index].id,
                                data: data,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(docs[index].id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditOrderPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditOrderPage({required this.docId, required this.data, super.key});

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  late TextEditingController _jumlahHelmController;
  late TextEditingController _namaController;
  late TextEditingController _noHpController;
  DateTime? _tanggalAmbil;
  String? _tipePembayaran;

  @override
  void initState() {
    super.initState();
    _jumlahHelmController =
        TextEditingController(text: widget.data['jumlahHelm'].toString());
    _namaController = TextEditingController(text: widget.data['nama']);
    _noHpController = TextEditingController(text: widget.data['noHp']);
    _tanggalAmbil = (widget.data['tanggalAmbil'] as Timestamp).toDate();
    _tipePembayaran = widget.data['tipePembayaran'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pemesanan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Layanan: ${widget.data['serviceType']}'),
            const SizedBox(height: 8),
            TextField(
              controller: _jumlahHelmController,
              decoration: const InputDecoration(labelText: 'Jumlah Helm'),
              keyboardType: TextInputType.number,
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
                  initialDate: _tanggalAmbil ?? DateTime.now(),
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
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noHpController,
              decoration: const InputDecoration(labelText: 'No HP'),
              keyboardType: TextInputType.phone,
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
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(widget.docId)
                    .update({
                  'jumlahHelm': int.parse(_jumlahHelmController.text),
                  'tanggalAmbil': Timestamp.fromDate(_tanggalAmbil!),
                  'nama': _namaController.text,
                  'noHp': _noHpController.text,
                  'tipePembayaran': _tipePembayaran,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil diubah!')),
                  );
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}