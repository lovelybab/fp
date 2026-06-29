import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../shared/kelola_akun.dart';
import 'status_iuran.dart';
import 'lihat_pengumuman.dart';
import 'riwayat_transaksi_saya.dart';
import '../bendahara/pembukuan_kas.dart';

class DashboardWarga extends StatefulWidget {
  const DashboardWarga({super.key});

  @override
  State<DashboardWarga> createState() => _DashboardWargaState();
}

class _DashboardWargaState extends State<DashboardWarga> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  double _saldo = 0;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final saldo = await _firestoreService.hitungSaldo();
    final uid = _authService.currentUser?.uid ?? '';
    final userData = await _authService.getUserData(uid);
    if (mounted) {
      setState(() {
        _saldo = saldo;
        _userData = userData;
      });
    }
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
            // Header
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
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const KelolaAkun()),
                              );
                              _loadData();
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Halo, ${_userData?.nama ?? 'Warga'}!',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right,
                                    color: Colors.white54, size: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Saldo Kas RT',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_saldo),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'No. Rumah: ${_userData?.noRumah ?? '-'}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
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
                    // Menu
                    Row(
                      children: [
                        Expanded(
                          child: _menuCard(
                            icon: Icons.receipt_long_outlined,
                            label: 'Status\nIuran',
                            gradient: const [
                              Color(0xFFFFB74D),
                              Color(0xFFE65100)
                            ],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StatusIuran()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _menuCard(
                            icon: Icons.notifications_outlined,
                            label: 'Pengumuman\nRT',
                            gradient: const [
                              Color(0xFF4DB6AC),
                              Color(0xFF00695C)
                            ],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LihatPengumuman()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  _menuCard(
  icon: Icons.history,
  label: 'Riwayat Transaksi Saya',
  gradient: const [Color(0xFF7986CB), Color(0xFF303F9F)],
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => const RiwayatTransaksiSaya()),
  ),
  fullWidth: true,
),
const SizedBox(height: 12),
                _menuCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Pembukuan Kas RT',
                  gradient: const [Color(0xFF26A69A), Color(0xFF00695C)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PembukuanKas()),
                  ),
                  fullWidth: true,
                ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
    );
  }
}