import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';

/// Garis finish kotak-kotak selebar jalan. Muncul saat waktu level habis,
/// turun secepat jebakan, dan level selesai saat mobil melewatinya.
class GarisFinish extends PositionComponent with HasGameReference<GameUtama> {
  GarisFinish() : super(priority: 0);

  static const _sisiKotak = 18.0;
  static const _barisKotak = 2;
  static const _tinggiSpanduk = 30.0;

  static final _hitam = Paint()..color = const Color(0xFF1A1A1A);
  static final _putih = Paint()..color = Colors.white;
  static final _spanduk = Paint()..color = const Color(0xFFD32F2F);

  late final double _kecepatan;
  late final TextPainter _tulisan;

  @override
  void onMount() {
    super.onMount();
    _kecepatan = game.levelConfig.kecepatanJebakan;
    size = Vector2(game.size.x, _tinggiSpanduk + _sisiKotak * _barisKotak);
    position = Vector2(0, -size.y);
    _tulisan = TextPainter(
      text: const TextSpan(
        text: 'FINISH',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Bawah garis kotak-kotak, yang "dilewati" mobil.
  double get _tepiBawah => position.y + size.y;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;
    position.y += _kecepatan * dt;
    if (_tepiBawah >= game.posisiDepanMobil) game.melewatiFinish();
  }

  @override
  void render(Canvas canvas) {
    // Spanduk merah bertuliskan FINISH.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, _tinggiSpanduk), _spanduk);
    _tulisan.paint(
      canvas,
      Offset(
        (size.x - _tulisan.width) / 2,
        (_tinggiSpanduk - _tulisan.height) / 2,
      ),
    );

    // Kotak-kotak hitam putih.
    final jumlahKolom = (size.x / _sisiKotak).ceil();
    for (var baris = 0; baris < _barisKotak; baris++) {
      for (var kolom = 0; kolom < jumlahKolom; kolom++) {
        canvas.drawRect(
          Rect.fromLTWH(
            kolom * _sisiKotak,
            _tinggiSpanduk + baris * _sisiKotak,
            _sisiKotak,
            _sisiKotak,
          ),
          (baris + kolom).isEven ? _hitam : _putih,
        );
      }
    }
  }
}
