import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/iuran_model.dart';

class KelolaIuran extends StatefulWidget {
  const KelolaIuran({super.key});

  @override
  State<KelolaIuran> createState() => _KelolaIuranState();
}

class _KelolaIuranState extends State<KelolaIuran> {
  final _firestoreService = FirestoreService();
  final List<String> _bulanList = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  late String _bulanTerpilih;
  late int _tahunTerpilih;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulanTerpilih = _bulanList[now.month - 1];
    _tahunTerpilih = now.year;
  }

  Future<void> _buatIuranBaru(UserModel warga) async {
    await _firestoreService.tambahIuran(IuranModel(
      id: '',
      userId: warga.uid,
      namaWarga: warga.nama,
      bulan: _bulanTerpilih,
      tahun: _tahunTerpilih,
      jumlah: 25000,
      status: 'belum',
    ));
  }

  Future<void> _hapusWarga(UserModel warga) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Warga?'),
        content: Text(
            'Akun ${warga.nama} akan dihapus dari daftar warga RT. Data iurannya tetap tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yakin == true) {
      await _firestoreService.hapusWarga(warga.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${warga.nama} berhasil dihapus'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _lihatBukti(BuildContext context, String base64Foto) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Transfer'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              child: Image.memory(
                base64Decode(base64Foto),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Kelola Iuran')),
      body: Column(
        children: [
          // Filter bulan & tahun
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bulanTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _bulanList.map((b) {
                      return DropdownMenuItem(value: b, child: Text(b));
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _bulanTerpilih = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _tahunTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [2024, 2025, 2026, 2027].map((t) {
                      return DropdownMenuItem(
                          value: t, child: Text(t.toString()));
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _tahunTerpilih = v!),
                  ),
                ),
              ],
            ),
          ),

          // Summary
          StreamBuilder<List<IuranModel>>(
            stream: _firestoreService.getIuranByBulanTahun(
                _bulanTerpilih, _tahunTerpilih),
            builder: (context, iuranSnapshot) {
              final iuranList = iuranSnapshot.data ?? [];
              final lunas =
                  iuranList.where((i) => i.status == 'lunas').length;
              final menunggu =
                  iuranList.where((i) => i.status == 'menunggu').length;
              final belum = iuranList.length - lunas - menunggu;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem(
                        '$lunas', 'Lunas', Colors.greenAccent),
                    Container(
                        width: 1, height: 40, color: Colors.white30),
                    _summaryItem(
                        '$menunggu', 'Menunggu', Colors.yellowAccent),
                    Container(
                        width: 1, height: 40, color: Colors.white30),
                    _summaryItem(
                        '$belum', 'Belum', Colors.orangeAccent),
                    Container(
                        width: 1, height: 40, color: Colors.white30),
                    _summaryItem(
                        _formatRupiah(lunas * 25000),
                        'Terkumpul',
                        Colors.white),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // List warga
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getWargaList(),
              builder: (context, wargaSnapshot) {
                if (!wargaSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final wargaList = wargaSnapshot.data!;

                if (wargaList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Belum ada data warga',
                            style:
                                TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<IuranModel>>(
                  stream: _firestoreService.getIuranByBulanTahun(
                      _bulanTerpilih, _tahunTerpilih),
                  builder: (context, iuranSnapshot) {
                    final iuranList = iuranSnapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: wargaList.length,
                      itemBuilder: (context, index) {
                        final warga = wargaList[index];
                        final iuranWarga = iuranList
                            .where((i) => i.userId == warga.uid)
                            .toList();
                        final sudahAda = iuranWarga.isNotEmpty;
                        final status = sudahAda
                            ? iuranWarga.first.status
                            : 'belum';
                        final isLunas = status == 'lunas';
                        final isMenunggu = status == 'menunggu';
                        final buktiFoto = sudahAda
                            ? iuranWarga.first.buktiFoto
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMenunggu
                                  ? Colors.blue.shade200
                                  : Colors.grey.shade200,
                              width: isMenunggu ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF1565C0)
                                        .withOpacity(0.1),
                                    child: Text(
                                      warga.nama[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(warga.nama,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600)),
                                        Text('No. ${warga.noRumah}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.grey.shade500)),
                                        if (isMenunggu)
                                          Text('Menunggu konfirmasi',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors
                                                      .blue.shade600,
                                                  fontWeight:
                                                      FontWeight.w500)),
                                      ],
                                    ),
                                  ),

                                  // Toggle/Button status
                                  if (!sudahAda)
                                    TextButton(
                                      onPressed: () =>
                                          _buatIuranBaru(warga),
                                      child: const Text('Buat Data'),
                                    )
                                  else if (isMenunggu)
                                    ElevatedButton(
                                      onPressed: () {
                                        _firestoreService
                                            .updateStatusIuran(
                                          iuranWarga.first.id,
                                          'lunas',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green.shade600,
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 12,
                                            vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8)),
                                      ),
                                      child: const Text('Konfirmasi',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    )
                                  else
                                    Switch(
                                      value: isLunas,
                                      activeColor: Colors.green,
                                      onChanged: (value) {
                                        _firestoreService
                                            .updateStatusIuran(
                                          iuranWarga.first.id,
                                          value ? 'lunas' : 'belum',
                                        );
                                      },
                                    ),

                                  // Tombol hapus warga
                                  IconButton(
                                    icon: Icon(Icons.person_remove_outlined,
                                        color: Colors.red.shade300,
                                        size: 20),
                                    onPressed: () => _hapusWarga(warga),
                                    tooltip: 'Hapus warga',
                                  ),
                                ],
                              ),

                              // Tombol lihat bukti transfer
                              if (isMenunggu && buktiFoto != null) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _lihatBukti(context, buktiFoto),
                                    icon: const Icon(
                                        Icons.image_outlined,
                                        size: 16),
                                    label:
                                        const Text('Lihat Bukti Transfer'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF1565C0),
                                      side: BorderSide(
                                          color: Colors.blue.shade200),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}