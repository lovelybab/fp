import 'package:cloud_firestore/cloud_firestore.dart';

class ReimburseModel {
  final String id;
  final String judul;
  final String keterangan;
  final double jumlah;
  final String userId;
  final String namaPengaju;
  final String status; // 'menunggu', 'disetujui', 'ditolak', 'selesai'
  final String? catatanKetua;
  final String? buktiNota;
  final DateTime tanggalAjukan;
  final DateTime? tanggalRespon;

  ReimburseModel({
    required this.id,
    required this.judul,
    required this.keterangan,
    required this.jumlah,
    required this.userId,
    required this.namaPengaju,
    required this.status,
    this.catatanKetua,
    this.buktiNota,
    required this.tanggalAjukan,
    this.tanggalRespon,
  });

  factory ReimburseModel.fromMap(Map<String, dynamic> map, String id) {
    return ReimburseModel(
      id: id,
      judul: map['judul'] ?? '',
      keterangan: map['keterangan'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      userId: map['user_id'] ?? '',
      namaPengaju: map['nama_pengaju'] ?? '',
      status: map['status'] ?? 'menunggu',
      catatanKetua: map['catatan_ketua'],
      buktiNota: map['bukti_nota'],
      tanggalAjukan: (map['tanggal_ajukan'] as Timestamp).toDate(),
      tanggalRespon: map['tanggal_respon'] != null
          ? (map['tanggal_respon'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'user_id': userId,
      'nama_pengaju': namaPengaju,
      'status': status,
      'catatan_ketua': catatanKetua,
      'bukti_nota': buktiNota,
      'tanggal_ajukan': Timestamp.fromDate(tanggalAjukan),
      'tanggal_respon':
          tanggalRespon != null ? Timestamp.fromDate(tanggalRespon!) : null,
    };
  }
}