import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/reimburse_model.dart';

class AjukanReimburse extends StatefulWidget {
  const AjukanReimburse({super.key});

  @override
  State<AjukanReimburse> createState() => _AjukanReimburseState();
}

class _AjukanReimburseState extends State<AjukanReimburse> {
  final _judulController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;
  File? _fileNota;
  String? _base64Nota;
  String? _namaFileNota;

  Future<void> _pilihNota() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _fileNota = file;
        _namaFileNota = picked.name;
        _base64Nota = base64Encode(bytes);
      });
    }
  }

  Future<void> _ajukan() async {
    if (_judulController.text.isEmpty ||
        _keteranganController.text.isEmpty ||
        _jumlahController.text.isEmpty) {
      _showSnackBar('Semua field wajib diisi', isError: true);
      return;
    }
    if (_base64Nota == null) {
      _showSnackBar('Upload bukti nota dulu', isError: true);
      return;
    }
    final jumlah = double.tryParse(_jumlahController.text.replaceAll('.', ''));
    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah harus angka yang valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userData =
          await _authService.getUserData(_authService.currentUser?.uid ?? '');
      final reimburse = ReimburseModel(
        id: '',
        judul: _judulController.text.trim(),
        keterangan: _keteranganController.text.trim(),
        jumlah: jumlah,
        userId: _authService.currentUser?.uid ?? '',
        namaPengaju: userData?.nama ?? 'Warga',
        status: 'menunggu',
        buktiNota: _base64Nota,
        tanggalAjukan: DateTime.now(),
      );
      await _firestoreService.ajukanReimburse(reimburse);
      if (mounted) {
        _showSnackBar('Pengajuan reimburse terkirim ke Ketua RT', isError: false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Ajukan Reimburse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Untuk pengeluaran pribadi yang dipakai keperluan RT (contoh: konsumsi gotong royong). Sertakan bukti nota.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: 'Judul Pengeluaran',
                prefixIcon: Icon(Icons.title),
                hintText: 'Contoh: Konsumsi Gotong Royong',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah yang Dikeluarkan (Rp)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keteranganController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Bukti Nota / Struk',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_fileNota != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_fileNota!,
                    height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
            ],
            GestureDetector(
              onTap: _pilihNota,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _namaFileNota != null
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _namaFileNota != null
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _namaFileNota != null
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      color: _namaFileNota != null
                          ? Colors.green.shade600
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _namaFileNota ?? 'Pilih foto bukti nota',
                        style: TextStyle(
                          color: _namaFileNota != null
                              ? Colors.green.shade700
                              : Colors.grey.shade500,
                          fontWeight: _namaFileNota != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _ajukan,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Ajukan ke Ketua RT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}