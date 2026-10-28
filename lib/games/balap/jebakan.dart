import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import 'rintangan.dart';

/// Jebakan di jalan (bom, kerucut, paku, batu, atau lubang), dipilih acak.
/// Kecepatan jatuh mengikuti level saat muncul.
class Jebakan extends Rintangan {
  Jebakan({super.x}) : super(ukuran: Vector2.all(40));

  static const _jariJari = 16.0;

  late final Svg _gambar;

  @override
  Rect get kotakTabrak =>
      Rect.fromCircle(center: absoluteCenter.toOffset(), radius: _jariJari);

  @override
  Future<void> onLoad() async {
    final semua = game.gambar.jebakan;
    _gambar = semua[game.random.nextInt(semua.length)];
    // Hitbox 80% dari gambar supaya serempetan tipis tidak dihitung kena.
    add(CircleHitbox(radius: _jariJari, position: size * 0.1));
  }

  @override
  void render(Canvas canvas) => _gambar.render(canvas, size);
}
