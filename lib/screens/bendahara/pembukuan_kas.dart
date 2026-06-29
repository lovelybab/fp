import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/transaksi_model.dart';

class PembukuanKas extends StatefulWidget {
  const PembukuanKas({super.key});

  @override
  State<PembukuanKas> createState() => _PembukuanKasState();
}

class _PembukuanKasState extends State<PembukuanKas> {
  final _firestoreService = FirestoreService();

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> _konfirmasiHapus(BuildContext context, String id) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text(
            'Transaksi ini akan dihapus permanen dari pembukuan kas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yakin == true) {
      await _firestoreService.hapusTransaksi(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pembukuan Kas'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TransaksiModel>>(
        stream: _firestoreService.getTransaksi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Belum ada transaksi',
                        style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              ),
            );
          }

          final transaksiList = snapshot.data!;
          final totalMasuk = transaksiList
              .where((t) => t.jenis == 'pemasukan')
              .fold(0.0, (sum, t) => sum + t.jumlah);
          final totalKeluar = transaksiList
              .where((t) => t.jenis == 'pengeluaran')
              .fold(0.0, (sum, t) => sum + t.jumlah);

          return Column(
            children: [
              // Ringkasan
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Masuk', _formatRupiah(totalMasuk),
                        Colors.greenAccent),
                    Container(width: 1, height: 36, color: Colors.white30),
                    _summaryItem('Keluar', _formatRupiah(totalKeluar),
                        Colors.redAccent),
                    Container(width: 1, height: 36, color: Colors.white30),
                    _summaryItem('Saldo',
                        _formatRupiah(totalMasuk - totalKeluar), Colors.white),
                  ],
                ),
              ),

              // List transaksi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: transaksiList.length,
                  itemBuilder: (context, index) {
                    final t = transaksiList[index];
                    final isPemasukan = t.jenis == 'pemasukan';

                    return Dismissible(
                      key: Key(t.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _konfirmasiHapus(context, t.id);
                        return false; // list otomatis update via stream
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      child: Container(
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
                                color: isPemasukan
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPemasukan
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: isPemasukan
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.keterangan,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${t.kategori[0].toUpperCase()}${t.kategori.substring(1)} • ${t.tanggal.day}/${t.tanggal.month}/${t.tanggal.year}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPemasukan ? '+' : '-'} ${_formatRupiah(t.jumlah)}',
                              style: TextStyle(
                                color: isPemasukan
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}