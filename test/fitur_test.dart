import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/jalan.dart';
import 'package:game_kren_kamu/game/jebakan.dart';
import 'package:game_kren_kamu/game/koin.dart';
import 'package:game_kren_kamu/game/level_config.dart';
import 'package:game_kren_kamu/game/misi.dart';
import 'package:game_kren_kamu/game/mobil_lawan.dart';
import 'package:game_kren_kamu/game/oli.dart';
import 'package:game_kren_kamu/game/player.dart';
import 'package:game_kren_kamu/game/power_up.dart';
import 'package:game_kren_kamu/game/rintangan.dart';

GameUtama _buatGame() {
  final game = GameUtama(
    random: Random(1),
    jam: () => DateTime(2026, 10, 28, 9),
  );
  for (final nama in [
    GameUtama.overlayHud,
    GameUtama.overlayLevelSelesai,
    GameUtama.overlayGameOver,
  ]) {
    game.overlays.addEntry(nama, (_, _) => const SizedBox());
  }
  return game;
}

Future<Player> _siap(GameUtama game) async {
  await game.ready();
  return game.children.whereType<Player>().single;
}

/// Menaruh [komponen] tepat di depan mobil supaya langsung bertabrakan.
Future<void> _tabrakkan(GameUtama game, PositionComponent komponen) async {
  await game.add(komponen);
  await game.ready();
  komponen.position.y = game.kotakMobil.top + 5;
  game.update(0.016);
  await game.ready();
}

/// Menaikkan level tanpa memainkan level sebelumnya.
void _keLevel(GameUtama game, int level) => game.level.value = level;

