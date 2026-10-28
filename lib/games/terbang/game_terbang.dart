import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bersama/dompet.dart';
import '../../bersama/penyimpanan.dart';

enum StatusTerbang { siap, main, kalah }

/// Terbang Kren: ketuk untuk mengepakkan sayap dan terbang melewati celah
/// pipa. Makin tinggi skor, pipa makin cepat dan celah makin sempit.
class GameTerbang extends FlameGame with TapCallbacks, HasCollisionDetection {
  GameTerbang({
    required this.penyimpanan,
    required this.dompet,
    this.onKalah,
    Random? random,
  }) : random = random ?? Random();

  static const overlaySiap = 'siap';
  static const overlayHud = 'hud';
  static const overlayKalah = 'kalah';

  static const gravitasi = 1100.0;
  static const kepakan = -380.0;
  static const tinggiTanah = 72.0;
  static const lebarPipa = 64.0;

  /// Jarak antar pipa (piksel), tetap; pipa makin cepat sehingga makin rapat
  /// dalam waktu.
  static const jarakPipa = 240.0;

  /// Lama jatuh setelah menabrak sebelum layar kalah muncul (detik).
  static const jedaKalah = 0.7;

  final Penyimpanan penyimpanan;
  final Dompet dompet;
  final Random random;

  /// Dipanggil saat layar kalah muncul (misalnya untuk iklan layar penuh).
  final VoidCallback? onKalah;

  final skor = ValueNotifier<int>(0);
  final koin = ValueNotifier<int>(0);
  late final rekor = ValueNotifier<int>(
    penyimpanan.bacaInt(KunciSimpan.rekorTerbang) ?? 0,
  );
  bool _rekorBaru = false;

  StatusTerbang _status = StatusTerbang.siap;
  late final Burung burung;
  double _jarakSejakPipa = 0;

  StatusTerbang get status => _status;
  bool get rekorBaru => _rekorBaru;
  double get batasTanah => size.y - tinggiTanah;

  /// Kecepatan dunia bergerak ke kiri (piksel/detik).
  double get kecepatan => min(170 + skor.value * 4.0, 280);

  /// Tinggi celah antar pipa atas & bawah.
  double get tinggiCelah => max(165 - skor.value * 2.0, 120);

  @override
  Future<void> onLoad() async {
    add(Langit());
    burung = Burung();
    add(burung);
    add(Tanah());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_status != StatusTerbang.main) return;
    _jarakSejakPipa += kecepatan * dt;
    if (_jarakSejakPipa >= jarakPipa) {
      _jarakSejakPipa = 0;
      _munculkanPipa();
    }
  }

  void _munculkanPipa() {
    final celah = tinggiCelah;
    final atas = 70 + celah / 2;
    final bawah = batasTanah - 70 - celah / 2;
    final tengah = atas + random.nextDouble() * max(bawah - atas, 0);
    add(PasanganPipa(tengahCelah: tengah, tinggiCelah: celah));
    if (random.nextDouble() < 0.45) {
      add(KoinTerbang(Vector2(size.x + lebarPipa / 2, tengah)));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    switch (_status) {
      case StatusTerbang.siap:
        mulai();
      case StatusTerbang.main:
        burung.kepak();
      case StatusTerbang.kalah:
        break; // pakai tombol di layar kalah
    }
  }

  void mulai() {
    if (_status != StatusTerbang.siap) return;
    _status = StatusTerbang.main;
    overlays
      ..remove(overlaySiap)
      ..add(overlayHud);
    // Pipa pertama muncul tak lama setelah mulai.
    _jarakSejakPipa = jarakPipa * 0.4;
    burung.kepak();
  }

  /// Dipanggil oleh [PasanganPipa] saat burung melewatinya.
  void lewatPipa() {
    if (_status != StatusTerbang.main) return;
    skor.value++;
    HapticFeedback.selectionClick();
  }

  /// Dipanggil oleh [KoinTerbang] saat diambil burung.
  void ambilKoin() {
    if (_status != StatusTerbang.main) return;
    koin.value++;
  }

  /// Burung menabrak pipa atau tanah.
  void kalah() {
    if (_status != StatusTerbang.main) return;
    _status = StatusTerbang.kalah;
    HapticFeedback.heavyImpact();

    _rekorBaru = skor.value > rekor.value;
    if (_rekorBaru) {
      rekor.value = skor.value;
      penyimpanan.tulisInt(KunciSimpan.rekorTerbang, rekor.value);
    }
    dompet.tambah(koin.value);

    add(
      TimerComponent(
        period: jedaKalah,
        removeOnFinish: true,
        onTick: () {
          overlays
            ..remove(overlayHud)
            ..add(overlayKalah);
          onKalah?.call();
        },
      ),
    );
  }

  void mainLagi() {
    removeAll(children.whereType<PasanganPipa>());
    removeAll(children.whereType<KoinTerbang>());
    removeAll(children.whereType<TimerComponent>());
    skor.value = 0;
    koin.value = 0;
    _rekorBaru = false;
    burung.keAwal();
    _status = StatusTerbang.siap;
    overlays
      ..remove(overlayKalah)
      ..remove(overlayHud)
      ..add(overlaySiap);
  }

  /// Ditutup di tengah permainan: koin yang sudah diambil tetap disimpan.
  void simpanSebelumKeluar() {
    if (_status == StatusTerbang.main) dompet.tambah(koin.value);
  }

  @override
  void onRemove() {
    skor.dispose();
    koin.dispose();
    rekor.dispose();
    super.onRemove();
  }
}

