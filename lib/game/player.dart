import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'efek_crash.dart';
import 'game_utama.dart';

/// Mobil pemain, dilihat dari atas.
class Player extends PositionComponent with HasGameReference<GameUtama> {
  Player() {
    size = Vector2(52, 80);
  }

  /// Warna gosong ditimpakan ke gambar mobil setelah tertabrak.
  static const _filterGosong = ColorFilter.mode(
    Color(0xCC2B1B12),
    BlendMode.srcATop,
  );

  final _paint = Paint()..filterQuality = FilterQuality.medium;
  bool _terbakar = false;

  bool get terbakar => _terbakar;

  @override
  Future<void> onLoad() async {
    // Hitbox sedikit lebih kecil dari gambar supaya tabrakan terasa adil.
    // Solid: jebakan yang sudah berada di dalam mobil tetap terhitung kena.
    add(
      RectangleHitbox(
        position: Vector2(6, 4),
        size: Vector2(size.x - 12, size.y - 8),
        isSolid: true,
      ),
    );
  }

  @override
  void onMount() {
    super.onMount();
    keTengah();
  }

  /// Jarak dari atas mobil ke bawah layar. Cukup tinggi supaya mobil tidak
  /// tertutup tombol ◀ ▶.
  static const jarakDariBawah = 200.0;

  /// Kembali ke posisi awal (tengah bawah).
  void keTengah() {
    position = Vector2(
      (game.size.x / 2) - (size.x / 2),
      game.size.y - jarakDariBawah,
    );
  }

  /// Mobil tertabrak: berhenti, terguncang, gosong, lalu terbakar.
  void tabrakan() {
    if (_terbakar) return;
    _terbakar = true;
    _paint.colorFilter = _filterGosong;

    add(
      MoveByEffect(
        Vector2(6, 0),
        EffectController(duration: 0.04, reverseDuration: 0.04, repeatCount: 6),
      ),
    );
    add(ApiTerbakar(lebar: size.x, random: game.random));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_terbakar) return;
    position.x += game.arahMobil * game.levelConfig.kecepatanPemain * dt;
    position.x = position.x.clamp(0, game.size.x - size.x);
  }

  /// Hapus efek terbakar untuk permainan baru.
  void pulihkan() {
    _terbakar = false;
    _paint.colorFilter = null;
    removeAll(children.where((c) => c is ApiTerbakar || c is Effect));
    keTengah();
  }

  @override
  void render(Canvas canvas) {
    game.gambar.mobil.render(canvas, size, overridePaint: _paint);
  }
}
