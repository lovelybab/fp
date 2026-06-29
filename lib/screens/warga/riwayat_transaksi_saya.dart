import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/iuran_model.dart';

class RiwayatTransaksiSaya extends StatefulWidget {
  const RiwayatTransaksiSaya({super.key});

  @override
  State<RiwayatTransaksiSaya> createState() => _RiwayatTransaksiSayaState();
}

class _RiwayatTransaksiSayaState extends State<RiwayatTransaksiSaya> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Saya'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<IuranModel>>(
        stream: _firestoreService.getIuranByUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hanya yang sudah lunas dianggap sebagai transaksi/riwayat pembayaran
          final riwayat = (snapshot.data ?? [])
              .where((i) => i.status == 'lunas')
              .toList()
            ..sort((a, b) {
              final tb = b.tanggalBayar ?? DateTime(2000);
              final ta = a.tanggalBayar ?? DateTime(2000);
              return tb.compareTo(ta);
            });

          if (riwayat.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi iuran yang lunas',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: riwayat.length,
            itemBuilder: (context, index) {
              final iuran = riwayat[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.check_circle_outline,
                          color: Colors.green.shade600, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Iuran ${iuran.bulan} ${iuran.tahun}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            iuran.tanggalBayar != null
                                ? 'Dibayar • ${iuran.tanggalBayar!.day}/${iuran.tanggalBayar!.month}/${iuran.tanggalBayar!.year}'
                                : 'Lunas',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '- ${_formatRupiah(iuran.jumlah)}',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}