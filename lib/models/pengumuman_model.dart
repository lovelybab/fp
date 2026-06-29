import 'package:cloud_firestore/cloud_firestore.dart';

class PengumumanModel {
  final String id;
  final String judul;
  final String isi;
  final String createdBy;
  final DateTime tanggal;

  PengumumanModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.createdBy,
    required this.tanggal,
  });

  factory PengumumanModel.fromMap(Map<String, dynamic> map, String id) {
    return PengumumanModel(
      id: id,
      judul: map['judul'] ?? '',
      isi: map['isi'] ?? '',
      createdBy: map['created_by'] ?? '',
      tanggal: (map['tanggal'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'isi': isi,
      'created_by': createdBy,
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }
}