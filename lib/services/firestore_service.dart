import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaksi_model.dart';
import '../models/iuran_model.dart';
import '../models/pengumuman_model.dart';
import '../models/user_model.dart';
import '../models/proposal_model.dart';
import '../models/reimburse_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== TRANSAKSI =====
  Future<void> tambahTransaksi(TransaksiModel transaksi) async {
    await _firestore.collection('transaksi').add(transaksi.toMap());
  }

  Stream<List<TransaksiModel>> getTransaksi() {
    return _firestore
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransaksiModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<double> hitungSaldo() async {
    final snapshot = await _firestore.collection('transaksi').get();
    double saldo = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final jumlah = (data['jumlah'] ?? 0).toDouble();
      if (data['jenis'] == 'pemasukan') {
        saldo += jumlah;
      } else {
        saldo -= jumlah;
      }
    }
    return saldo;
  }

  Future<void> hapusTransaksi(String id) async {
    await _firestore.collection('transaksi').doc(id).delete();
  }

  // ===== USERS / WARGA =====
  Stream<List<UserModel>> getWargaList() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'warga')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ===== IURAN =====
  Future<void> tambahIuran(IuranModel iuran) async {
    await _firestore.collection('iuran').add(iuran.toMap());
  }

  Stream<List<IuranModel>> getIuranByBulanTahun(String bulan, int tahun) {
    return _firestore
        .collection('iuran')
        .where('bulan', isEqualTo: bulan)
        .where('tahun', isEqualTo: tahun)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IuranModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<IuranModel>> getIuranByUser(String userId) {
    return _firestore
        .collection('iuran')
        .where('user_id', isEqualTo: userId)
        .orderBy('tahun', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IuranModel.fromMap(doc.data(), doc.id))
            .toList());
  }

Future<void> updateStatusIuran(String iuranId, String status) async {
  // Ambil data iuran dulu
  final iuranDoc = await _firestore.collection('iuran').doc(iuranId).get();
  final iuranData = iuranDoc.data();

  // Update status iuran
  await _firestore.collection('iuran').doc(iuranId).update({
    'status': status,
    'tanggal_bayar': status == 'lunas' ? Timestamp.now() : null,
  });

  // Kalau di-set lunas, otomatis tambah transaksi pemasukan
  if (status == 'lunas' && iuranData != null) {
    await _firestore.collection('transaksi').add({
      'jenis': 'pemasukan',
      'jumlah': iuranData['jumlah'] ?? 25000,
      'keterangan': 'Iuran ${iuranData['nama_warga'] ?? ''} - ${iuranData['bulan']} ${iuranData['tahun']}',
      'kategori': 'iuran',
      'created_by': 'sistem',
      'tanggal': Timestamp.now(),
    });
  }

  // Kalau di-set belum (toggle balik), hapus transaksi iuran terkait
  if (status == 'belum' && iuranData != null) {
    final existing = await _firestore
        .collection('transaksi')
        .where('keterangan', isEqualTo:
            'Iuran ${iuranData['nama_warga'] ?? ''} - ${iuranData['bulan']} ${iuranData['tahun']}')
        .get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }
  }
}

  // ===== PENGUMUMAN =====
  Future<void> tambahPengumuman(PengumumanModel pengumuman) async {
    await _firestore.collection('pengumuman').add(pengumuman.toMap());
  }

  Stream<List<PengumumanModel>> getPengumuman() {
    return _firestore
        .collection('pengumuman')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PengumumanModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> hapusPengumuman(String id) async {
    await _firestore.collection('pengumuman').doc(id).delete();
  }

  Future<double> hitungTotal(String jenis) async {
  final snapshot = await _firestore
      .collection('transaksi')
      .where('jenis', isEqualTo: jenis)
      .get();
  double total = 0;
  for (var doc in snapshot.docs) {
    total += (doc.data()['jumlah'] ?? 0).toDouble();
  }
  return total;
}
Future<void> simpanBuktiFoto(String iuranId, String base64Foto) async {
  await _firestore.collection('iuran').doc(iuranId).update({
    'bukti_foto': base64Foto,
    'status': 'menunggu',
    'tanggal_bayar': null,
  });
}
Future<void> hapusWarga(String uid) async {
  await _firestore.collection('users').doc(uid).delete();
}

// ===== PROPOSAL PENGELUARAN =====
Future<void> ajukanProposal(ProposalModel proposal) async {
  await _firestore.collection('proposal').add(proposal.toMap());
}

Stream<List<ProposalModel>> getProposal() {
  return _firestore
      .collection('proposal')
      .orderBy('tanggal_ajukan', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProposalModel.fromMap(doc.data(), doc.id))
          .toList());
}

Stream<List<ProposalModel>> getProposalMenunggu() {
  return _firestore
      .collection('proposal')
      .where('status', isEqualTo: 'menunggu')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProposalModel.fromMap(doc.data(), doc.id))
          .toList());
}

Future<void> responProposal(
    String proposalId, String status, String? catatan) async {
  await _firestore.collection('proposal').doc(proposalId).update({
    'status': status,
    'catatan_ketua': catatan,
    'tanggal_respon': Timestamp.now(),
  });
}

Future<void> prosesProposalKePengeluaran(ProposalModel proposal) async {
  await _firestore.collection('transaksi').add({
    'jenis': 'pengeluaran',
    'jumlah': proposal.jumlah,
    'keterangan': proposal.judul,
    'kategori': proposal.kategori,
    'created_by': proposal.createdBy,
    'tanggal': Timestamp.now(),
  });
  await _firestore.collection('proposal').doc(proposal.id).update({
    'status': 'selesai',
  });
}

// ===== REIMBURSE =====
Future<void> ajukanReimburse(ReimburseModel reimburse) async {
  await _firestore.collection('reimburse').add(reimburse.toMap());
}

Stream<List<ReimburseModel>> getReimburseByUser(String userId) {
  return _firestore
      .collection('reimburse')
      .where('user_id', isEqualTo: userId)
      .orderBy('tanggal_ajukan', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ReimburseModel.fromMap(doc.data(), doc.id))
          .toList());
}

Stream<List<ReimburseModel>> getReimburseMenunggu() {
  return _firestore
      .collection('reimburse')
      .where('status', isEqualTo: 'menunggu')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ReimburseModel.fromMap(doc.data(), doc.id))
          .toList());
}

Stream<List<ReimburseModel>> getReimburseDisetujui() {
  return _firestore
      .collection('reimburse')
      .where('status', isEqualTo: 'disetujui')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ReimburseModel.fromMap(doc.data(), doc.id))
          .toList());
}

Future<void> responReimburse(
    String reimburseId, String status, String? catatan) async {
  await _firestore.collection('reimburse').doc(reimburseId).update({
    'status': status,
    'catatan_ketua': catatan,
    'tanggal_respon': Timestamp.now(),
  });
}

Future<void> prosesReimburseSelesai(ReimburseModel reimburse) async {
  await _firestore.collection('transaksi').add({
    'jenis': 'pengeluaran',
    'jumlah': reimburse.jumlah,
    'keterangan': 'Reimburse: ${reimburse.judul} (${reimburse.namaPengaju})',
    'kategori': 'reimburse',
    'created_by': reimburse.userId,
    'tanggal': Timestamp.now(),
  });
  await _firestore.collection('reimburse').doc(reimburse.id).update({
    'status': 'selesai',
  });
}
}