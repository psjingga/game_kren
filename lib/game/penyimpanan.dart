import 'package:shared_preferences/shared_preferences.dart';

/// Data pemain yang bertahan setelah aplikasi ditutup, sebagai pasangan
/// kunci-nilai. Setiap fitur (rekor, garasi, hadiah harian, misi) memakai
/// kuncinya sendiri.
abstract class Penyimpanan {
  int? bacaInt(String kunci);
  String? bacaTeks(String kunci);
  List<String>? bacaDaftar(String kunci);

  Future<void> tulisInt(String kunci, int nilai);
  Future<void> tulisTeks(String kunci, String nilai);
  Future<void> tulisDaftar(String kunci, List<String> nilai);
}

/// Kunci yang dipakai lebih dari satu fitur.
abstract class KunciSimpan {
  static const rekor = 'rekor';
  static const totalKoin = 'total_koin';
}

/// Disimpan di HP lewat shared_preferences.
class PenyimpananHp implements Penyimpanan {
  PenyimpananHp._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PenyimpananHp> buka() async =>
      PenyimpananHp._(await SharedPreferences.getInstance());

  @override
  int? bacaInt(String kunci) => _prefs.getInt(kunci);

  @override
  String? bacaTeks(String kunci) => _prefs.getString(kunci);

  @override
  List<String>? bacaDaftar(String kunci) => _prefs.getStringList(kunci);

  @override
  Future<void> tulisInt(String kunci, int nilai) => _prefs.setInt(kunci, nilai);

  @override
  Future<void> tulisTeks(String kunci, String nilai) =>
      _prefs.setString(kunci, nilai);

  @override
  Future<void> tulisDaftar(String kunci, List<String> nilai) =>
      _prefs.setStringList(kunci, nilai);
}

/// Hanya di memori (hilang saat aplikasi ditutup), untuk test.
class PenyimpananMemori implements Penyimpanan {
  PenyimpananMemori({int? rekor, int? totalKoin}) {
    if (rekor != null) data[KunciSimpan.rekor] = rekor;
    if (totalKoin != null) data[KunciSimpan.totalKoin] = totalKoin;
  }

  final data = <String, Object>{};

  @override
  int? bacaInt(String kunci) => data[kunci] as int?;

  @override
  String? bacaTeks(String kunci) => data[kunci] as String?;

  @override
  List<String>? bacaDaftar(String kunci) => data[kunci] as List<String>?;

  @override
  Future<void> tulisInt(String kunci, int nilai) async => data[kunci] = nilai;

  @override
  Future<void> tulisTeks(String kunci, String nilai) async =>
      data[kunci] = nilai;

  @override
  Future<void> tulisDaftar(String kunci, List<String> nilai) async =>
      data[kunci] = [...nilai];
}
