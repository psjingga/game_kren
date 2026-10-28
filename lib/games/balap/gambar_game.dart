import 'package:flame_svg/flame_svg.dart';

import 'garasi.dart';

/// Semua gambar game, dimuat sekali di awal. Ganti file di `assets/images/`
/// untuk mengganti tampilan tanpa mengubah kode.
class GambarGame {
  const GambarGame({
    required this.mobil,
    required this.jebakan,
    required this.oli,
  });

  static const _fileJebakan = [
    'jebakan_bom.svg',
    'jebakan_kerucut.svg',
    'jebakan_paku.svg',
    'jebakan_batu.svg',
    'jebakan_lubang.svg',
  ];

  /// Gambar setiap mobil di garasi, dengan id mobil sebagai kunci.
  final Map<String, Svg> mobil;
  final List<Svg> jebakan;

  /// Tumpahan oli (bukan jebakan: membuat selip, bukan game over).
  final Svg oli;

  static Future<GambarGame> muat() async {
    final hasil = await Future.wait([
      for (final m in daftarMobil) Svg.load('images/${m.file}'),
      for (final file in _fileJebakan) Svg.load('images/$file'),
      Svg.load('images/jebakan_oli.svg'),
    ]);
    return GambarGame(
      mobil: {
        for (var i = 0; i < daftarMobil.length; i++)
          daftarMobil[i].id: hasil[i],
      },
      jebakan: hasil.sublist(daftarMobil.length, hasil.length - 1),
      oli: hasil.last,
    );
  }
}
