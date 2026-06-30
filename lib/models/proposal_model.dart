import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalModel {
  final String id;
  final String judul;
  final String keterangan;
  final double jumlah;
  final String kategori;
  final String createdBy;
  final String namaPengaju;
  final String status; // 'menunggu', 'disetujui', 'ditolak'
  final String? catatanKetua;
  final DateTime tanggalAjukan;
  final DateTime? tanggalRespon;

  ProposalModel({
    required this.id,
    required this.judul,
    required this.keterangan,
    required this.jumlah,
    required this.kategori,
    required this.createdBy,
    required this.namaPengaju,
    required this.status,
    this.catatanKetua,
    required this.tanggalAjukan,
    this.tanggalRespon,
  });

  factory ProposalModel.fromMap(Map<String, dynamic> map, String id) {
    return ProposalModel(
      id: id,
      judul: map['judul'] ?? '',
      keterangan: map['keterangan'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toDouble(),
      kategori: map['kategori'] ?? '',
      createdBy: map['created_by'] ?? '',
      namaPengaju: map['nama_pengaju'] ?? '',
      status: map['status'] ?? 'menunggu',
      catatanKetua: map['catatan_ketua'],
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
      'kategori': kategori,
      'created_by': createdBy,
      'nama_pengaju': namaPengaju,
      'status': status,
      'catatan_ketua': catatanKetua,
      'tanggal_ajukan': Timestamp.fromDate(tanggalAjukan),
      'tanggal_respon':
          tanggalRespon != null ? Timestamp.fromDate(tanggalRespon!) : null,
    };
  }
}