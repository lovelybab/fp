import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/iuran_model.dart';
import 'pembayaran_iuran.dart';

class StatusIuran extends StatefulWidget {
  const StatusIuran({super.key});

  @override
  State<StatusIuran> createState() => _StatusIuranState();
}

class _StatusIuranState extends State<StatusIuran> {
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
      appBar: AppBar(title: const Text('Status Iuran Saya')),
      body: StreamBuilder<List<IuranModel>>(
        stream: _firestoreService.getIuranByUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Belum ada data iuran'),
            );
          }

          final iuranList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: iuranList.length,
            itemBuilder: (context, index) {
              final iuran = iuranList[index];
              final isLunas = iuran.status == 'lunas';
              final isMenunggu = iuran.status == 'menunggu';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isLunas
                            ? Colors.green.shade100
                            : isMenunggu
                                ? Colors.blue.shade100
                                : Colors.orange.shade100,
                        child: Icon(
                          isLunas
                              ? Icons.check_circle
                              : isMenunggu
                                  ? Icons.hourglass_top
                                  : Icons.pending,
                          color: isLunas
                              ? Colors.green
                              : isMenunggu
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${iuran.bulan} ${iuran.tahun}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(_formatRupiah(iuran.jumlah)),
                          ],
                        ),
                      ),
                      if (isLunas)
                        const Chip(
                          label: Text('Lunas',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.green,
                        )
                      else if (isMenunggu)
                        const Chip(
                          label: Text('Menunggu Konfirmasi',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: Colors.blue,
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PembayaranIuran(iuran: iuran),
                              ),
                            );
                          },
                          child: const Text('Bayar Sekarang',
                              style: TextStyle(fontSize: 12)),
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