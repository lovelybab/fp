import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  final String id;
  final String jenis; // 'pemasukan' atau 'pengeluaran'
  final double jumlah;
  final String keterangan;
  final String kategori;
  final String createdBy;
  final DateTime tanggal;

  TransaksiModel({
    required this.id,
    required this.jenis,
    required this.jumlah,
    required this.keterangan,
    required this.kategori,
    required this.createdBy,
    required this.tanggal,
  });

  factory TransaksiModel.fromMap(Map<String, dynamic> map, String id) {
    return TransaksiModel(
      id: id,
      jenis: map['jenis'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      keterangan: map['keterangan'] ?? '',
      kategori: map['kategori'] ?? '',
      createdBy: map['created_by'] ?? '',
      tanggal: (map['tanggal'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jenis': jenis,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'kategori': kategori,
      'created_by': createdBy,
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }
}