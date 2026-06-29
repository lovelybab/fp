import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../shared/kelola_akun.dart';
import 'tambah_transaksi.dart';
import 'kelola_iuran.dart';
import 'buat_pengumuman.dart';
import 'pembukuan_kas.dart';
import '../warga/lihat_pengumuman.dart';

class DashboardBendahara extends StatefulWidget {
  const DashboardBendahara({super.key});

  @override
  State<DashboardBendahara> createState() => _DashboardBendaharaState();
}

class _DashboardBendaharaState extends State<DashboardBendahara> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  double _saldo = 0;
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final saldo = await _firestoreService.hitungSaldo();
    final pemasukan = await _firestoreService.hitungTotal('pemasukan');
    final pengeluaran = await _firestoreService.hitungTotal('pengeluaran');
    final uid = _authService.currentUser?.uid ?? '';
    final userData = await _authService.getUserData(uid);
    if (mounted) {
      setState(() {
        _saldo = saldo;
        _totalPemasukan = pemasukan;
        _totalPengeluaran = pengeluaran;
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
              expandedHeight: 200,
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
                                const Icon(Icons.account_balance_wallet,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Halo, ${_userData?.nama ?? 'Bendahara'}!',
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
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _statChip(
                                Icons.arrow_downward,
                                'Masuk',
                                _formatRupiah(_totalPemasukan),
                                Colors.greenAccent,
                              ),
                              const SizedBox(width: 12),
                              _statChip(
                                Icons.arrow_upward,
                                'Keluar',
                                _formatRupiah(_totalPengeluaran),
                                Colors.redAccent,
                              ),
                            ],
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
                    // Menu Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _menuCard(
                          icon: Icons.add_circle_outline,
                          label: 'Tambah\nTransaksi',
                          gradient: const [Color(0xFF42A5F5), Color(0xFF1565C0)],
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const TambahTransaksi()));
                            _loadData();
                          },
                        ),
                        _menuCard(
                          icon: Icons.people_outline,
                          label: 'Kelola\nIuran',
                          gradient: const [Color(0xFFFFB74D), Color(0xFFE65100)],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const KelolaIuran())),
                        ),
                        _menuCard(
                          icon: Icons.campaign_outlined,
                          label: 'Buat\nPengumuman',
                          gradient: const [Color(0xFFBA68C8), Color(0xFF6A1B9A)],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const BuatPengumuman())),
                        ),
                        _menuCard(
                          icon: Icons.notifications_outlined,
                          label: 'Lihat\nPengumuman',
                          gradient: const [Color(0xFF4DB6AC), Color(0xFF00695C)],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const LihatPengumuman())),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _menuCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Pembukuan Kas (Uang Masuk & Keluar)',
                      gradient: const [Color(0xFF26A69A), Color(0xFF00695C)],
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const PembukuanKas()));
                        _loadData();
                      },
                      fullWidth: true,
                    ),

                    const SizedBox(height: 12),
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

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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
        height: fullWidth ? 64 : null,
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
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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