import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/efek_crash.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/level_config.dart';
import 'package:game_kren_kamu/game/jebakan.dart';
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

Iterable<Jebakan> _jebakan(GameUtama game) =>
    game.children.whereType<Jebakan>();

/// Melompati waktu sampai level selesai.
void _selesaikanLevel(GameUtama game) => game.update(LevelConfig.durasiLevel);

Player _player(GameUtama game) => game.children.whereType<Player>().single;

/// Versi untuk testWidgets: pemuatan gambar butuh async sungguhan.
Future<void> _tungguGambar(WidgetTester tester, GameUtama game) async {
  await tester.runAsync(() async {
    await game.loaded;
    await game.ready();
  });
  await tester.pump();
}

/// Menunggu gambar dimuat dan mobil terpasang.
Future<Player> _playerSiap(GameUtama game) async {
  await game.ready();
  return _player(game);
}

void main() {
  testWithGame<GameUtama>('pemain muncul di tengah bawah', _buatGame, (
    game,
  ) async {
    final player = await _playerSiap(game);
    expect(
      player.position,
      Vector2(game.size.x / 2 - player.size.x / 2, game.size.y - 120),
    );
  });

  testWithGame<GameUtama>(
    'jebakan pertama muncul setelah 1,5 detik',
    _buatGame,
    (game) async {
      game.update(1.4);
      await game.ready();
      expect(_jebakan(game), isEmpty);

      game.update(0.2);
      await game.ready();
      expect(_jebakan(game), hasLength(1));
    },
  );

  testWithGame<GameUtama>(
    'jebakan yang lolos ke bawah menambah skor lalu dihapus',
    _buatGame,
    (game) async {
      final jebakan = Jebakan(x: 0); // jauh dari pemain di tengah
      await game.add(jebakan);
      await game.ready();

      // 250 px/detik dari y = -50 butuh lebih dari 2,6 detik melewati y = 600.
      for (var i = 0; i < 27; i++) {
        game.update(0.1);
      }
      await game.ready();

      expect(jebakan.isMounted, isFalse);
      expect(game.skor.value, greaterThanOrEqualTo(1));
    },
  );

  testWithGame<GameUtama>(
    'level selesai setelah ${LevelConfig.durasiLevel.toInt()} detik: game '
    'berhenti dan menunggu tombol lanjut',
    _buatGame,
    (game) async {
      expect(game.sisaDetik.value, LevelConfig.durasiLevel.toInt());

      game.update(LevelConfig.durasiLevel - 1);
      expect(game.menungguLanjut, isFalse);
      expect(game.sisaDetik.value, 1);

      game.update(1);
      expect(game.menungguLanjut, isTrue);
      expect(game.paused, isTrue);
      expect(game.sisaDetik.value, 0);
      expect(game.level.value, 1, reason: 'level naik saat tombol lanjut');
      expect(game.overlays.isActive(GameUtama.overlayLevelSelesai), isTrue);

      // Jebakan yang lolos saat jeda tidak dihitung.
      final skor = game.skor.value;
      game.jebakanDihindari();
      expect(game.skor.value, skor);
    },
  );

  testWithGame<GameUtama>(
    'jumlah jebakan dihindari tidak membuat level selesai',
    _buatGame,
    (game) async {
      for (var i = 0; i < 50; i++) {
        game.jebakanDihindari();
      }
      expect(game.menungguLanjut, isFalse);
      expect(game.skor.value, 50);
    },
  );

  testWithGame<GameUtama>(
    'lanjut level menaikkan level, mengulang waktu, dan membersihkan layar',
    _buatGame,
    (game) async {
      _selesaikanLevel(game);
      await game.ready();
      final skor = game.skor.value;

      game.lanjutLevel();
      await game.ready();

      expect(game.level.value, 2);
      expect(game.sisaDetik.value, LevelConfig.durasiLevel.toInt());
      expect(game.dihindariDiLevelIni.value, 0);
      expect(game.skor.value, skor, reason: 'skor dibawa ke level berikutnya');
      expect(game.menungguLanjut, isFalse);
      expect(game.paused, isFalse);
      expect(_jebakan(game), isEmpty);
      expect(game.overlays.isActive(GameUtama.overlayLevelSelesai), isFalse);
    },
  );

  testWithGame<GameUtama>(
    'jebakan baru di level 2 jatuh lebih cepat',
    _buatGame,
    (game) async {
      _selesaikanLevel(game);
      game.lanjutLevel();

      final jebakan = Jebakan(x: 0);
      await game.add(jebakan);
      await game.ready();
      final yAwal = jebakan.position.y;
      game.update(1);

      expect(jebakan.position.y - yAwal, closeTo(287.5, 0.001));
    },
  );

  testWithGame<GameUtama>('mobil tidak bisa digeser keluar jalan', _buatGame, (
    game,
  ) async {
    final player = await _playerSiap(game);
    player.geser(-1000);
    expect(player.position.x, 0);
    player.geser(1000);
    expect(player.position.x, game.size.x - player.size.x);
  });

  testWithGame<GameUtama>(
    'jebakan yang kena pemain: mobil meledak dan terbakar, lalu game over',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      final jebakan = Jebakan(x: player.position.x + 10);
      final jebakanLain = Jebakan(x: 0);
      await game.addAll([jebakan, jebakanLain]);
      await game.ready();
      jebakan.position.y = player.position.y + 5;

      game.update(0.016);
      await game.ready();
      final yJebakanLain = jebakanLain.position.y;

      // Langsung: ledakan, mobil terbakar, jebakan yang menabrak hancur.
      expect(game.isGameOver, isTrue);
      expect(player.terbakar, isTrue);
      expect(player.children.whereType<ApiTerbakar>(), hasLength(1));
      expect(game.children.whereType<ParticleSystemComponent>(), isNotEmpty);
      expect(jebakan.isMounted, isFalse);
      expect(game.overlays.isActive(GameUtama.overlayGameOver), isFalse);

      // Selama efek berjalan, jebakan lain membeku dan mobil tidak bisa
      // digerakkan.
      final xMobil = player.position.x;
      player.geser(50);
      game.update(GameUtama.jedaGameOver / 2);
      expect(jebakanLain.position.y, yJebakanLain);
      expect(player.position.x, closeTo(xMobil, 6.01)); // hanya guncangan

      // Setelah jeda, layar Game Over muncul; game tetap jalan agar api
      // terus menyala.
      game.update(GameUtama.jedaGameOver / 2 + 0.1);
      expect(game.overlays.isActive(GameUtama.overlayGameOver), isTrue);
      expect(game.paused, isFalse);
    },
  );

  var gameOverDipanggil = 0;
  testWithGame<GameUtama>(
    'onGameOver dipanggil sekali saat layar Game Over muncul',
    () {
      gameOverDipanggil = 0;
      final game = GameUtama(
        random: Random(1),
        onGameOver: () => gameOverDipanggil++,
      );
      game.overlays.addEntry(
        GameUtama.overlayGameOver,
        (_, _) => const SizedBox(),
      );
      return game;
    },
    (game) async {
      await _playerSiap(game);
      game.gameOver();
      await game.ready();
      game.update(GameUtama.jedaGameOver / 2);
      expect(gameOverDipanggil, 0, reason: 'iklan menunggu efek terbakar');

      game.update(GameUtama.jedaGameOver / 2 + 0.1);
      game.update(1);
      expect(gameOverDipanggil, 1);
      expect(game.overlays.isActive(GameUtama.overlayGameOver), isTrue);
    },
  );

  testWithGame<GameUtama>('main lagi mengembalikan game ke awal', _buatGame, (
    game,
  ) async {
    final player = await _playerSiap(game);
    for (var i = 0; i < 15; i++) {
      game.jebakanDihindari();
    }
    await game.add(Jebakan(x: 0));
    await game.ready();
    game.gameOver();
    game.update(GameUtama.jedaGameOver + 0.1);
    await game.ready();

    game.mainLagi();
    await game.ready();

    expect(game.isGameOver, isFalse);
    expect(game.level.value, 1);
    expect(game.skor.value, 0);
    expect(_jebakan(game), isEmpty);
    expect(player.terbakar, isFalse);
    expect(player.children.whereType<ApiTerbakar>(), isEmpty);
    expect(game.children.whereType<ParticleSystemComponent>(), isEmpty);
    expect(game.overlays.isActive(GameUtama.overlayGameOver), isFalse);
  });

  testWidgets('mobil mengikuti geseran jari ke kanan dan ke kiri', (
    tester,
  ) async {
    final game = _buatGame();
    await tester.pumpWidget(
      Center(
        child: SizedBox(width: 400, height: 800, child: GameWidget(game: game)),
      ),
    );
    await _tungguGambar(tester, game);

    final player = _player(game);
    final xAwal = player.position.x;
    final kotak = tester.getRect(find.byType(GameWidget<GameUtama>));

    // Jari di bagian atas layar, jauh dari mobil: mobil tetap ikut.
    await tester.timedDragFrom(
      kotak.center - const Offset(0, 200),
      const Offset(100, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pump();
    expect(player.position.x, closeTo(xAwal + 100, 1));

    await tester.timedDragFrom(
      kotak.center,
      const Offset(-150, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pump();
    expect(player.position.x, closeTo(xAwal - 50, 1));
  });

  testWidgets('LayarGame menampilkan level dan skor', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LayarGame(showAds: false)));
    // Pemuatan gambar butuh async sungguhan, bukan waktu palsu testWidgets.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(GameWidget<GameUtama>), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Skor 0'), findsOneWidget);
  });
}
