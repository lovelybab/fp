import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../bendahara/dashboard_bendahara.dart';
import '../warga/dashboard_warga.dart';
import '../ketua_rt/dashboard_ketua_rt.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _noRumahController = TextEditingController();
  final _noHpController = TextEditingController();
  final _kodeRahasiaController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureKode = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _noRumahController.dispose();
    _noHpController.dispose();
    _kodeRahasiaController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _noRumahController.text.isEmpty ||
        _noHpController.text.isEmpty) {
      _showSnackBar('Semua field wajib harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        noRumah: _noRumahController.text.trim(),
        noHp: _noHpController.text.trim(),
        kodeRahasia: _kodeRahasiaController.text.trim(),
      );

      if (user != null && mounted) {
        if (user.role == 'bendahara') {
          _showSnackBar('Berhasil daftar sebagai Bendahara!', isError: false);
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardBendahara()),
            );
          }
        } else if (user.role == 'ketua_rt') {
          _showSnackBar('Berhasil daftar sebagai Ketua RT!', isError: false);
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardKetuaRT()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardWarga()),
          );
        }
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade400 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
              Color(0xFFF5F7FA)
            ],
            stops: [0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daftar Akun',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Buat akun baru KasRT',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Card
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _namaController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon:
                                  Icon(Icons.person_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon:
                                  Icon(Icons.email_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined,
                                  size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _noRumahController,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Rumah',
                              prefixIcon:
                                  Icon(Icons.home_outlined, size: 20),
                              hintText: 'Contoh: A1, B2, 05',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _noHpController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon:
                                  Icon(Icons.phone_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider kode rahasia
                          Row(
                            children: [
                              Expanded(
                                  child:
                                      Divider(color: Colors.grey.shade200)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text(
                                  'Khusus Pengurus RT',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
                                ),
                              ),
                              Expanded(
                                  child:
                                      Divider(color: Colors.grey.shade200)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _kodeRahasiaController,
                            obscureText: _obscureKode,
                            decoration: InputDecoration(
                              labelText: 'Kode Rahasia Pengurus (opsional)',
                              prefixIcon:
                                  const Icon(Icons.key_outlined, size: 20),
                              hintText: 'Kosongkan jika daftar sebagai warga',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureKode
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureKode = !_obscureKode),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kode bendahara untuk akun pengurus kas, kode ketua RT untuk akun approval dana',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Daftar Sekarang',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}