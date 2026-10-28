import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/efek_crash.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/garis_finish.dart';
import 'package:game_kren_kamu/game/level_config.dart';
import 'package:game_kren_kamu/game/overlays.dart';
import 'package:game_kren_kamu/game/jam.dart';
import 'package:game_kren_kamu/game/jebakan.dart';
import 'package:game_kren_kamu/game/koin.dart';
import 'package:game_kren_kamu/game/penyimpanan.dart';
import 'package:game_kren_kamu/game/player.dart';
import 'package:game_kren_kamu/layar_game.dart';

/// Game dengan random tetap dan overlay terdaftar (tanpa GameWidget, Flame
/// menolak membuka overlay yang belum punya builder).
GameUtama _buatGame({
  Penyimpanan? penyimpanan,
  bool mulaiDiMenu = false,
  VoidCallback? onGameOver,
}) {
  final game = GameUtama(
    random: Random(1),
    penyimpanan: penyimpanan,
    mulaiDiMenu: mulaiDiMenu,
    onGameOver: onGameOver,
  );
  for (final nama in [
    GameUtama.overlayMenu,
    GameUtama.overlayGarasi,
    GameUtama.overlayHud,
    GameUtama.overlayJeda,
    GameUtama.overlayLevelSelesai,
    GameUtama.overlayGameOver,
  ]) {
    game.overlays.addEntry(nama, (_, _) => const SizedBox());
  }
  return game;
}

/// Mobil tertabrak dan layar Game Over sudah muncul.
Future<void> _tabrakSampaiGameOver(GameUtama game) async {
  game.gameOver();
  await game.ready();
  game.update(GameUtama.jedaGameOver + 0.1);
  await game.ready();
}

Iterable<Jebakan> _jebakan(GameUtama game) =>
    game.children.whereType<Jebakan>();

