import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../models/iuran_model.dart';

class PembayaranIuran extends StatefulWidget {
  final IuranModel iuran;
  const PembayaranIuran({super.key, required this.iuran});

  @override
  State<PembayaranIuran> createState() => _PembayaranIuranState();
}

class _PembayaranIuranState extends State<PembayaranIuran> {
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _metodePembayaran;
  String? _namaFileBukti;
  String? _base64Bukti;
  File? _fileBukti;

  final _rekeningList = [
    {'bank': 'BCA', 'noRek': '1234567890', 'atasNama': 'Kas RT 05'},
    {'bank': 'BRI', 'noRek': '0987654321', 'atasNama': 'Kas RT 05'},
    {'bank': 'Mandiri', 'noRek': '1122334455', 'atasNama': 'Kas RT 05'},
  ];

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> _pilihFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() {
        _fileBukti = file;
        _namaFileBukti = picked.name;
        _base64Bukti = base64;
      });
      _showSnackBar('Bukti berhasil dipilih!', isError: false);
    }
  }

  Future<void> _konfirmasiPembayaran() async {
    if (_metodePembayaran == null) {
      _showSnackBar('Pilih metode pembayaran dulu', isError: true);
      return;
    }
    if (_metodePembayaran == 'transfer' && _base64Bukti == null) {
      _showSnackBar('Upload bukti transfer dulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_metodePembayaran == 'transfer' && _base64Bukti != null) {
        await _firestoreService.simpanBuktiFoto(
            widget.iuran.id, _base64Bukti!);
      } else {
        await _firestoreService.updateStatusIuran(
            widget.iuran.id, 'menunggu');
      }

      if (mounted) {
        _showSnackBar(
          _metodePembayaran == 'cod'
              ? 'Konfirmasi COD terkirim. Menunggu verifikasi bendahara.'
              : 'Bukti transfer terkirim. Menunggu verifikasi bendahara.',
          isError: false,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade400 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _salinNoRek(String noRek) {
    Clipboard.setData(ClipboardData(text: noRek));
    _showSnackBar('Nomor rekening disalin!', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pembayaran Iuran'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card detail iuran
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Iuran Kas RT',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${widget.iuran.bulan} ${widget.iuran.tahun}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Jumlah yang harus dibayar',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_formatRupiah(widget.iuran.jumlah),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pilih metode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Metode Pembayaran',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _metodeCard(
                              icon: Icons.account_balance_outlined,
                              label: 'Transfer Bank',
                              value: 'transfer',
                              color: const Color(0xFF1565C0))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _metodeCard(
                              icon: Icons.payments_outlined,
                              label: 'Bayar Tunai (COD)',
                              value: 'cod',
                              color: Colors.orange.shade700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Transfer
            if (_metodePembayaran == 'transfer') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rekening Kas RT',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._rekeningList.map((rek) => _rekeningCard(rek)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade600, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Transfer sesuai nominal, lalu upload bukti di bawah.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Bukti Transfer',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Preview foto kalau sudah dipilih
                    if (_fileBukti != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_fileBukti!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 10),
                    ],

                    GestureDetector(
                      onTap: _pilihFoto,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _namaFileBukti != null
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _namaFileBukti != null
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _namaFileBukti != null
                                  ? Icons.check_circle_outline
                                  : Icons.upload_file_outlined,
                              color: _namaFileBukti != null
                                  ? Colors.green.shade600
                                  : Colors.grey.shade500,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _namaFileBukti ??
                                    'Pilih foto bukti transfer',
                                style: TextStyle(
                                  color: _namaFileBukti != null
                                      ? Colors.green.shade700
                                      : Colors.grey.shade500,
                                  fontWeight: _namaFileBukti != null
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info COD
            if (_metodePembayaran == 'cod') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cara Bayar Tunai',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _langkahCOD('1', 'Tekan tombol konfirmasi di bawah'),
                    _langkahCOD('2', 'Hubungi atau temui bendahara RT'),
                    _langkahCOD(
                        '3',
                        'Serahkan uang tunai sebesar ${_formatRupiah(widget.iuran.jumlah)}'),
                    _langkahCOD(
                        '4', 'Bendahara akan memverifikasi pembayaranmu'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tombol konfirmasi
            if (_metodePembayaran != null)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _konfirmasiPembayaran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _metodePembayaran == 'transfer'
                              ? 'Kirim Bukti Transfer'
                              : 'Konfirmasi Bayar Tunai',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metodeCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _metodePembayaran == value;
    return GestureDetector(
      onTap: () => setState(() {
        _metodePembayaran = value;
        _namaFileBukti = null;
        _base64Bukti = null;
        _fileBukti = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    isSelected ? color : Colors.grey.shade400,
                size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Icon(Icons.check_circle, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rekeningCard(Map<String, String> rek) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance,
                color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rek['bank']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(rek['noRek']!,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                Text('a.n. ${rek['atasNama']}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _salinNoRek(rek['noRek']!),
            icon: Icon(Icons.copy_outlined,
                color: Colors.grey.shade400, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _langkahCOD(String nomor, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(nomor,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(teks,
                  style: const TextStyle(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}