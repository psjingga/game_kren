import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';
import 'player.dart';

/// Meteor (lingkaran merah). Kecepatan jatuh mengikuti level saat muncul.
class Meteor extends PositionComponent
    with HasGameReference<GameUtama>, CollisionCallbacks {
  /// [x] opsional untuk menentukan posisi horizontal (dipakai di test).
  Meteor({this._x}) {
    size = Vector2(40, 40);
  }

  final double? _x;
  late final double _kecepatanJatuh;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    _kecepatanJatuh = game.levelConfig.kecepatanMeteor;
    final acakX = game.random.nextDouble() * (game.size.x - size.x);
    position = Vector2(_x ?? acakX, -50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _kecepatanJatuh * dt;

    // Meteor lolos melewati layar bawah: pemain berhasil menghindar.
    if (position.y > game.size.y) {
      game.meteorDihindari();
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) game.gameOver();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.red,
    );
  }
}
