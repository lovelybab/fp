class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final String noRumah;
  final String noHp;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    required this.noRumah,
    required this.noHp,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'warga',
      noRumah: map['no_rumah'] ?? '',
      noHp: map['no_hp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role,
      'no_rumah': noRumah,
      'no_hp': noHp,
    };
  }
}