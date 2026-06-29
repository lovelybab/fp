import 'package:cloud_firestore/cloud_firestore.dart';

class IuranModel {
  final String id;
  final String userId;
  final String namaWarga;
  final String bulan;
  final int tahun;
  final double jumlah;
  final String status;
  final DateTime? tanggalBayar;
  final String? buktiFoto; // base64 string

  IuranModel({
    required this.id,
    required this.userId,
    required this.namaWarga,
    required this.bulan,
    required this.tahun,
    required this.jumlah,
    required this.status,
    this.tanggalBayar,
    this.buktiFoto,
  });

  factory IuranModel.fromMap(Map<String, dynamic> map, String id) {
    return IuranModel(
      id: id,
      userId: map['user_id'] ?? '',
      namaWarga: map['nama_warga'] ?? '',
      bulan: map['bulan'] ?? '',
      tahun: map['tahun'] ?? 0,
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      status: map['status'] ?? 'belum',
      tanggalBayar: map['tanggal_bayar'] != null
          ? (map['tanggal_bayar'] as Timestamp).toDate()
          : null,
      buktiFoto: map['bukti_foto'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nama_warga': namaWarga,
      'bulan': bulan,
      'tahun': tahun,
      'jumlah': jumlah,
      'status': status,
      'tanggal_bayar':
          tanggalBayar != null ? Timestamp.fromDate(tanggalBayar!) : null,
      'bukti_foto': buktiFoto,
    };
  }
}