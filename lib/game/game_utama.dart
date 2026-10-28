import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'level_config.dart';
import 'meteor.dart';
import 'player.dart';

/// Mengatur dunia game: munculnya meteor, skor, level, dan game over.
class GameUtama extends FlameGame with TapCallbacks, HasCollisionDetection {
  GameUtama({Random? random}) : random = random ?? Random();

  static const overlayHud = 'hud';
  static const overlayLevelSelesai = 'levelSelesai';
  static const overlayGameOver = 'gameOver';

  final Random random;

  /// Didengarkan oleh overlay Flutter (HUD, Level Selesai, Game Over).
  final level = ValueNotifier<int>(1);
  final skor = ValueNotifier<int>(0);
  final dihindariDiLevelIni = ValueNotifier<int>(0);

  late Player _player;
  double _waktuMunculMeteor = 0;
  bool _isGameOver = false;
  bool _menungguLanjut = false;

  bool get isGameOver => _isGameOver;

  /// `true` saat level selesai dan menunggu pemain menekan "Lanjut".
  bool get menungguLanjut => _menungguLanjut;

  LevelConfig get levelConfig => LevelConfig.forLevel(level.value);

  bool get _sedangBermain => !_isGameOver && !_menungguLanjut;

  @override
  Future<void> onLoad() async {
    _player = Player();
    add(_player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_sedangBermain) return;

    _waktuMunculMeteor += dt;
    if (_waktuMunculMeteor > levelConfig.jedaMunculMeteor) {
      add(Meteor());
      _waktuMunculMeteor = 0;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_sedangBermain) return;
    final lokasiKlikX = event.canvasPosition.x;

    // Klik layar kiri = ke kiri, klik layar kanan = ke kanan
    if (lokasiKlikX < size.x / 2) {
      _player.bergerakKeKiri();
    } else {
      _player.bergerakKeKanan();
    }
  }

  /// Dipanggil oleh [Meteor] saat lolos melewati layar bawah.
  void meteorDihindari() {
    if (!_sedangBermain) return;
    skor.value++;
    dihindariDiLevelIni.value++;

    if (dihindariDiLevelIni.value >= LevelConfig.meteorPerLevel) {
      _menungguLanjut = true;
      overlays.add(overlayLevelSelesai);
      pauseEngine();
    }
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

  /// Dipanggil oleh [Meteor] saat mengenai pemain.
  void gameOver() {
    if (!_sedangBermain) return;
    _isGameOver = true;
    overlays.add(overlayGameOver);
    pauseEngine();
  }

  void mainLagi() {
    level.value = 1;
    skor.value = 0;
    _mulaiLevel();
    _player.keTengah();
    _isGameOver = false;
    _menungguLanjut = false;

    overlays
      ..remove(overlayGameOver)
      ..remove(overlayLevelSelesai);
    resumeEngine();
  }

  /// Layar bersih untuk level baru: meteor lama dihapus dan pemain berhenti.
  void _mulaiLevel() {
    removeAll(children.whereType<Meteor>());
    _player.berhenti();
    dihindariDiLevelIni.value = 0;
    _waktuMunculMeteor = 0;
  }

  @override
  void onRemove() {
    level.dispose();
    skor.dispose();
    dihindariDiLevelIni.dispose();
    super.onRemove();
  }
}
