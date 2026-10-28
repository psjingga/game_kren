import 'package:shared_preferences/shared_preferences.dart';

/// Data pemain yang bertahan setelah aplikasi ditutup.
abstract class Penyimpanan {
  int get rekor;
  int get totalKoin;

  /// Id mobil yang sudah dibeli (lihat `daftarMobil`).
  Set<String> get mobilDimiliki;
  String get mobilDipakai;

  Future<void> simpan({required int rekor, required int totalKoin});

  /// Dipanggil saat membeli atau mengganti mobil. Total koin ikut disimpan
  /// karena pembelian mengurangi koin.
  Future<void> simpanGarasi({
    required int totalKoin,
    required Set<String> mobilDimiliki,
    required String mobilDipakai,
  });
}

/// Disimpan di HP lewat shared_preferences.
class PenyimpananHp implements Penyimpanan {
  PenyimpananHp._(this._prefs);

  static const _kunciRekor = 'rekor';
  static const _kunciTotalKoin = 'total_koin';
  static const _kunciMobilDimiliki = 'mobil_dimiliki';
  static const _kunciMobilDipakai = 'mobil_dipakai';

  final SharedPreferences _prefs;

  static Future<PenyimpananHp> buka() async =>
      PenyimpananHp._(await SharedPreferences.getInstance());

  @override
  int get rekor => _prefs.getInt(_kunciRekor) ?? 0;

  @override
  int get totalKoin => _prefs.getInt(_kunciTotalKoin) ?? 0;

  @override
  Set<String> get mobilDimiliki =>
      (_prefs.getStringList(_kunciMobilDimiliki) ?? const []).toSet();

  @override
  String get mobilDipakai => _prefs.getString(_kunciMobilDipakai) ?? '';

  @override
  Future<void> simpan({required int rekor, required int totalKoin}) async {
    await _prefs.setInt(_kunciRekor, rekor);
    await _prefs.setInt(_kunciTotalKoin, totalKoin);
  }

  @override
  Future<void> simpanGarasi({
    required int totalKoin,
    required Set<String> mobilDimiliki,
    required String mobilDipakai,
  }) async {
    await _prefs.setInt(_kunciTotalKoin, totalKoin);
    await _prefs.setStringList(_kunciMobilDimiliki, mobilDimiliki.toList());
    await _prefs.setString(_kunciMobilDipakai, mobilDipakai);
  }
}

/// Hanya di memori (hilang saat aplikasi ditutup), untuk test.
class PenyimpananMemori implements Penyimpanan {
  PenyimpananMemori({
    this.rekor = 0,
    this.totalKoin = 0,
    Set<String>? mobilDimiliki,
    this.mobilDipakai = '',
  }) : mobilDimiliki = mobilDimiliki ?? {};

  @override
  int rekor;

  @override
  int totalKoin;

  @override
  Set<String> mobilDimiliki;

  @override
  String mobilDipakai;

  @override
  Future<void> simpan({required int rekor, required int totalKoin}) async {
    this.rekor = rekor;
    this.totalKoin = totalKoin;
  }

  @override
  Future<void> simpanGarasi({
    required int totalKoin,
    required Set<String> mobilDimiliki,
    required String mobilDipakai,
  }) async {
    this.totalKoin = totalKoin;
    this.mobilDimiliki = {...mobilDimiliki};
    this.mobilDipakai = mobilDipakai;
  }
}
