import 'package:flame_svg/flame_svg.dart';

/// Semua gambar game, dimuat sekali di awal. Ganti file di `assets/images/`
/// untuk mengganti tampilan tanpa mengubah kode.
class GambarGame {
  const GambarGame({required this.mobil, required this.jebakan});

  static const _fileJebakan = [
    'jebakan_bom.svg',
    'jebakan_kerucut.svg',
    'jebakan_paku.svg',
    'jebakan_oli.svg',
    'jebakan_batu.svg',
    'jebakan_lubang.svg',
  ];

  final Svg mobil;
  final List<Svg> jebakan;

  static Future<GambarGame> muat() async {
    final hasil = await Future.wait([
      Svg.load('images/mobil.svg'),
      for (final file in _fileJebakan) Svg.load('images/$file'),
    ]);
    return GambarGame(mobil: hasil.first, jebakan: hasil.sublist(1));
  }
}