/// Melompati waktu sampai level selesai.
/// Melompati waktu sampai level selesai: waktu habis, lalu mobil melewati
/// garis finish. Jebakan dibuang dulu supaya mobil pasti selamat.
Future<void> _selesaikanLevel(GameUtama game) async {
  game.update(LevelConfig.durasiLevel);
  await game.ready();
  game.removeAll(_jebakan(game));
  await game.ready();
  for (var i = 0; i < 100 && !game.menungguLanjut; i++) {
    game.update(0.1);
  }
}

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
      Vector2(
        game.size.x / 2 - player.size.x / 2,
        game.size.y - Player.jarakDariBawah,
      ),
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
    'setelah ${LevelConfig.durasiLevel.toInt()} detik garis finish muncul; '
    'level selesai saat mobil melewatinya',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      expect(game.sisaDetik.value, LevelConfig.durasiLevel.toInt());

      game.update(LevelConfig.durasiLevel - 1);
      expect(game.menujuFinish, isFalse);
      expect(game.sisaDetik.value, 1);

      // Waktu habis: garis finish muncul di atas, belum selesai.
      game.update(1);
      await game.ready();
      game.removeAll(_jebakan(game));
      await game.ready();
      expect(game.menujuFinish, isTrue);
      expect(game.menungguLanjut, isFalse);
      final garis = game.children.whereType<GarisFinish>().single;
      expect(garis.position.y, lessThan(0));

      // Tidak ada jebakan baru selama menuju finish.
      game.update(1);
      await game.ready();
      expect(_jebakan(game), isEmpty);

      // Garis finish turun sampai dilewati mobil.
      while (!game.menungguLanjut) {
        game.update(0.05);
      }
      expect(
        garis.position.y + garis.size.y,
        greaterThanOrEqualTo(player.position.y),
      );
      expect(game.menujuFinish, isFalse);
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
      await _selesaikanLevel(game);
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
      await _selesaikanLevel(game);
      game.lanjutLevel();

      final jebakan = Jebakan(x: 0);
      await game.add(jebakan);
      await game.ready();
      final yAwal = jebakan.position.y;
      game.update(1);

      expect(jebakan.position.y - yAwal, closeTo(287.5, 0.001));
    },
  );

  testWithGame<GameUtama>(
    'mobil bergerak selama tombol ditahan dan berhenti saat dilepas',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      final xAwal = player.position.x;

      game.tekanKanan(ditekan: true);
      game.update(0.1);
      expect(player.position.x, closeTo(xAwal + 25, 0.001));

      game.tekanKanan(ditekan: false);
      game.update(0.1);
      expect(player.position.x, closeTo(xAwal + 25, 0.001));

      game.tekanKiri(ditekan: true);
      game.update(0.1);
      expect(player.position.x, closeTo(xAwal, 0.001));

      // Kedua tombol ditekan: saling meniadakan.
      game.tekanKanan(ditekan: true);
      game.update(0.1);
      expect(player.position.x, closeTo(xAwal, 0.001));
    },
  );

  testWithGame<GameUtama>('mobil tidak bisa keluar jalan', _buatGame, (
    game,
  ) async {
    final player = await _playerSiap(game);
    game.tekanKiri(ditekan: true);
    game.update(10);
    expect(player.position.x, 0);

    game.tekanKiri(ditekan: false);
    game.tekanKanan(ditekan: true);
    game.update(10);
    expect(player.position.x, game.size.x - player.size.x);
  });

  testWithGame<GameUtama>('mobil di level 2 bergerak lebih cepat', _buatGame, (
    game,
  ) async {
    final player = await _playerSiap(game);
    await _selesaikanLevel(game);
    game.lanjutLevel();

    final xAwal = player.position.x;
    game.tekanKanan(ditekan: true);
    game.update(0.1);
    expect(player.position.x - xAwal, closeTo(28.75, 0.001));
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
      game.tekanKanan(ditekan: true);
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
      return _buatGame(onGameOver: () => gameOverDipanggil++);
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

  testWidgets('menahan tombol ▶ lalu ◀ di layar menggerakkan mobil', (
    tester,
  ) async {
    final game = _buatGame();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 800,
          child: GameWidget<GameUtama>(
            game: game,
            initialActiveOverlays: const [GameUtama.overlayHud],
            overlayBuilderMap: {
              GameUtama.overlayHud: (_, game) => HudOverlay(game: game),
            },
          ),
        ),
      ),
    );
    await _tungguGambar(tester, game);

    final player = _player(game);
    final xAwal = player.position.x;

    Future<void> tahan(String label) async {
      final jari = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel(label)),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await jari.up();
      await tester.pump();
    }

    await tahan('Kanan');
    final xSetelahKanan = player.position.x;
    expect(xSetelahKanan, greaterThan(xAwal));

    // Tombol sudah dilepas: mobil diam.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(player.position.x, xSetelahKanan);

    await tahan('Kiri');
    expect(player.position.x, lessThan(xSetelahKanan));
  });

  testWithGame<GameUtama>(
    'koin yang kena mobil menambah jumlah koin',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      final koin = Koin(x: player.position.x + 10);
      await game.add(koin);
      await game.ready();
      koin.position.y = player.position.y + 10;

      game.update(0.016);
      await game.ready();

      expect(game.koin.value, 1);
      expect(koin.isMounted, isFalse);
      expect(game.isGameOver, isFalse, reason: 'koin bukan jebakan');
    },
  );

  testWithGame<GameUtama>('koin muncul berkala di jalan', _buatGame, (
    game,
  ) async {
    game.update(GameUtama.jedaMunculKoin + 0.05);
    await game.ready();
    expect(game.children.whereType<Koin>(), hasLength(1));
  });

  testWithGame<GameUtama>(
    'jam yang kena mobil memotong sisa waktu level',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      game.update(2);
      expect(game.sisaDetik.value, 28);

      final jam = Jam(x: player.position.x + 10);
      await game.add(jam);
      await game.ready();
      jam.position.y = player.position.y + 10;
      game.update(0.016);
      await game.ready();

      expect(jam.isMounted, isFalse);
      expect(game.sisaDetik.value, 25);
      expect(game.children.whereType<TeksMelayang>(), hasLength(1));
      expect(game.koin.value, 0, reason: 'jam bukan koin');
      expect(game.isGameOver, isFalse);
    },
  );

  testWithGame<GameUtama>(
    'jam di detik terakhir langsung memunculkan garis finish',
    _buatGame,
    (game) async {
      await _playerSiap(game);
      game.update(LevelConfig.durasiLevel - 2);

      game.ambilJam();
      expect(game.sisaDetik.value, 0);
      game.update(0.016);
      await game.ready();

      expect(game.menujuFinish, isTrue);
      expect(game.children.whereType<GarisFinish>(), hasLength(1));
    },
  );

  testWithGame<GameUtama>(
    'tertabrak saat menuju finish lalu lanjut lewat iklan: garis finish tetap',
    _buatGame,
    (game) async {
      await _playerSiap(game);
      game.update(LevelConfig.durasiLevel);
      await game.ready();
      expect(game.menujuFinish, isTrue);

      await _tabrakSampaiGameOver(game);
      game.lanjutSetelahIklan();
      await game.ready();

      expect(game.menujuFinish, isTrue);
      expect(game.children.whereType<GarisFinish>(), hasLength(1));
      for (var i = 0; i < 100 && !game.menungguLanjut; i++) {
        game.update(0.1);
      }
      expect(game.menungguLanjut, isTrue);
    },
  );

  testWithGame<GameUtama>(
    'lanjut level membuang garis finish lama',
    _buatGame,
    (game) async {
      await _playerSiap(game);
      await _selesaikanLevel(game);
      game.lanjutLevel();
      await game.ready();
      expect(game.children.whereType<GarisFinish>(), isEmpty);
      expect(game.menujuFinish, isFalse);
    },
  );

  testWithGame<GameUtama>('jam muncul lebih jarang dari koin', _buatGame, (
    game,
  ) async {
    for (var i = 0; i < 52; i++) {
      game.update(0.1);
    }
    await game.ready();
    expect(game.children.whereType<Jam>(), hasLength(1));
  });

  testWithGame<GameUtama>(
    'game over menyimpan rekor dan koin ke penyimpanan',
    () => _buatGame(penyimpanan: PenyimpananMemori(rekor: 3, totalKoin: 10)),
    (game) async {
      await _playerSiap(game);
      expect(game.rekor.value, 3);

      for (var i = 0; i < 5; i++) {
        game.jebakanDihindari();
      }
      game.ambilKoin();
      game.ambilKoin();
      await _tabrakSampaiGameOver(game);

      expect(game.rekor.value, 5);
      expect(game.rekorBaru, isTrue);
      expect(game.totalKoin.value, 12);

      // Permainan berikutnya dengan skor lebih rendah: rekor tetap.
      game.mainLagi();
      game.jebakanDihindari();
      await _tabrakSampaiGameOver(game);
      expect(game.rekor.value, 5);
      expect(game.rekorBaru, isFalse);
      expect(game.totalKoin.value, 12);
    },
  );

  test('rekor dan koin terbaca lagi dari penyimpanan', () async {
    final penyimpanan = PenyimpananMemori();
    await penyimpanan.simpan(rekor: 7, totalKoin: 20);
    final game = GameUtama(penyimpanan: penyimpanan);
    expect(game.rekor.value, 7);
    expect(game.totalKoin.value, 20);
  });

  testWithGame<GameUtama>(
    'lanjut setelah iklan: permainan diteruskan sekali saja',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      for (var i = 0; i < 4; i++) {
        game.jebakanDihindari();
      }
      game.ambilKoin();
      game.update(5);
      await game.add(Jebakan(x: 0));
      await game.ready();
      await _tabrakSampaiGameOver(game);
      final sisaDetik = game.sisaDetik.value;

      game.lanjutSetelahIklan();
      await game.ready();

      expect(game.isGameOver, isFalse);
      expect(player.terbakar, isFalse);
      expect(game.skor.value, 4, reason: 'skor tidak hilang');
      expect(game.koin.value, 1);
      expect(game.sisaDetik.value, sisaDetik);
      expect(_jebakan(game), isEmpty, reason: 'jalan dibersihkan');
      expect(game.overlays.isActive(GameUtama.overlayGameOver), isFalse);
      expect(game.bisaLanjutDenganIklan, isFalse);

      // Tabrakan kedua: tidak bisa lanjut lagi.
      await _tabrakSampaiGameOver(game);
      game.lanjutSetelahIklan();
      expect(game.isGameOver, isTrue);

      // Main lagi: kesempatan lanjut kembali tersedia.
      game.mainLagi();
      expect(game.bisaLanjutDenganIklan, isTrue);
    },
  );

  testWithGame<GameUtama>(
    'jeda menghentikan game dan mobil, lalu bisa dilanjutkan',
    _buatGame,
    (game) async {
      final player = await _playerSiap(game);
      game.jeda();
      expect(game.dijeda, isTrue);
      expect(game.paused, isTrue);
      expect(game.overlays.isActive(GameUtama.overlayJeda), isTrue);

      game.lanjutkanJeda();
      expect(game.dijeda, isFalse);
      expect(game.paused, isFalse);
      expect(game.overlays.isActive(GameUtama.overlayJeda), isFalse);

      // Tombol yang tertahan saat jeda dilepas, mobil tidak jalan sendiri.
      game.tekanKanan(ditekan: true);
      game.jeda();
      game.lanjutkanJeda();
      final x = player.position.x;
      game.update(0.5);
      expect(player.position.x, x);
    },
  );

  testWithGame<GameUtama>(
    'aplikasi ditinggal saat bermain: jeda otomatis dan tetap jeda saat kembali',
    _buatGame,
    (game) async {
      await _playerSiap(game);
      game.lifecycleStateChange(AppLifecycleState.inactive);
      game.lifecycleStateChange(AppLifecycleState.hidden);
      game.lifecycleStateChange(AppLifecycleState.paused);
      expect(game.dijeda, isTrue);

      game.lifecycleStateChange(AppLifecycleState.hidden);
      game.lifecycleStateChange(AppLifecycleState.inactive);
      game.lifecycleStateChange(AppLifecycleState.resumed);
      expect(game.dijeda, isTrue);
      expect(game.paused, isTrue, reason: 'menunggu tombol Lanjut');
    },
  );

  testWithGame<GameUtama>(
    'game dimulai dari menu: belum ada jebakan atau waktu berjalan',
    () => _buatGame(mulaiDiMenu: true),
    (game) async {
      await _playerSiap(game);
      game.update(5);
      await game.ready();
      expect(game.diMenu, isTrue);
      expect(_jebakan(game), isEmpty);
      expect(game.sisaDetik.value, LevelConfig.durasiLevel.toInt());

      game.mulai();
      expect(game.diMenu, isFalse);
      expect(game.overlays.isActive(GameUtama.overlayHud), isTrue);
      game.update(5);
      expect(game.sisaDetik.value, LevelConfig.durasiLevel.toInt() - 5);
    },
  );

  testWithGame<GameUtama>(
    'kembali ke menu dari jeda menyimpan koin dan mengulang permainan',
    _buatGame,
    (game) async {
      await _playerSiap(game);
      game.jebakanDihindari();
      game.ambilKoin();
      game.jeda();

      game.kembaliKeMenu();

      expect(game.diMenu, isTrue);
      expect(game.paused, isFalse, reason: 'jalan tetap bergerak di menu');
      expect(game.totalKoin.value, 1);
      expect(game.rekor.value, 1);
      expect(game.skor.value, 0);
      expect(game.overlays.isActive(GameUtama.overlayMenu), isTrue);
      expect(game.overlays.isActive(GameUtama.overlayJeda), isFalse);
    },
  );

  testWidgets('LayarGame dimulai dari menu, tombol MAIN memulai permainan', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LayarGame(showAds: false)));
    // Pemuatan gambar butuh async sungguhan, bukan waktu palsu testWidgets.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('KREN KAMU'), findsOneWidget);
    expect(find.text('Rekor 0'), findsOneWidget);

    await tester.tap(find.text('MAIN'));
    await tester.pump();

    expect(find.text('KREN KAMU'), findsNothing);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Skor 0'), findsOneWidget);
  });
}
