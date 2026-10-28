import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';
import 'player.dart';

/// Jebakan di jalan (bom, kerucut, paku, oli, batu, atau lubang), dipilih
/// acak. Kecepatan jatuh mengikuti level saat muncul.
class Jebakan extends PositionComponent
    with HasGameReference<GameUtama>, CollisionCallbacks {
  /// [x] opsional untuk menentukan posisi horizontal (dipakai di test).
  Jebakan({this._x}) {
    size = Vector2(40, 40);
  }

  final double? _x;
  late final double _kecepatanJatuh;
  late final Svg _gambar;

  @override
  Future<void> onLoad() async {
    final semua = game.gambar.jebakan;
    _gambar = semua[game.random.nextInt(semua.length)];
    // Hitbox 80% dari gambar supaya serempetan tipis tidak dihitung kena.
    add(CircleHitbox(radius: size.x * 0.4, position: size * 0.1));
  }

  @override
  void onMount() {
    super.onMount();
    _kecepatanJatuh = game.levelConfig.kecepatanJebakan;
    final acakX = game.random.nextDouble() * (game.size.x - size.x);
    position = Vector2(_x ?? acakX, -50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Semua jebakan membeku saat mobil tertabrak.
    if (game.isGameOver) return;
    position.y += _kecepatanJatuh * dt;

    // Jebakan lolos melewati layar bawah: pemain berhasil menghindar.
    if (position.y > game.size.y) {
      game.jebakanDihindari();
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      game.gameOver(titikTabrakan: absoluteCenter);
      removeFromParent(); // jebakan hancur dalam ledakan
    }
  }

  @override
  void render(Canvas canvas) => _gambar.render(canvas, size);
}
