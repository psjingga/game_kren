import 'dart:math';

/// Aturan tingkat kesulitan per level. Ubah angka di sini untuk menyeimbangkan
/// game; level 1 sama dengan game awal (meteor 250 px/detik tiap 1,5 detik,
/// pemain 200 px/detik).
class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.kecepatanMeteor,
    required this.kecepatanPemain,
    required this.jedaMunculMeteor,
  });

  /// Jumlah meteor yang harus dihindari untuk menyelesaikan satu level.
  static const meteorPerLevel = 10;

  /// Kenaikan kecepatan meteor & pemain per level (+15%), tanpa batas atas.
  static const _kenaikanPerLevel = 0.15;

  static const _kecepatanMeteorAwal = 250.0;
  static const _kecepatanPemainAwal = 200.0;

  static const _jedaAwal = 1.5;
  static const _jedaMin = 0.4;
  static const _pengaliJeda = 0.88; // jeda 12% lebih pendek per level

  final int level;

  /// Kecepatan jatuh meteor dalam piksel per detik.
  final double kecepatanMeteor;

  /// Kecepatan gerak pemain dalam piksel per detik, naik bersama meteor
  /// supaya pemain tetap bisa menghindar.
  final double kecepatanPemain;

  /// Jeda antar kemunculan meteor dalam detik.
  final double jedaMunculMeteor;

  factory LevelConfig.forLevel(int level) {
    final levelValid = max(level, 1);
    final pengali = 1 + _kenaikanPerLevel * (levelValid - 1);
    return LevelConfig(
      level: levelValid,
      kecepatanMeteor: _kecepatanMeteorAwal * pengali,
      kecepatanPemain: _kecepatanPemainAwal * pengali,
      jedaMunculMeteor: max(
        _jedaAwal * pow(_pengaliJeda, levelValid - 1),
        _jedaMin,
      ),
    );
  }
}
