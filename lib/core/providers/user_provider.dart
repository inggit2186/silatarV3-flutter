import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get hasUser => _user != null;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// Update specific fields in user
  void updateUserFields({
    String? name,
    String? nik,
    String? noHp,
    String? alamat,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? bio,
  }) {
    if (_user == null) return;

    _user = _user!.copyWith(
      name: name,
      nik: nik,
      noHp: noHp,
      alamat: alamat,
      tempatLahir: tempatLahir,
      tanggalLahir: tanggalLahir,
      jenisKelamin: jenisKelamin,
      bio: bio,
    );
    notifyListeners();
  }

  /// Update user photo
  void updatePhoto(String? photoUrl) {
    if (_user == null) return;

    _user = _user!.copyWith(
      pp: photoUrl,
      foto: photoUrl,
    );
    notifyListeners();
  }
}
