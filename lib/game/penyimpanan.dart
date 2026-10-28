import 'package:shared_preferences/shared_preferences.dart';

/// Data pemain yang bertahan setelah aplikasi ditutup.
abstract class Penyimpanan {
  int get rekor;
  int get totalKoin;

  Future<void> simpan({required int rekor, required int totalKoin});
}

/// Disimpan di HP lewat shared_preferences.
class PenyimpananHp implements Penyimpanan {
  PenyimpananHp._(this._prefs);

  static const _kunciRekor = 'rekor';
  static const _kunciTotalKoin = 'total_koin';

  final SharedPreferences _prefs;

  static Future<PenyimpananHp> buka() async =>
      PenyimpananHp._(await SharedPreferences.getInstance());

  @override
  int get rekor => _prefs.getInt(_kunciRekor) ?? 0;

  @override
  int get totalKoin => _prefs.getInt(_kunciTotalKoin) ?? 0;

  @override
  Future<void> simpan({required int rekor, required int totalKoin}) async {
    await _prefs.setInt(_kunciRekor, rekor);
    await _prefs.setInt(_kunciTotalKoin, totalKoin);
  }
}

/// Hanya di memori (hilang saat aplikasi ditutup), untuk test.
class PenyimpananMemori implements Penyimpanan {
  PenyimpananMemori({this.rekor = 0, this.totalKoin = 0});

  @override
  int rekor;

  @override
  int totalKoin;

  @override
  Future<void> simpan({required int rekor, required int totalKoin}) async {
    this.rekor = rekor;
    this.totalKoin = totalKoin;
  }
}
