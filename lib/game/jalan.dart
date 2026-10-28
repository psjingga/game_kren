import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';

/// Suasana jalan, berganti setiap level: siang → sore → malam → siang ...
enum Suasana {
  siang(
    rumput: Color(0xFF5DA94F),
    pohon: Color(0xFF2E7D32),
    daun: Color(0xFF43A047),
    aspal: Color(0xFF4A4A4F),
  ),
  sore(
    rumput: Color(0xFF8E9A3E),
    pohon: Color(0xFF55601C),
    daun: Color(0xFF7A8A2A),
    aspal: Color(0xFF4D4545),
  ),
  malam(
    rumput: Color(0xFF1E3A24),
    pohon: Color(0xFF0F2914),
    daun: Color(0xFF1B4D25),
    aspal: Color(0xFF2C2C33),
  );

  const Suasana({
    required this.rumput,
    required this.pohon,
    required this.daun,
    required this.aspal,
  });

  final Color rumput;
  final Color pohon;
  final Color daun;
  final Color aspal;

  static Suasana untukLevel(int level) => values[(level - 1) % values.length];
}

/// Latar jalan aspal di antara rumput berpohon, dengan marka putus-putus.
/// Marka dan pohon bergerak ke bawah secepat jebakan supaya mobil terasa
/// melaju.
class Jalan extends Component with HasGameReference<GameUtama> {
  Jalan() : super(priority: -1);

  static const _panjangMarka = 40.0;
  static const _jarakMarka = 40.0;
  static const _lebarMarka = 6.0;
  static const _jarakPohon = 130.0;

  final _cat = Paint();
  final _bahu = Paint()..color = const Color(0xFFE0E0E0);
  final _marka = Paint()..color = const Color(0xFFF5F5F5);

  double _geserMarka = 0;
  double _geserPohon = 0;

  @override
  void update(double dt) {
    if (game.isGameOver) return; // jalan berhenti saat mobil tertabrak
    final jarak = game.levelConfig.kecepatanJebakan * dt;
    _geserMarka = (_geserMarka + jarak) % (_panjangMarka + _jarakMarka);
    _geserPohon = (_geserPohon + jarak) % _jarakPohon;
  }

  @override
  void render(Canvas canvas) {
    final ukuran = game.size;
    final suasana = game.suasana;
    final kiri = game.batasKiri;
    final kanan = game.batasKanan;

    // Rumput di kedua sisi, lalu aspal di tengah.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ukuran.x, ukuran.y),
      _cat..color = suasana.rumput,
    );
    canvas.drawRect(
      Rect.fromLTRB(kiri, 0, kanan, ukuran.y),
      _cat..color = suasana.aspal,
    );

    _gambarPohon(canvas, kiri / 2, suasana);
    _gambarPohon(canvas, (kanan + ukuran.x) / 2, suasana);

    // Garis tepi jalan.
    canvas.drawRect(Rect.fromLTWH(kiri, 0, 4, ukuran.y), _bahu);
    canvas.drawRect(Rect.fromLTWH(kanan - 4, 0, 4, ukuran.y), _bahu);

    // Marka lajur putus-putus.
    final lebarLajur = (kanan - kiri) / GameUtama.jumlahLajur;
    for (var lajur = 1; lajur < GameUtama.jumlahLajur; lajur++) {
      final x = kiri + lebarLajur * lajur - _lebarMarka / 2;
      for (
        var y = _geserMarka - _panjangMarka;
        y < ukuran.y;
        y += _panjangMarka + _jarakMarka
      ) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, _lebarMarka, _panjangMarka),
          _marka,
        );
      }
    }
  }

  /// Deretan pohon (dilihat dari atas: lingkaran daun) di tengah rumput.
  void _gambarPohon(Canvas canvas, double x, Suasana suasana) {
    final jariJari = (game.batasKiri / 2 - 2).clamp(4.0, 14.0);
    for (
      var y = _geserPohon - _jarakPohon;
      y < game.size.y + jariJari;
      y += _jarakPohon
    ) {
      canvas
        ..drawCircle(Offset(x, y), jariJari, _cat..color = suasana.pohon)
        ..drawCircle(
          Offset(x - jariJari * 0.25, y - jariJari * 0.25),
          jariJari * 0.6,
          _cat..color = suasana.daun,
        );
    }
  }
}

/// Lapisan cahaya di atas jalan: rona jingga saat sore, gelap dengan sorot
/// lampu mobil saat malam. Hanya visual; tidak memengaruhi tabrakan.
class LapisanSuasana extends Component with HasGameReference<GameUtama> {
  LapisanSuasana() : super(priority: 15);

  static const _panjangSorot = 320.0;

  static final _jingga = Paint()..color = const Color(0x22FF8F00);
  static final _gelap = Paint()..color = const Color(0x99000814);

  @override
  void render(Canvas canvas) {
    final layar = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    switch (game.suasana) {
      case Suasana.siang:
        return;
      case Suasana.sore:
        canvas.drawRect(layar, _jingga);
      case Suasana.malam:
        _gambarMalam(canvas, layar);
    }
  }

  void _gambarMalam(Canvas canvas, Rect layar) {
    final mobil = game.kotakMobil;
    final depan = mobil.top;
    final tengah = mobil.center.dx;

    canvas.saveLayer(layar, Paint());
    canvas.drawRect(layar, _gelap);

    // Sorot lampu: trapesium yang makin pudar ke depan, "dilubangi" dari
    // lapisan gelap dengan BlendMode.dstOut.
    final sorot = Path()
      ..moveTo(tengah - 18, depan)
      ..lineTo(tengah + 18, depan)
      ..lineTo(tengah + 95, depan - _panjangSorot)
      ..lineTo(tengah - 95, depan - _panjangSorot)
      ..close();
    canvas.drawPath(
      sorot,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader =
            LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.white, Colors.white.withValues(alpha: 0)],
            ).createShader(
              Rect.fromLTRB(
                tengah - 95,
                depan - _panjangSorot,
                tengah + 95,
                depan,
              ),
            ),
    );

    // Mobil sendiri tetap terlihat.
    canvas.drawCircle(
      mobil.center,
      mobil.height * 0.75,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader =
            RadialGradient(
              colors: [Colors.white, Colors.white.withValues(alpha: 0)],
            ).createShader(
              Rect.fromCircle(
                center: mobil.center,
                radius: mobil.height * 0.75,
              ),
            ),
    );
    canvas.restore();
  }
}
