import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'rintangan.dart';

/// Tumpahan oli: tidak membuat game over, tapi mobil yang melindasnya
/// selip sebentar dan tidak bisa disetir. Muncul mulai level 2.
class Oli extends Rintangan {
  Oli({super.x}) : super(ukuran: Vector2(56, 40));

  bool _sudahKena = false;

  @override
  bool get berbahaya => false;

  @override
  Rect get kotakTabrak => toAbsoluteRect();

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        position: Vector2(8, 6),
        size: Vector2(size.x - 16, size.y - 12),
      ),
    );
  }

  @override
  void kenaMobil() {
    if (_sudahKena) return;
    _sudahKena = true;
    game.kenaOli();
  }

  @override
  void render(Canvas canvas) => game.gambar.oli.render(canvas, size);
}
