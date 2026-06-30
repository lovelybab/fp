import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/proposal_model.dart';

class AjukanProposal extends StatefulWidget {
  const AjukanProposal({super.key});

  @override
  State<AjukanProposal> createState() => _AjukanProposalState();
}

class _AjukanProposalState extends State<AjukanProposal> {
  final _judulController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String _kategori = 'kegiatan';
  bool _isLoading = false;

  final List<String> _kategoriList = [
    'kegiatan', 'perbaikan', 'kebersihan', 'keamanan', 'lainnya'
  ];

  Future<void> _ajukan() async {
    if (_judulController.text.isEmpty ||
        _keteranganController.text.isEmpty ||
        _jumlahController.text.isEmpty) {
      _showSnackBar('Semua field harus diisi', isError: true);
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
      final proposal = ProposalModel(
        id: '',
        judul: _judulController.text.trim(),
        keterangan: _keteranganController.text.trim(),
        jumlah: jumlah,
        kategori: _kategori,
        createdBy: _authService.currentUser?.uid ?? '',
        namaPengaju: userData?.nama ?? 'Bendahara',
        status: 'menunggu',
        tanggalAjukan: DateTime.now(),
      );
      await _firestoreService.ajukanProposal(proposal);
      if (mounted) {
        _showSnackBar('Proposal berhasil diajukan ke Ketua RT', isError: false);
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
      appBar: AppBar(title: const Text('Ajukan Proposal Pengeluaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Proposal akan dikirim ke Ketua RT untuk disetujui sebelum dana dikeluarkan.',
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
                hintText: 'Contoh: Perbaikan Lampu Jalan',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Dana (Rp)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _kategoriList.map((k) {
                return DropdownMenuItem(
                    value: k, child: Text(k[0].toUpperCase() + k.substring(1)));
              }).toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keteranganController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Keterangan / Alasan Pengeluaran',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
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