/// Burung kuning bersayap. Jatuh karena gravitasi, naik saat dikepakkan.
class Burung extends PositionComponent
    with HasGameReference<GameTerbang>, CollisionCallbacks {
  Burung() : super(size: Vector2(46, 36), anchor: Anchor.center);

  double kecepatanY = 0;
  double _waktu = 0;

  static final _badan = Paint()..color = const Color(0xFFFFD54F);
  static final _perut = Paint()..color = const Color(0xFFFFF59D);
  static final _sayap = Paint()..color = const Color(0xFFFFB300);
  static final _mataPutih = Paint()..color = Colors.white;
  static final _mataHitam = Paint()..color = Colors.black;
  static final _paruh = Paint()..color = const Color(0xFFFF7043);
  static final _garis = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
    // Hitbox sedikit lebih kecil dari gambar supaya serempetan tidak kena.
    add(CircleHitbox(radius: 14, position: size / 2, anchor: Anchor.center));
  }

  @override
  void onMount() {
    super.onMount();
    keAwal();
  }

  void keAwal() {
    position = Vector2(game.size.x * 0.3, game.batasTanah * 0.45);
    kecepatanY = 0;
    angle = 0;
  }

  void kepak() => kecepatanY = GameTerbang.kepakan;

  @override
  void update(double dt) {
    super.update(dt);
    _waktu += dt;
    switch (game.status) {
      case StatusTerbang.siap:
        // Melayang naik-turun menunggu ketukan pertama.
        position.y = game.batasTanah * 0.45 + sin(_waktu * 4) * 8;
        return;
      case StatusTerbang.main:
      case StatusTerbang.kalah:
        kecepatanY += GameTerbang.gravitasi * dt;
        position.y += kecepatanY * dt;
        // Menengadah saat naik, menukik saat jatuh.
        angle = (kecepatanY / 600).clamp(-0.45, 1.3);
    }

    if (position.y < size.y / 2) {
      position.y = size.y / 2;
      kecepatanY = 0;
    }
    if (position.y + size.y / 2 >= game.batasTanah) {
      position.y = game.batasTanah - size.y / 2;
      kecepatanY = 0;
      game.kalah();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PasanganPipa) game.kalah();
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    canvas
      ..drawOval(Rect.fromLTWH(2, 2, w - 8, h - 4), _badan)
      ..drawOval(Rect.fromLTWH(10, h * 0.5, w * 0.5, h * 0.42), _perut)
      ..drawOval(Rect.fromLTWH(2, 2, w - 8, h - 4), _garis);

    // Sayap mengepak naik-turun.
    final kepak = game.status == StatusTerbang.kalah ? 0.0 : sin(_waktu * 22);
    canvas
      ..save()
      ..translate(14, h * 0.5)
      ..scale(1, 0.6 + 0.4 * kepak.abs())
      ..drawOval(const Rect.fromLTWH(-12, -8, 20, 14), _sayap)
      ..drawOval(const Rect.fromLTWH(-12, -8, 20, 14), _garis)
      ..restore();

    canvas
      ..drawCircle(Offset(w * 0.66, h * 0.32), 7, _mataPutih)
      ..drawCircle(Offset(w * 0.66, h * 0.32), 7, _garis)
      ..drawCircle(Offset(w * 0.7, h * 0.32), 3, _mataHitam);

    final paruh = Path()
      ..moveTo(w - 10, h * 0.45)
      ..lineTo(w + 2, h * 0.55)
      ..lineTo(w - 10, h * 0.66)
      ..close();
    canvas
      ..drawPath(paruh, _paruh)
      ..drawPath(paruh, _garis);
  }
}

