import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/proposal_model.dart';

class ApprovalProposal extends StatelessWidget {
  const ApprovalProposal({super.key});

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  Future<void> _respon(BuildContext context, FirestoreService service,
      ProposalModel proposal, String status) async {
    final catatanController = TextEditingController();
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(status == 'disetujui' ? 'Setujui Proposal?' : 'Tolak Proposal?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${proposal.judul} - ${_formatRupiah(proposal.jumlah)}'),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == 'disetujui' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'disetujui' ? 'Setujui' : 'Tolak',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await service.responProposal(
          proposal.id, status, catatanController.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'disetujui'
                ? 'Proposal disetujui'
                : 'Proposal ditolak'),
            backgroundColor:
                status == 'disetujui' ? Colors.green.shade600 : Colors.red.shade400,
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
        title: const Text('Approval Proposal'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: const TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Menunggu'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) {
            return TabBarView(
              children: [
                // Tab Menunggu
                StreamBuilder<List<ProposalModel>>(
                  stream: firestoreService.getProposalMenunggu(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data!;
                    if (list.isEmpty) {
                      return _emptyState('Tidak ada proposal menunggu');
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final p = list[index];
                        return _proposalCard(context, firestoreService, p,
                            showActions: true);
                      },
                    );
                  },
                ),
                // Tab Riwayat
                StreamBuilder<List<ProposalModel>>(
                  stream: firestoreService.getProposal(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data!
                        .where((p) => p.status != 'menunggu')
                        .toList();
                    if (list.isEmpty) {
                      return _emptyState('Belum ada riwayat');
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final p = list[index];
                        return _proposalCard(context, firestoreService, p,
                            showActions: false);
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _proposalCard(BuildContext context, FirestoreService service,
      ProposalModel p, {required bool showActions}) {
    Color statusColor;
    switch (p.status) {
      case 'disetujui':
        statusColor = Colors.blue;
        break;
      case 'selesai':
        statusColor = Colors.green;
        break;
      case 'ditolak':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

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
          Row(
            children: [
              Expanded(
                child: Text(p.judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.status[0].toUpperCase() + p.status.substring(1),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.keterangan,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatRupiah(p.jumlah),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1565C0))),
              Text('oleh ${p.namaPengaju}',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          if (p.catatanKetua != null && p.catatanKetua!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Catatan: ${p.catatanKetua}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _respon(context, service, p, 'ditolak'),
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
                    onPressed: () =>
                        _respon(context, service, p, 'disetujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                    ),
                    child: const Text('Setujui',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}