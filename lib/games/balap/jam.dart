import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'barang_ambilan.dart';

/// Jam (stopwatch) di jalan; memotong sisa waktu level saat diambil.
class Jam extends BarangAmbilan {
  Jam({super.x}) : super(ukuran: 34);

  static final _badan = Paint()..color = const Color(0xFF29B6F6);
  static final _muka = Paint()..color = Colors.white;
  static final _garis = Paint()
    ..color = const Color(0xFF0D47A1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  @override
  void diambil() => game.ambilJam();

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final pusat = Offset(r, r + 2);

    // Tombol di atas stopwatch.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(r, 3), width: 9, height: 6),
        const Radius.circular(2),
      ),
      _badan,
    );
    canvas.drawCircle(pusat, r - 2, _badan);
    canvas.drawCircle(pusat, r - 6, _muka);

    // Jarum menunjuk ke "jam 12" dan "jam 2".
    canvas.drawLine(pusat, pusat + Offset(0, -(r - 10)), _garis);
    canvas.drawLine(
      pusat,
      pusat + Offset(cos(-pi / 6), sin(-pi / 6)) * (r - 12),
      _garis,
    );
  }
}

/// Tulisan yang melayang naik lalu memudar, misalnya "-3 detik".
class TeksMelayang extends PositionComponent {
  TeksMelayang(this.teks, {required super.position, required this.warna})
    : super(anchor: Anchor.center, priority: 20);

  final String teks;
  final Color warna;

  static const _lama = 0.9;
  double _umur = 0;

  @override
  void update(double dt) {
    _umur += dt;
    position.y -= 60 * dt;
    if (_umur >= _lama) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final sisa = (1 - _umur / _lama).clamp(0.0, 1.0);
    final pelukis = TextPainter(
      text: TextSpan(
        text: teks,
        style: TextStyle(
          color: warna.withValues(alpha: sisa),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7 * sisa),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pelukis.paint(canvas, Offset(-pelukis.width / 2, -pelukis.height / 2));
  }
}
