import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';
import 'rintangan.dart';

/// Mobil lain yang melaju searah di tengah lajurnya, lebih lambat dari
/// pemain, jadi terlihat mendekat dari atas. Muncul mulai level 3.
class MobilLawan extends Rintangan {
  MobilLawan({super.x}) : super(ukuran: Vector2(52, 80), pengaliKecepatan: 0.6);

  static const _insetX = 6.0;
  static const _insetY = 4.0;

  late final Svg _gambar;

  @override
  Rect get kotakTabrak => Rect.fromLTWH(
    position.x + _insetX,
    position.y + _insetY,
    size.x - _insetX * 2,
    size.y - _insetY * 2,
  );

  /// Selalu di tengah salah satu lajur, tidak di posisi acak.
  @override
  double acakX() {
    final lajur = game.random.nextInt(GameUtama.jumlahLajur);
    return game.tengahLajur(lajur) - size.x / 2;
  }

  @override
  Future<void> onLoad() async {
    final semua = game.gambar.mobil.values.toList();
    _gambar = semua[game.random.nextInt(semua.length)];
    add(
      RectangleHitbox(
        position: Vector2(_insetX, _insetY),
        size: Vector2(size.x - _insetX * 2, size.y - _insetY * 2),
      ),
    );
  }

  @override
  void render(Canvas canvas) => _gambar.render(canvas, size);
}