void main() {
  // Memuat gambar SVG dari aset butuh binding Flutter.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Power-up', () {
    testWithGame<GameUtama>(
      'perisai menahan satu tabrakan, tabrakan berikutnya game over',
      _buatGame,
      (game) async {
        final player = await _siap(game);
        game.ambilPowerUp(JenisPowerUp.perisai);
        expect(game.status.perisai.value, isTrue);

        final jebakan = Jebakan(x: player.position.x + 6);
        await _tabrakkan(game, jebakan);
        expect(game.isGameOver, isFalse);
        expect(game.status.perisai.value, isFalse);
        expect(jebakan.isMounted, isFalse);

        game.update(1); // masa kebal habis
        await _tabrakkan(game, Jebakan(x: player.position.x + 6));
        expect(game.isGameOver, isTrue);
      },
    );

    testWithGame<GameUtama>(
      'koin ganda: setiap koin bernilai 2 selama 10 detik',
      _buatGame,
      (game) async {
        await _siap(game);
        game.ambilPowerUp(JenisPowerUp.koinGanda);
        game.ambilKoin();
        expect(game.koin.value, 2);
        expect(game.status.detikKoinGanda.value, 10);

        game.update(StatusPowerUp.lamaKoinGanda + 0.1);
        expect(game.status.koinGandaAktif, isFalse);
        game.ambilKoin();
        expect(game.koin.value, 3);
      },
    );

    testWithGame<GameUtama>('magnet menarik koin di dekat mobil', _buatGame, (
      game,
    ) async {
      final player = await _siap(game);
      // Di samping mobil, dalam jangkauan magnet.
      final koin = Koin(x: player.position.x - 110);
      await game.add(koin);
      await game.ready();
      koin.position.y = player.position.y + 20;
      final jarakAwal = (koin.absoluteCenter - player.absoluteCenter).length;

      game.ambilPowerUp(JenisPowerUp.magnet);
      game.update(0.1);
      final jarakSetelah = (koin.absoluteCenter - player.absoluteCenter).length;

      expect(jarakSetelah, lessThan(jarakAwal - 30));
    });

    testWithGame<GameUtama>('power-up muncul berkala', _buatGame, (game) async {
      await _siap(game);
      for (var i = 0; i < 92; i++) {
        game.update(0.1);
      }
      await game.ready();
      expect(game.children.whereType<PowerUp>(), hasLength(1));
    });
  });

  group('Nyaris', () {
    testWithGame<GameUtama>(
      'jebakan yang lewat sangat tipis di samping mobil memberi +2',
      _buatGame,
      (game) async {
        await _siap(game);
        final mobil = game.kotakMobil;
        // Tepi kanan hitbox jebakan 6 px dari tepi kiri hitbox mobil.
        final jebakan = Jebakan(x: mobil.left - 6 - 36);
        await game.add(jebakan);
        await game.ready();
        jebakan.position.y = mobil.top - 60;

        for (var i = 0; i < 20; i++) {
          game.update(0.05);
        }
        expect(game.isGameOver, isFalse);
        expect(game.skor.value, GameUtama.bonusNyaris);
      },
    );

    testWithGame<GameUtama>(
      'jebakan yang lewat jauh tidak memberi bonus',
      _buatGame,
      (game) async {
        await _siap(game);
        final jebakan = Jebakan(x: game.batasKiri);
        await game.add(jebakan);
        await game.ready();
        jebakan.position.y = game.kotakMobil.top - 60;

        for (var i = 0; i < 20; i++) {
          game.update(0.05);
        }
        expect(game.skor.value, 0);
      },
    );
  });

  group('Rintangan', () {
    testWithGame<GameUtama>(
      'oli membuat mobil selip, bukan game over',
      _buatGame,
      (game) async {
        final player = await _siap(game);
        await _tabrakkan(game, Oli(x: player.position.x));

        expect(game.isGameOver, isFalse);
        expect(player.selip, isTrue);

        // Tombol setir tidak berpengaruh selama selip.
        final x = player.position.x;
        game.tekanKiri(ditekan: true);
        game.update(0.2);
        expect(player.position.x, isNot(closeTo(x - 0.2 * 250, 1)));

        game.update(Player.lamaSelip);
        expect(player.selip, isFalse);
      },
    );

    testWithGame<GameUtama>(
      'mobil lain di tengah lajur; menabraknya game over',
      _buatGame,
      (game) async {
        final player = await _siap(game);
        final lawan = MobilLawan();
        await game.add(lawan);
        await game.ready();
        final tengah = lawan.position.x + lawan.size.x / 2;
        expect([
          for (var i = 0; i < 3; i++) game.tengahLajur(i),
        ], contains(closeTo(tengah, 0.001)));

        lawan.position.x = player.position.x;
        await _tabrakkan(game, MobilLawan(x: player.position.x));
        expect(game.isGameOver, isTrue);
      },
    );

    testWithGame<GameUtama>('level 1 hanya jebakan biasa', _buatGame, (
      game,
    ) async {
      await _siap(game);
      // 15 × 1,51 detik masih di bawah 30 detik (sebelum garis finish).
      for (var i = 0; i < 15; i++) {
        game.update(LevelConfig.forLevel(1).jedaMunculJebakan + 0.01);
        await game.ready();
        final rintangan = game.children.whereType<Rintangan>().toList();
        expect(rintangan, isNotEmpty);
        expect(rintangan.every((r) => r is Jebakan), isTrue);
        game.removeAll(rintangan);
        await game.ready();
      }
    });

    testWithGame<GameUtama>(
      'level tinggi: muncul oli, mobil lain, dan barisan jebakan bercelah',
      _buatGame,
      (game) async {
        await _siap(game);
        _keLevel(game, 5);
        var adaOli = false;
        var adaLawan = false;
        var adaBarisan = false;
        for (var i = 0; i < 80; i++) {
          game.update(LevelConfig.forLevel(5).jedaMunculJebakan + 0.01);
          await game.ready();
          final rintangan = game.children.whereType<Rintangan>().toList();
          adaOli |= rintangan.any((r) => r is Oli);
          adaLawan |= rintangan.any((r) => r is MobilLawan);
          final barisan = rintangan.whereType<Jebakan>().toList();
          if (barisan.length > 2) {
            adaBarisan = true;
            // Ada celah minimal 120 px yang cukup untuk mobil.
            final xs = barisan.map((j) => j.position.x).toList()..sort();
            final celah = [
              xs.first - game.batasKiri,
              for (var k = 1; k < xs.length; k++) xs[k] - xs[k - 1] - 40,
              game.batasKanan - (xs.last + 40),
            ].reduce(max);
            expect(celah, greaterThanOrEqualTo(80));
          }
          game.removeAll(rintangan);
          await game.ready();
          if (game.isGameOver) break;
        }
        expect(adaOli, isTrue);
        expect(adaLawan, isTrue);
        expect(adaBarisan, isTrue);
      },
    );
  });

  group('Tampilan', () {
    test('suasana berganti per level: siang, sore, malam, siang', () {
      expect(
        [for (var l = 1; l <= 4; l++) Suasana.untukLevel(l)],
        [Suasana.siang, Suasana.sore, Suasana.malam, Suasana.siang],
      );
    });

    testWithGame<GameUtama>(
      'barang dan mobil tetap di aspal, tidak di rumput',
      _buatGame,
      (game) async {
        await _siap(game);
        for (var i = 0; i < 30; i++) {
          final koin = Koin();
          await game.add(koin);
        }
        await game.ready();
        for (final koin in game.children.whereType<Koin>()) {
          expect(koin.position.x, greaterThanOrEqualTo(game.batasKiri));
          expect(
            koin.position.x + koin.size.x,
            lessThanOrEqualTo(game.batasKanan),
          );
        }
      },
    );
  });

  group('Misi tercatat saat bermain', () {
    testWithGame<GameUtama>(
      'koin, jam, power-up, dan jebakan dihindari menambah progres misi',
      _buatGame,
      (game) async {
        await _siap(game);
        game
          ..ambilKoin()
          ..ambilJam()
          ..ambilPowerUp(JenisPowerUp.magnet)
          ..jebakanDihindari();
        final progres = {
          for (final m in game.misi.daftar.value) m.jenis: m.progres,
        };
        for (final jenis in [
          JenisMisi.koin,
          JenisMisi.jam,
          JenisMisi.powerUp,
          JenisMisi.hindari,
        ]) {
          if (progres.containsKey(jenis)) expect(progres[jenis], 1);
        }
      },
    );
  });
}
