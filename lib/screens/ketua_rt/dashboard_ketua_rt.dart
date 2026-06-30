import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaksi_model.dart';
import '../../models/proposal_model.dart';
import '../../models/reimburse_model.dart';
import '../auth/login_screen.dart';
import '../warga/lihat_pengumuman.dart';
import 'approval_proposal.dart';
import 'approval_reimburse.dart';

class DashboardKetuaRT extends StatefulWidget {
  const DashboardKetuaRT({super.key});

  @override
  State<DashboardKetuaRT> createState() => _DashboardKetuaRTState();
}

class _DashboardKetuaRTState extends State<DashboardKetuaRT> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  double _saldo = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final saldo = await _firestoreService.hitungSaldo();
    if (mounted) setState(() => _saldo = saldo);
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF1565C0),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await _authService.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 6),
                              Text('KasRT — Ketua RT',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Saldo Kas RT',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_saldo),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu approval
                    StreamBuilder<List<ProposalModel>>(
                      stream: _firestoreService.getProposalMenunggu(),
                      builder: (context, proposalSnap) {
                        final jumlahProposal = proposalSnap.data?.length ?? 0;
                        return StreamBuilder<List<ReimburseModel>>(
                          stream: _firestoreService.getReimburseMenunggu(),
                          builder: (context, reimburseSnap) {
                            final jumlahReimburse =
                                reimburseSnap.data?.length ?? 0;
                            return Row(
                              children: [
                                Expanded(
                                  child: _menuCard(
                                    icon: Icons.description_outlined,
                                    label: 'Proposal\nPengeluaran',
                                    gradient: const [
                                      Color(0xFF7986CB),
                                      Color(0xFF303F9F)
                                    ],
                                    badge: jumlahProposal,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ApprovalProposal()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _menuCard(
                                    icon: Icons.receipt_outlined,
                                    label: 'Pengajuan\nReimburse',
                                    gradient: const [
                                      Color(0xFFFF8A65),
                                      Color(0xFFD84315)
                                    ],
                                    badge: jumlahReimburse,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ApprovalReimburse()),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _menuCard(
                      icon: Icons.notifications_outlined,
                      label: 'Pengumuman RT',
                      gradient: const [Color(0xFF4DB6AC), Color(0xFF00695C)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LihatPengumuman()),
                      ),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Riwayat Transaksi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            StreamBuilder<List<TransaksiModel>>(
              stream: _firestoreService.getTransaksi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Belum ada transaksi',
                                style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final t = snapshot.data![index];
                        final isPemasukan = t.jenis == 'pemasukan';
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
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    int badge = 0,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: fullWidth ? 64 : 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: fullWidth
                ? Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 26),
                      const SizedBox(width: 12),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
          ),
          if (badge > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}