import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

void main() {
  runApp(GameWidget(game: GameUtama()));
}

// =============================================================================
// 1. KELAS GAME UTAMA (Mengatur Dunia Game)
// =============================================================================
class GameUtama extends FlameGame with TapCallbacks {
  late Player _player;
  double _waktuMunculMeteor = 0;

  @override
  Future<void> onLoad() async {
    _player = Player();
    add(_player);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Munculkan meteor baru otomatis setiap 1.5 detik
    _waktuMunculMeteor += dt;
    if (_waktuMunculMeteor > 1.5) {
      add(Meteor());
      _waktuMunculMeteor = 0;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final lokasiKlikX = event.canvasPosition.x;

    // Klik layar kiri = ke kiri, klik layar kanan = ke kanan
    if (lokasiKlikX < size.x / 2) {
      _player.bergerakKeKiri();
    } else {
      _player.bergerakKeKanan();
    }
  }
}

// =============================================================================
// 2. KOMPONEN PEMAIN (Kotak Biru)
// =============================================================================
class Player extends PositionComponent with HasGameReference<GameUtama> {
  final double _kecepatan = 200;
  double _arah = 0; // -1 = Kiri, 1 = Kanan, 0 = Diam

  Player() {
    size = Vector2(60, 60);
  }

  @override
  void onMount() {
    super.onMount();
    position = Vector2((game.size.x / 2) - (size.x / 2), game.size.y - 120);
  }

  void bergerakKeKiri() => _arah = -1;
  void bergerakKeKanan() => _arah = 1;

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _arah * _kecepatan * dt;
    position.x = position.x.clamp(0, game.size.x - size.x);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), Paint()..color = Colors.blue);
  }
}

// =============================================================================
// 3. KOMPONEN MUSUH / METEOR (Lingkaran Merah)
// =============================================================================
class Meteor extends PositionComponent with HasGameReference<GameUtama> {
  final double _kecepatanJatuh = 250;

  Meteor() {
    size = Vector2(40, 40);
  }

  @override
  void onMount() {
    super.onMount();
    final acakX = Random().nextDouble() * (game.size.x - size.x);
    position = Vector2(acakX, -50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _kecepatanJatuh * dt;

    // Hapus dari memori jika meteor sudah melewati layar bawah
    if (position.y > game.size.y) {
      removeFromParent();
    }
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
