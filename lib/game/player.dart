import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';

/// Pemain (kotak biru).
class Player extends PositionComponent with HasGameReference<GameUtama> {
  double _arah = 0; // -1 = Kiri, 1 = Kanan, 0 = Diam

  Player() {
    size = Vector2(60, 60);
  }

  @override
  Future<void> onLoad() async {
    // Solid: meteor yang sudah berada di dalam kotak tetap terhitung kena.
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void onMount() {
    super.onMount();
    keTengah();
  }

  void bergerakKeKiri() => _arah = -1;
  void bergerakKeKanan() => _arah = 1;

  void berhenti() => _arah = 0;

  /// Kembali ke posisi awal (tengah bawah) dan berhenti.
  void keTengah() {
    _arah = 0;
    position = Vector2((game.size.x / 2) - (size.x / 2), game.size.y - 120);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _arah * game.levelConfig.kecepatanPemain * dt;
    position.x = position.x.clamp(0, game.size.x - size.x);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), Paint()..color = Colors.blue);
  }
}
