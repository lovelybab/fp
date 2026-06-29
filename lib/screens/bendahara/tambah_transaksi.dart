import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaksi_model.dart';

class TambahTransaksi extends StatefulWidget {
  const TambahTransaksi({super.key});

  @override
  State<TambahTransaksi> createState() => _TambahTransaksiState();
}

class _TambahTransaksiState extends State<TambahTransaksi> {
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  String _jenis = 'pemasukan';
  String _kategori = 'iuran';
  bool _isLoading = false;

  final List<String> _kategoriList = [
    'Bantuan Operasional',
    'Hibah',
    'lainnya',
  ];

  Future<void> _simpanTransaksi() async {
    if (_jumlahController.text.isEmpty || _keteranganController.text.isEmpty) {
      _showSnackBar('Jumlah dan keterangan harus diisi');
      return;
    }

    final jumlah = double.tryParse(_jumlahController.text.replaceAll('.', ''));
    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah harus berupa angka yang valid');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaksi = TransaksiModel(
        id: '',
        jenis: _jenis,
        jumlah: jumlah,
        keterangan: _keteranganController.text.trim(),
        kategori: _kategori,
        createdBy: _authService.currentUser?.uid ?? '',
        tanggal: DateTime.now(),
      );

      await _firestoreService.tambahTransaksi(transaksi);

      if (mounted) {
        _showSnackBar('Transaksi berhasil disimpan', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan transaksi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pilih jenis transaksi
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pemasukan',
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: 'pengeluaran',
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_jenis},
              onSelectionChanged: (Set<String> selection) {
                setState(() => _jenis = selection.first);
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _kategoriList.map((kategori) {
                return DropdownMenuItem(
                  value: kategori,
                  child: Text(kategori[0].toUpperCase() + kategori.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _kategori = value!);
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _simpanTransaksi,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan Transaksi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}