import 'dart:math';

import 'package:flutter/material.dart';

import 'barang_ambilan.dart';

enum JenisPowerUp {
  /// Kebal satu kali tabrakan.
  perisai(emoji: '🛡️', warna: Color(0xFF26C6DA)),

  /// Koin di dekat mobil tertarik selama [StatusPowerUp.lamaMagnet] detik.
  magnet(emoji: '🧲', warna: Color(0xFFEF5350)),

  /// Setiap koin bernilai 2 selama [StatusPowerUp.lamaKoinGanda] detik.
  koinGanda(emoji: '×2', warna: Color(0xFFFFB300));

  const JenisPowerUp({required this.emoji, required this.warna});

  final String emoji;
  final Color warna;
}

/// Power-up yang jatuh di jalan, diambil seperti koin.
class PowerUp extends BarangAmbilan {
  PowerUp(this.jenis, {super.x}) : super(ukuran: 38);

  final JenisPowerUp jenis;
  late final TextPainter _ikon;
  double _waktu = 0;

  @override
  void onMount() {
    super.onMount();
    _ikon = TextPainter(
      text: TextSpan(
        text: jenis.emoji,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _waktu += dt;
  }

  @override
  void diambil() => game.ambilPowerUp(jenis);

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final pusat = Offset(r, r);
    // Cahaya berdenyut supaya menonjol dari koin.
    final denyut = 0.5 + 0.5 * sin(_waktu * 8);
    canvas.drawCircle(
      pusat,
      r + 3 * denyut,
      Paint()..color = jenis.warna.withValues(alpha: 0.35),
    );
    canvas.drawCircle(pusat, r - 2, Paint()..color = jenis.warna);
    canvas.drawCircle(
      pusat,
      r - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    _ikon.paint(canvas, pusat - Offset(_ikon.width / 2, _ikon.height / 2));
  }
}

/// Power-up yang sedang aktif. Waktu tersisa dibulatkan ke detik untuk HUD
/// supaya HUD tidak digambar ulang setiap frame.
class StatusPowerUp {
  static const lamaMagnet = 6.0;
  static const lamaKoinGanda = 10.0;

  final perisai = ValueNotifier<bool>(false);
  final detikMagnet = ValueNotifier<int>(0);
  final detikKoinGanda = ValueNotifier<int>(0);

  double _sisaMagnet = 0;
  double _sisaKoinGanda = 0;

  bool get magnetAktif => _sisaMagnet > 0;
  bool get koinGandaAktif => _sisaKoinGanda > 0;

  void aktifkan(JenisPowerUp jenis) {
    switch (jenis) {
      case JenisPowerUp.perisai:
        perisai.value = true;
      case JenisPowerUp.magnet:
        _sisaMagnet = lamaMagnet;
      case JenisPowerUp.koinGanda:
        _sisaKoinGanda = lamaKoinGanda;
    }
    _perbaruiDetik();
  }

  void update(double dt) {
    if (!magnetAktif && !koinGandaAktif) return;
    _sisaMagnet = max(_sisaMagnet - dt, 0);
    _sisaKoinGanda = max(_sisaKoinGanda - dt, 0);
    _perbaruiDetik();
  }

  /// Perisai menahan satu tabrakan lalu hilang.
  bool pakaiPerisai() {
    if (!perisai.value) return false;
    perisai.value = false;
    return true;
  }

  void reset() {
    perisai.value = false;
    _sisaMagnet = 0;
    _sisaKoinGanda = 0;
    _perbaruiDetik();
  }

  void _perbaruiDetik() {
    detikMagnet.value = _sisaMagnet.ceil();
    detikKoinGanda.value = _sisaKoinGanda.ceil();
  }

  void dispose() {
    perisai.dispose();
    detikMagnet.dispose();
    detikKoinGanda.dispose();
  }
}
