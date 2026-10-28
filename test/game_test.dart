import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/level_config.dart';
import 'package:game_kren_kamu/game/meteor.dart';
import 'package:game_kren_kamu/game/player.dart';
import 'package:game_kren_kamu/layar_game.dart';

/// Game dengan random tetap dan overlay terdaftar (tanpa GameWidget, Flame
/// menolak membuka overlay yang belum punya builder).
GameUtama _buatGame() {
  final game = GameUtama(random: Random(1));
  for (final nama in [
    GameUtama.overlayHud,
    GameUtama.overlayLevelSelesai,
    GameUtama.overlayGameOver,
  ]) {
    game.overlays.addEntry(nama, (_, _) => const SizedBox());
  }
  return game;
}

Iterable<Meteor> _meteor(GameUtama game) => game.children.whereType<Meteor>();

Player _player(GameUtama game) => game.children.whereType<Player>().single;

void main() {
  testWithGame<GameUtama>('pemain muncul di tengah bawah', _buatGame, (
    game,
  ) async {
    final player = _player(game);
    expect(
      player.position,
      Vector2(game.size.x / 2 - player.size.x / 2, game.size.y - 120),
    );
  });

  testWithGame<GameUtama>(
    'meteor pertama muncul setelah 1,5 detik',
    _buatGame,
    (game) async {
      game.update(1.4);
      await game.ready();
      expect(_meteor(game), isEmpty);

      game.update(0.2);
      await game.ready();
      expect(_meteor(game), hasLength(1));
    },
  );

  testWithGame<GameUtama>(
    'meteor yang lolos ke bawah menambah skor lalu dihapus',
    _buatGame,
    (game) async {
      final meteor = Meteor(x: 0); // jauh dari pemain di tengah
      await game.add(meteor);
      await game.ready();

      // 250 px/detik dari y = -50 butuh lebih dari 2,6 detik melewati y = 600.
      for (var i = 0; i < 27; i++) {
        game.update(0.1);
      }
      await game.ready();

      expect(meteor.isMounted, isFalse);
      expect(game.skor.value, greaterThanOrEqualTo(1));
    },
  );

  testWithGame<GameUtama>(
    'level selesai setelah ${LevelConfig.meteorPerLevel} meteor: game berhenti '
    'dan menunggu tombol lanjut',
    _buatGame,
    (game) async {
      for (var i = 0; i < LevelConfig.meteorPerLevel - 1; i++) {
        game.meteorDihindari();
      }
      expect(game.menungguLanjut, isFalse);

      game.meteorDihindari();
      expect(game.menungguLanjut, isTrue);
      expect(game.paused, isTrue);
      expect(game.level.value, 1, reason: 'level naik saat tombol lanjut');
      expect(game.overlays.isActive(GameUtama.overlayLevelSelesai), isTrue);

      // Meteor lain yang lolos di frame yang sama tidak dihitung.
      game.meteorDihindari();
      expect(game.skor.value, LevelConfig.meteorPerLevel);
    },
  );

  testWithGame<GameUtama>(
    'lanjut level menaikkan level, membersihkan layar, dan main lagi',
    _buatGame,
    (game) async {
      await game.add(Meteor(x: 0));
      await game.ready();
      for (var i = 0; i < LevelConfig.meteorPerLevel; i++) {
        game.meteorDihindari();
      }

      game.lanjutLevel();
      await game.ready();

      expect(game.level.value, 2);
      expect(game.dihindariDiLevelIni.value, 0);
      expect(game.skor.value, LevelConfig.meteorPerLevel);
      expect(game.menungguLanjut, isFalse);
      expect(game.paused, isFalse);
      expect(_meteor(game), isEmpty);
      expect(game.overlays.isActive(GameUtama.overlayLevelSelesai), isFalse);
    },
  );

  testWithGame<GameUtama>(
    'meteor baru di level 2 jatuh lebih cepat',
    _buatGame,
    (game) async {
      for (var i = 0; i < LevelConfig.meteorPerLevel; i++) {
        game.meteorDihindari();
      }
      game.lanjutLevel();

      final meteor = Meteor(x: 0);
      await game.add(meteor);
      await game.ready();
      final yAwal = meteor.position.y;
      game.update(1);

      expect(meteor.position.y - yAwal, closeTo(287.5, 0.001));
    },
  );

  testWithGame<GameUtama>('pemain di level 2 bergerak lebih cepat', _buatGame, (
    game,
  ) async {
    final player = _player(game);
    player.bergerakKeKanan();
    final xAwal = player.position.x;
    game.update(0.1);
    final jarakLevel1 = player.position.x - xAwal;

    for (var i = 0; i < LevelConfig.meteorPerLevel; i++) {
      game.meteorDihindari();
    }
    game.lanjutLevel();
    player.position.x = 0;
    player.bergerakKeKanan();
    game.update(0.1);

    expect(jarakLevel1, closeTo(20, 0.001));
    expect(player.position.x, closeTo(23, 0.001));
  });

  testWithGame<GameUtama>(
    'meteor yang kena pemain membuat game over',
    _buatGame,
    (game) async {
      final player = _player(game);
      final meteor = Meteor(x: player.position.x + 10);
      await game.add(meteor);
      await game.ready();
      meteor.position.y = player.position.y + 5;

      game.update(0.016);

      expect(game.isGameOver, isTrue);
      expect(game.paused, isTrue);
      expect(game.overlays.isActive(GameUtama.overlayGameOver), isTrue);
    },
  );

  testWithGame<GameUtama>('main lagi mengembalikan game ke awal', _buatGame, (
    game,
  ) async {
    for (var i = 0; i < 15; i++) {
      game.meteorDihindari();
    }
    await game.add(Meteor(x: 0));
    await game.ready();
    game.gameOver();

    game.mainLagi();
    await game.ready();

    expect(game.isGameOver, isFalse);
    expect(game.paused, isFalse);
    expect(game.level.value, 1);
    expect(game.skor.value, 0);
    expect(_meteor(game), isEmpty);
    expect(game.overlays.isActive(GameUtama.overlayGameOver), isFalse);
  });

  testWidgets('ketuk kanan menggerakkan pemain ke kanan, kiri ke kiri', (
    tester,
  ) async {
    final game = _buatGame();
    await tester.pumpWidget(
      Center(
        child: SizedBox(width: 400, height: 800, child: GameWidget(game: game)),
      ),
    );
    await tester.pump();
    await tester.pump();

    final player = _player(game);
    final xAwal = player.position.x;
    final kotak = tester.getRect(find.byType(GameWidget<GameUtama>));

    await tester.tapAt(kotak.centerRight - const Offset(20, 0));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(player.position.x, greaterThan(xAwal));

    final xSetelahKanan = player.position.x;
    await tester.tapAt(kotak.centerLeft + const Offset(20, 0));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(player.position.x, lessThan(xSetelahKanan));
  });

  testWidgets('LayarGame menampilkan level dan skor', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LayarGame(showAds: false)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameWidget<GameUtama>), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Skor 0'), findsOneWidget);
  });
}
