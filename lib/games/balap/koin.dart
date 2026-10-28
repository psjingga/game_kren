import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

import 'barang_ambilan.dart';

/// Koin emas di jalan; menambah jumlah koin saat diambil.
class Koin extends BarangAmbilan {
  Koin({super.x}) : super(ukuran: 28);

  static final _emas = Paint()..color = const Color(0xFFFFC107);
  static final _tepi = Paint()
    ..color = const Color(0xFFFF8F00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final _kilau = Paint()..color = const Color(0xCCFFF8E1);

  /// Jarak dan kecepatan tarikan magnet.
  static const _jangkauanMagnet = 230.0;
  static const _kecepatanMagnet = 650.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.status.magnetAktif || game.isGameOver) return;
    final arah = game.kotakMobil.center.toVector2() - absoluteCenter;
    if (arah.length < _jangkauanMagnet) {
      position += arah.normalized() * _kecepatanMagnet * dt;
    }
  }

  @override
  void diambil() => game.ambilKoin();

  @override
  void render(Canvas canvas) {
    final pusat = (size / 2).toOffset();
    final r = size.x / 2;
    canvas.drawCircle(pusat, r, _emas);
    canvas.drawCircle(pusat, r - 1.5, _tepi);
    canvas.drawCircle(pusat, r * 0.55, _tepi);
    canvas.drawCircle(pusat + Offset(-r * 0.35, -r * 0.35), r * 0.18, _kilau);
  }
}
