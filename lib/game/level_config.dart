import 'dart:math';

/// Aturan tingkat kesulitan per level. Ubah angka di sini untuk menyeimbangkan
/// game; level 1 sama dengan game awal (jebakan 250 px/detik tiap 1,5 detik).
/// Mobil pemain tidak punya kecepatan sendiri: ia mengikuti gerak jari.
class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.kecepatanJebakan,
    required this.jedaMunculJebakan,
  });

  /// Lama bertahan (detik) untuk menyelesaikan satu level, sama di semua level.
  static const durasiLevel = 30.0;

  /// Kenaikan kecepatan jebakan per level (+15%), tanpa batas atas.
  static const _kenaikanPerLevel = 0.15;

  static const _kecepatanJebakanAwal = 250.0;

  static const _jedaAwal = 1.5;
  static const _jedaMin = 0.4;
  static const _pengaliJeda = 0.88; // jeda 12% lebih pendek per level

  final int level;

  /// Kecepatan jatuh jebakan dalam piksel per detik.
  final double kecepatanJebakan;

  /// Jeda antar kemunculan jebakan dalam detik.
  final double jedaMunculJebakan;

  factory LevelConfig.forLevel(int level) {
    final levelValid = max(level, 1);
    final pengali = 1 + _kenaikanPerLevel * (levelValid - 1);
    return LevelConfig(
      level: levelValid,
      kecepatanJebakan: _kecepatanJebakanAwal * pengali,
      jedaMunculJebakan: max(
        _jedaAwal * pow(_pengaliJeda, levelValid - 1),
        _jedaMin,
      ),
    );
  }
}