/// Pipa atas & bawah dengan celah di antaranya, bergerak ke kiri.
class PasanganPipa extends PositionComponent
    with HasGameReference<GameTerbang> {
  PasanganPipa({required this.tengahCelah, required this.tinggiCelah});

  final double tengahCelah;
  final double tinggiCelah;
  bool _sudahDilewati = false;

  static const _tinggiTutup = 26.0;
  static const _lebihTutup = 5.0;

  static final _pipa = Paint()..color = const Color(0xFF66BB6A);
  static final _kilau = Paint()..color = const Color(0xFFA5D6A7);
  static final _tepi = Paint()
    ..color = const Color(0xFF1B5E20)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  double get _bawahAtas => tengahCelah - tinggiCelah / 2;
  double get _atasBawah => tengahCelah + tinggiCelah / 2;

  @override
  Future<void> onLoad() async {
    size = Vector2(GameTerbang.lebarPipa, game.batasTanah);
    position = Vector2(game.size.x, 0);
    add(
      RectangleHitbox(
        position: Vector2.zero(),
        size: Vector2(size.x, _bawahAtas),
      ),
    );
    add(
      RectangleHitbox(
        position: Vector2(0, _atasBawah),
        size: Vector2(size.x, game.batasTanah - _atasBawah),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.status != StatusTerbang.main) return;
    position.x -= game.kecepatan * dt;
    if (!_sudahDilewati && position.x + size.x < game.burung.position.x) {
      _sudahDilewati = true;
      game.lewatPipa();
    }
    if (position.x + size.x < -_lebihTutup) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    _gambarPipa(canvas, 0, _bawahAtas, tutupDiBawah: true);
    _gambarPipa(canvas, _atasBawah, size.y, tutupDiBawah: false);
  }

  void _gambarPipa(
    Canvas canvas,
    double atas,
    double bawah, {
    required bool tutupDiBawah,
  }) {
    final badan = Rect.fromLTRB(4, atas, size.x - 4, bawah);
    canvas
      ..drawRect(badan, _pipa)
      ..drawRect(Rect.fromLTWH(12, atas, 8, bawah - atas), _kilau)
      ..drawRect(badan, _tepi);
    final yTutup = tutupDiBawah ? bawah - _tinggiTutup : atas;
    final tutup = Rect.fromLTWH(
      -_lebihTutup + 4,
      yTutup,
      size.x + _lebihTutup * 2 - 8,
      _tinggiTutup,
    );
    canvas
      ..drawRect(tutup, _pipa)
      ..drawRect(tutup, _tepi);
  }
}

/// Koin di tengah celah pipa.
class KoinTerbang extends PositionComponent
    with HasGameReference<GameTerbang>, CollisionCallbacks {
  KoinTerbang(Vector2 posisi)
    : super(position: posisi, size: Vector2.all(26), anchor: Anchor.center);

  static final _emas = Paint()..color = const Color(0xFFFFC107);
  static final _tepi = Paint()
    ..color = const Color(0xFFFF8F00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  Future<void> onLoad() async => add(CircleHitbox());

  @override
  void update(double dt) {
    super.update(dt);
    if (game.status != StatusTerbang.main) return;
    position.x -= game.kecepatan * dt;
    if (position.x < -size.x) removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Burung) {
      game.ambilKoin();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    canvas
      ..drawCircle(Offset(r, r), r, _emas)
      ..drawCircle(Offset(r, r), r - 1.5, _tepi)
      ..drawCircle(Offset(r, r), r * 0.5, _tepi);
  }
}

/// Langit biru bergradasi dengan awan yang bergeser pelan.
class Langit extends Component with HasGameReference<GameTerbang> {
  Langit() : super(priority: -2);

  static final _awan = Paint()..color = const Color(0xCCFFFFFF);
  double _geser = 0;

  @override
  void update(double dt) {
    if (game.status != StatusTerbang.kalah) _geser += 20 * dt;
  }

  @override
  void render(Canvas canvas) {
    final layar = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    canvas.drawRect(
      layar,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
        ).createShader(layar),
    );
    final lebar = game.size.x + 160;
    for (var i = 0; i < 4; i++) {
      final x = (i * 140 - _geser * (1 + i % 2 * 0.5)) % lebar - 80;
      final y = 60.0 + i * 90 % 260;
      canvas
        ..drawOval(Rect.fromLTWH(x, y, 90, 30), _awan)
        ..drawOval(Rect.fromLTWH(x + 25, y - 14, 50, 32), _awan);
    }
  }
}

/// Tanah bergaris yang bergerak secepat pipa.
class Tanah extends Component with HasGameReference<GameTerbang> {
  Tanah() : super(priority: 5);

  static final _rumput = Paint()..color = const Color(0xFF7CB342);
  static final _tanah = Paint()..color = const Color(0xFFDED895);
  static final _garis = Paint()..color = const Color(0xFFC5BC6E);
  double _geser = 0;

  @override
  void update(double dt) {
    if (game.status != StatusTerbang.kalah) {
      _geser = (_geser + game.kecepatan * dt) % 24;
    }
  }

  @override
  void render(Canvas canvas) {
    final y = game.batasTanah;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, y, game.size.x, GameTerbang.tinggiTanah),
        _tanah,
      )
      ..drawRect(Rect.fromLTWH(0, y, game.size.x, 14), _rumput);
    for (var x = -_geser; x < game.size.x; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, y + 22, 12, 6), _garis);
    }
  }
}
