import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/pengumuman_model.dart';

class BuatPengumuman extends StatefulWidget {
  const BuatPengumuman({super.key});

  @override
  State<BuatPengumuman> createState() => _BuatPengumumanState();
}

class _BuatPengumumanState extends State<BuatPengumuman> {
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _simpanPengumuman() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan isi harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pengumuman = PengumumanModel(
        id: '',
        judul: _judulController.text.trim(),
        isi: _isiController.text.trim(),
        createdBy: _authService.currentUser?.uid ?? '',
        tanggal: DateTime.now(),
      );

      await _firestoreService.tambahPengumuman(pengumuman);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pengumuman')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: 'Judul Pengumuman',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _isiController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Isi Pengumuman',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _simpanPengumuman,
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
                  : const Text('Publikasikan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}