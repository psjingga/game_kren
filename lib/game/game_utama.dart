import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'efek_crash.dart';
import 'gambar_game.dart';
import 'jalan.dart';
import 'jebakan.dart';
import 'level_config.dart';
import 'player.dart';

/// Mengatur dunia game: munculnya jebakan, skor, level, dan game over.
class GameUtama extends FlameGame with DragCallbacks, HasCollisionDetection {
  GameUtama({Random? random, this.onGameOver}) : random = random ?? Random();

  static const overlayHud = 'hud';
  static const overlayLevelSelesai = 'levelSelesai';
  static const overlayGameOver = 'gameOver';

  /// Lama efek tabrakan & terbakar sebelum layar Game Over muncul (detik).
  static const jedaGameOver = 1.2;

  final Random random;

  /// Dipanggil saat layar Game Over muncul (misalnya untuk iklan layar
  /// penuh). Game sendiri tidak tahu apa-apa soal iklan.
  final VoidCallback? onGameOver;

  /// Didengarkan oleh overlay Flutter (HUD, Level Selesai, Game Over).
  final level = ValueNotifier<int>(1);
  final skor = ValueNotifier<int>(0);
  final dihindariDiLevelIni = ValueNotifier<int>(0);

  /// Sisa waktu level dalam detik (dibulatkan ke atas) untuk HUD.
  final sisaDetik = ValueNotifier<int>(LevelConfig.durasiLevel.ceil());

  late final GambarGame gambar;
  late Player _player;
  double _waktuMunculJebakan = 0;
  double _waktuLevel = 0;
  bool _isGameOver = false;
  bool _menungguLanjut = false;

  bool get isGameOver => _isGameOver;

  /// `true` saat level selesai dan menunggu pemain menekan "Lanjut".
  bool get menungguLanjut => _menungguLanjut;

  LevelConfig get levelConfig => LevelConfig.forLevel(level.value);

  bool get _sedangBermain => !_isGameOver && !_menungguLanjut;

  @override
  Future<void> onLoad() async {
    gambar = await GambarGame.muat();
    add(Jalan());
    _player = Player();
    add(_player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_sedangBermain) return;

    _waktuLevel += dt;
    final sisa = LevelConfig.durasiLevel - _waktuLevel;
    sisaDetik.value = max(sisa, 0).ceil();
    if (sisa <= 0) {
      _levelSelesai();
      return;
    }

    _waktuMunculJebakan += dt;
    if (_waktuMunculJebakan > levelConfig.jedaMunculJebakan) {
      add(Jebakan());
      _waktuMunculJebakan = 0;
    }
  }

  /// Mobil mengikuti gerak jari ke kiri/kanan. Jari bisa diletakkan di mana
  /// saja di layar, jadi mobil tidak tertutup jari.
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_sedangBermain) return;
    _player.geser(event.localDelta.x);
  }

  /// Dipanggil oleh [Jebakan] saat lolos melewati layar bawah.
  void jebakanDihindari() {
    if (!_sedangBermain) return;
    skor.value++;
    dihindariDiLevelIni.value++;
  }

  /// Waktu level habis dan pemain masih selamat.
  void _levelSelesai() {
    _menungguLanjut = true;
    overlays.add(overlayLevelSelesai);
    pauseEngine();
  }

  /// Dipanggil dari tombol "Lanjut" di layar Level Selesai.
  void lanjutLevel() {
    if (!_menungguLanjut) return;
    level.value++;
    _mulaiLevel();
    overlays.remove(overlayLevelSelesai);
    _menungguLanjut = false;
    resumeEngine();
  }

  /// Dipanggil oleh [Jebakan] saat mengenai pemain.
  ///
  /// Mobil meledak dan terbakar dulu; layar Game Over muncul setelah
  /// [jedaGameOver] detik. Game tidak di-pause supaya api tetap menyala.
  void gameOver({Vector2? titikTabrakan}) {
    if (!_sedangBermain) return;
    _isGameOver = true;

    _player.tabrakan();
    add(buatLedakan(titikTabrakan ?? _player.center, random));
    HapticFeedback.heavyImpact();
    add(
      TimerComponent(
        period: jedaGameOver,
        removeOnFinish: true,
        onTick: () {
          overlays.add(overlayGameOver);
          onGameOver?.call();
        },
      ),
    );
  }

  void mainLagi() {
    level.value = 1;
    skor.value = 0;
    _mulaiLevel();
    removeAll(children.whereType<ParticleSystemComponent>());
    _player.pulihkan();
    _isGameOver = false;
    _menungguLanjut = false;

    overlays
      ..remove(overlayGameOver)
      ..remove(overlayLevelSelesai);
    resumeEngine();
  }

  /// Layar bersih untuk level baru: jebakan lama dihapus.
  void _mulaiLevel() {
    removeAll(children.whereType<Jebakan>());
    dihindariDiLevelIni.value = 0;
    _waktuMunculJebakan = 0;
    _waktuLevel = 0;
    sisaDetik.value = LevelConfig.durasiLevel.ceil();
  }

  @override
  void onRemove() {
    level.dispose();
    skor.dispose();
    dihindariDiLevelIni.dispose();
    sisaDetik.dispose();
    super.onRemove();
  }
}
