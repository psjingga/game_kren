import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/bersama/dompet.dart';
import 'package:game_kren_kamu/bersama/penyimpanan.dart';
import 'package:game_kren_kamu/games/terbang/game_terbang.dart';

late PenyimpananMemori _penyimpanan;
late Dompet _dompet;
var _kalahDipanggil = 0;

GameTerbang _buatGame() {
  _penyimpanan = PenyimpananMemori();
  _dompet = Dompet(_penyimpanan);
  _kalahDipanggil = 0;
  final game = GameTerbang(
    penyimpanan: _penyimpanan,
    dompet: _dompet,
    random: Random(1),
    onKalah: () => _kalahDipanggil++,
  );
  for (final nama in [
    GameTerbang.overlaySiap,
    GameTerbang.overlayHud,
    GameTerbang.overlayKalah,
  ]) {
    game.overlays.addEntry(nama, (_, _) => const SizedBox());
  }
  return game;
}

/// Jalankan game [detik] dengan langkah kecil.
void _jalankan(GameTerbang game, double detik) {
  for (var t = 0.0; t < detik; t += 0.02) {
    game.update(0.02);
  }
}

void main() {
  // Getaran (HapticFeedback) butuh binding Flutter.
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame<GameTerbang>(
    'sebelum diketuk burung melayang di tempat',
    _buatGame,
    (game) async {
      await game.ready();
      final y = game.burung.position.y;
      _jalankan(game, 2);
      expect(game.status, StatusTerbang.siap);
      expect(game.burung.position.y, closeTo(y, 10));
    },
  );

  testWithGame<GameTerbang>(
    'ketukan pertama memulai; kepakan membuat burung naik',
    _buatGame,
    (game) async {
      await game.ready();
      game.mulai();
      expect(game.status, StatusTerbang.main);
      expect(game.overlays.isActive(GameTerbang.overlayHud), isTrue);

      final y = game.burung.position.y;
      game.update(0.1);
      expect(game.burung.position.y, lessThan(y));
    },
  );

  testWithGame<GameTerbang>(
    'tanpa kepakan burung jatuh ke tanah lalu kalah',
    _buatGame,
    (game) async {
      await game.ready();
      game.mulai();
      _jalankan(game, 2);
      expect(game.status, StatusTerbang.kalah);
      await game.ready(); // timer jeda kalah terpasang
      _jalankan(game, 1);
      expect(game.overlays.isActive(GameTerbang.overlayKalah), isTrue);
      expect(_kalahDipanggil, 1);
    },
  );

  testWithGame<GameTerbang>(
    'melewati celah pipa menambah skor; menabrak pipa kalah',
    _buatGame,
    (game) async {
      await game.ready();
      game.mulai();
      game.burung.kecepatanY = 0;

      // Celah tepat di posisi burung, pipa tepat di depannya.
      final aman = PasanganPipa(
        tengahCelah: game.burung.position.y,
        tinggiCelah: 200,
      );
      await game.add(aman);
      await game.ready();
      aman.position.x = game.burung.position.x + 30;
      for (var t = 0.0; t < 1.0 && game.skor.value == 0; t += 0.02) {
        game.burung.kecepatanY = 0; // jaga ketinggian
        game.update(0.02);
      }
      expect(game.skor.value, 1);
      expect(game.status, StatusTerbang.main);

      // Pipa tanpa celah di ketinggian burung.
      final tabrak = PasanganPipa(tengahCelah: 60, tinggiCelah: 40);
      await game.add(tabrak);
      await game.ready();
      tabrak.position.x = game.burung.position.x - 10;
      game.update(0.02);
      await game.ready();
      expect(game.status, StatusTerbang.kalah);
    },
  );

  testWithGame<GameTerbang>(
    'koin yang diambil masuk dompet saat kalah; rekor tersimpan',
    _buatGame,
    (game) async {
      await game.ready();
      game.mulai();
      await game.add(KoinTerbang(game.burung.position.clone()));
      await game.ready();
      game.update(0.02);
      await game.ready();
      expect(game.koin.value, 1);

      game.skor.value = 5;
      game.kalah();
      expect(_dompet.saldo.value, 1);
      expect(game.rekorBaru, isTrue);
      expect(_penyimpanan.bacaInt(KunciSimpan.rekorTerbang), 5);
    },
  );

  testWithGame<GameTerbang>('main lagi mengulang dari awal', _buatGame, (
    game,
  ) async {
    await game.ready();
    game.mulai();
    _jalankan(game, 2);
    await game.ready();
    _jalankan(game, 1);
    expect(game.status, StatusTerbang.kalah);

    game.mainLagi();
    await game.ready();
    expect(game.status, StatusTerbang.siap);
    expect(game.skor.value, 0);
    expect(game.children.whereType<PasanganPipa>(), isEmpty);
    expect(game.overlays.isActive(GameTerbang.overlaySiap), isTrue);
  });

  testWithGame<GameTerbang>('pipa muncul berkala selama bermain', _buatGame, (
    game,
  ) async {
    await game.ready();
    game.mulai();
    for (var t = 0.0; t < 3; t += 0.02) {
      if (game.burung.position.y > game.size.y * 0.4) game.burung.kepak();
      game.update(0.02);
    }
    await game.ready();
    expect(
      game.children.whereType<PasanganPipa>().length + game.skor.value,
      greaterThanOrEqualTo(1),
    );
  });

  test('pipa makin cepat dan celah makin sempit seiring skor', () {
    final game = GameTerbang(
      penyimpanan: PenyimpananMemori(),
      dompet: Dompet(PenyimpananMemori()),
    );
    final awal = (game.kecepatan, game.tinggiCelah);
    game.skor.value = 15;
    expect(game.kecepatan, greaterThan(awal.$1));
    expect(game.tinggiCelah, lessThan(awal.$2));
    game.skor.value = 1000;
    expect(game.kecepatan, 280);
    expect(game.tinggiCelah, 120);
  });
}
