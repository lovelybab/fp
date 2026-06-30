import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kode rahasia untuk membuat akun bendahara.
  // GANTI dengan kode rahasiamu sendiri, lalu beritahu hanya ke bendahara.
  static const String kodeRahasiaBendahara = 'BENDAHARA-RT01';

  // Mendapatkan user yang sedang login
  User? get currentUser => _auth.currentUser;

  // Stream untuk memantau status login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // LOGIN
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          result.user!.uid,
        );
      }
      return null;
    } catch (e) {
      throw Exception(_getErrorMessage(e.toString()));
    }
  }

// REGISTER (warga, bendahara, atau ketua RT pakai kode rahasia)
Future<UserModel?> register({
  required String nama,
  required String email,
  required String password,
  required String noRumah,
  required String noHp,
  String kodeRahasia = '',
}) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String role = 'warga';
    if (kodeRahasia == 'KASRT2026') {
      role = 'bendahara';
    } else if (kodeRahasia == 'KETUA2026') {
      role = 'ketua_rt';
    }

    UserModel newUser = UserModel(
      uid: result.user!.uid,
      nama: nama,
      email: email,
      role: role,
      noRumah: noRumah,
      noHp: noHp,
    );

    await _firestore
        .collection('users')
        .doc(result.user!.uid)
        .set(newUser.toMap());

    return newUser;
  } catch (e) {
    throw Exception(_getErrorMessage(e.toString()));
  }
}
  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mendapatkan data user dari Firestore
  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }

  // UPDATE PROFIL (nama, no HP, no rumah)
  Future<void> updateProfile({
    required String uid,
    required String nama,
    required String noHp,
    required String noRumah,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'nama': nama,
      'no_hp': noHp,
      'no_rumah': noRumah,
    });
  }

  // UBAH PASSWORD (butuh password lama untuk re-autentikasi)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Tidak ada user yang login');
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception(_getErrorMessage(e.toString()));
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Email tidak ditemukan';
    } else if (error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Password lama salah';
    } else if (error.contains('email-already-in-use')) {
      return 'Email sudah terdaftar';
    } else if (error.contains('weak-password')) {
      return 'Password terlalu lemah (minimal 6 karakter)';
    } else if (error.contains('invalid-email')) {
      return 'Format email tidak valid';
    } else if (error.contains('requires-recent-login')) {
      return 'Sesi login sudah lama, silakan logout dan login lagi sebelum ubah password';
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}