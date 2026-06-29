import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/pengumuman_model.dart';

class LihatPengumuman extends StatelessWidget {
  const LihatPengumuman({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: StreamBuilder<List<PengumumanModel>>(
        stream: firestoreService.getPengumuman(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pengumuman'));
          }

          final pengumumanList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pengumumanList.length,
            itemBuilder: (context, index) {
              final p = pengumumanList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.judul,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(p.isi),
                      const SizedBox(height: 8),
                      Text(
                        '${p.tanggal.day}/${p.tanggal.month}/${p.tanggal.year}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
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