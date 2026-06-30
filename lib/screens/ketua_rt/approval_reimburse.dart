import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/reimburse_model.dart';

class ApprovalReimburse extends StatelessWidget {
  const ApprovalReimburse({super.key});

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  void _lihatNota(BuildContext context, String base64Foto) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Nota'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              leading: IconButton(
                  icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.memory(base64Decode(base64Foto), fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respon(BuildContext context, FirestoreService service,
      ReimburseModel r, String status) async {
    final catatanController = TextEditingController();
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(status == 'disetujui' ? 'Setujui Reimburse?' : 'Tolak Reimburse?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.judul} - ${_formatRupiah(r.jumlah)}'),
            const SizedBox(height: 12),
            TextField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'disetujui' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'disetujui' ? 'Setujui' : 'Tolak',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await service.responReimburse(r.id, status, catatanController.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'disetujui' ? 'Reimburse disetujui' : 'Reimburse ditolak'),
            backgroundColor: status == 'disetujui' ? Colors.green.shade600 : Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Approval Reimburse'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ReimburseModel>>(
        stream: firestoreService.getReimburseMenunggu(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Tidak ada pengajuan reimburse', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(r.keterangan, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatRupiah(r.jumlah),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
                        Text('oleh ${r.namaPengaju}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    if (r.buktiNota != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _lihatNota(context, r.buktiNota!),
                          icon: const Icon(Icons.receipt_long_outlined, size: 16),
                          label: const Text('Lihat Bukti Nota'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0),
                            side: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _respon(context, firestoreService, r, 'ditolak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _respon(context, firestoreService, r, 'disetujui'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                            child: const Text('Setujui', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
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