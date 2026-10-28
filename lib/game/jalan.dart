import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';

/// Latar jalan aspal dengan marka putus-putus yang bergerak ke bawah
/// secepat jebakan, supaya mobil terasa melaju.
class Jalan extends Component with HasGameReference<GameUtama> {
  Jalan() : super(priority: -1);

  static const _panjangMarka = 40.0;
  static const _jarakMarka = 40.0;
  static const _lebarMarka = 6.0;
  static const _jumlahLajur = 3;

  final _aspal = Paint()..color = const Color(0xFF4A4A4F);
  final _bahu = Paint()..color = const Color(0xFFE0E0E0);
  final _marka = Paint()..color = const Color(0xFFF5F5F5);

  double _geser = 0;

  @override
  void update(double dt) {
    if (game.isGameOver) return; // jalan berhenti saat mobil tertabrak
    _geser =
        (_geser + game.levelConfig.kecepatanJebakan * dt) %
        (_panjangMarka + _jarakMarka);
  }

  @override
  void render(Canvas canvas) {
    final ukuran = game.size;
    canvas.drawRect(Rect.fromLTWH(0, 0, ukuran.x, ukuran.y), _aspal);

    // Garis tepi jalan.
    canvas.drawRect(Rect.fromLTWH(0, 0, 4, ukuran.y), _bahu);
    canvas.drawRect(Rect.fromLTWH(ukuran.x - 4, 0, 4, ukuran.y), _bahu);

    // Marka lajur putus-putus.
    final lebarLajur = ukuran.x / _jumlahLajur;
    for (var lajur = 1; lajur < _jumlahLajur; lajur++) {
      final x = lebarLajur * lajur - _lebarMarka / 2;
      for (
        var y = _geser - _panjangMarka;
        y < ukuran.y;
        y += _panjangMarka + _jarakMarka
      ) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, _lebarMarka, _panjangMarka),
          _marka,
        );
      }
    }
  }
}
