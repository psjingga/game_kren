import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'game_utama.dart';
import 'player.dart';

/// Sesuatu di jalan yang harus dihindari mobil: jebakan, mobil lain, oli.
///
/// Jatuh dari atas, membeku saat mobil tertabrak, dan menambah skor saat
/// lolos melewati layar bawah. Rintangan yang [berbahaya] juga memberi
/// bonus "nyaris" bila dilewati mobil dengan jarak sangat tipis.
abstract class Rintangan extends PositionComponent
    with HasGameReference<GameUtama>, CollisionCallbacks {
  /// [x] opsional untuk menentukan posisi horizontal (dipakai di test dan
  /// barisan jebakan).
  Rintangan({this._x, required Vector2 ukuran, this.pengaliKecepatan = 1}) {
    size = ukuran;
  }

  /// Jarak samping (piksel) yang dihitung "nyaris".
  static const jarakNyaris = 12.0;

  final double? _x;

  /// Kecepatan jatuh relatif terhadap kecepatan jebakan di level ini.
  final double pengaliKecepatan;

  late final double _kecepatanJatuh;
  double _jarakTerdekat = double.infinity;
  bool _sudahLewatMobil = false;

  /// `false` untuk rintangan yang tidak membuat game over (misalnya oli).
  bool get berbahaya => true;

  /// Kotak tabrakan di koordinat layar, untuk menghitung "nyaris".
  Rect get kotakTabrak;

  /// Saat mengenai mobil. Bawaan: tabrakan (atau ditahan perisai).
  void kenaMobil() => game.kenaRintangan(this);

  /// Posisi x acak di dalam jalan.
  double acakX() =>
      game.batasKiri +
      game.random.nextDouble() * (game.batasKanan - game.batasKiri - size.x);

  @override
  void onMount() {
    super.onMount();
    _kecepatanJatuh = game.levelConfig.kecepatanJebakan * pengaliKecepatan;
    position = Vector2(_x ?? acakX(), -size.y - 10);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;
    position.y += _kecepatanJatuh * dt;
    if (berbahaya) _periksaNyaris();

    // Lolos melewati layar bawah: pemain berhasil menghindar.
    if (position.y > game.size.y) {
      game.jebakanDihindari();
      removeFromParent();
    }
  }

  /// Mencatat jarak samping terdekat selama sejajar dengan mobil; setelah
  /// rintangan lewat, jarak yang sangat tipis memberi bonus.
  void _periksaNyaris() {
    if (_sudahLewatMobil) return;
    final mobil = game.kotakMobil;
    final kotak = kotakTabrak;
    if (kotak.bottom < mobil.top) return; // belum sejajar

    if (kotak.top <= mobil.bottom) {
      final jarak = max(kotak.left - mobil.right, mobil.left - kotak.right);
      _jarakTerdekat = min(_jarakTerdekat, jarak);
      return;
    }

    _sudahLewatMobil = true;
    if (_jarakTerdekat >= 0 && _jarakTerdekat < jarakNyaris) {
      game.nyaris(Vector2(kotak.center.dx, mobil.center.dy));
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && !game.isGameOver) kenaMobil();
  }
}
