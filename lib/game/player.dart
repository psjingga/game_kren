import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

import 'efek_crash.dart';
import 'game_utama.dart';

/// Mobil pemain dilihat dari atas, bergambar mobil yang dipakai di garasi.
class Player extends PositionComponent with HasGameReference<GameUtama> {
  Player() {
    size = Vector2(52, 80);
  }

  /// Warna gosong ditimpakan ke gambar mobil setelah tertabrak.
  static const _filterGosong = ColorFilter.mode(
    Color(0xCC2B1B12),
    BlendMode.srcATop,
  );

  static const _insetX = 6.0;
  static const _insetY = 4.0;

  /// Lama mobil selip setelah melindas oli (detik).
  static const lamaSelip = 0.8;

  static final _gelembung = Paint()
    ..color = const Color(0x4026C6DA)
    ..style = PaintingStyle.fill;
  static final _tepiGelembung = Paint()
    ..color = const Color(0xFF80DEEA)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final _paint = Paint()..filterQuality = FilterQuality.medium;
  bool _terbakar = false;
  double _sisaSelip = 0;
  double _arahSelip = 0;

  bool get terbakar => _terbakar;
  bool get selip => _sisaSelip > 0;

  /// Kotak tabrakan di koordinat layar (sama dengan hitbox).
  Rect get kotakTabrak => Rect.fromLTWH(
    position.x + _insetX,
    position.y + _insetY,
    size.x - _insetX * 2,
    size.y - _insetY * 2,
  );

  @override
  Future<void> onLoad() async {
    // Hitbox sedikit lebih kecil dari gambar supaya tabrakan terasa adil.
    // Solid: jebakan yang sudah berada di dalam mobil tetap terhitung kena.
    add(
      RectangleHitbox(
        position: Vector2(_insetX, _insetY),
        size: Vector2(size.x - _insetX * 2, size.y - _insetY * 2),
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

  /// Melindas oli: tergelincir ke samping (arah acak) dan berputar
  /// sebentar; tombol setir tidak berpengaruh selama selip.
  void mulaiSelip() {
    if (_terbakar) return;
    _sisaSelip = lamaSelip;
    _arahSelip = game.random.nextBool() ? 1 : -1;
  }

  /// Mobil tertabrak: berhenti, terguncang, gosong, lalu terbakar.
  void tabrakan() {
    if (_terbakar) return;
    _terbakar = true;
    _sisaSelip = 0;
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
    final kecepatan = game.levelConfig.kecepatanPemain;
    if (selip) {
      _sisaSelip = max(_sisaSelip - dt, 0);
      position.x += _arahSelip * kecepatan * 0.8 * dt;
    } else {
      position.x += game.arahMobil * kecepatan * dt;
    }
    position.x = position.x.clamp(game.batasKiri, game.batasKanan - size.x);
  }

  /// Hapus efek terbakar untuk permainan baru.
  void pulihkan() {
    _terbakar = false;
    _sisaSelip = 0;
    _paint.colorFilter = null;
    removeAll(children.where((c) => c is ApiTerbakar || c is Effect));
    keTengah();
  }

  @override
  void render(Canvas canvas) {
    final pusat = (size / 2).toOffset();
    canvas.save();
    if (selip) {
      // Berputar bolak-balik di sekitar titik tengah mobil.
      final waktu = lamaSelip - _sisaSelip;
      canvas
        ..translate(pusat.dx, pusat.dy)
        ..rotate(sin(waktu * 25) * 0.35)
        ..translate(-pusat.dx, -pusat.dy);
    }
    final gambar = game.gambar.mobil[game.garasi.dipakai.value]!;
    gambar.render(canvas, size, overridePaint: _paint);
    canvas.restore();

    if (game.status.perisai.value) {
      final r = size.y / 2 + 6;
      canvas
        ..drawCircle(pusat, r, _gelembung)
        ..drawCircle(pusat, r, _tepiGelembung);
    }
  }
}
