import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/garasi.dart';
import 'package:game_kren_kamu/game/garasi_overlay.dart';
import 'package:game_kren_kamu/game/overlays.dart';
import 'package:game_kren_kamu/game/penyimpanan.dart';

DataMobil _mobil(String id) => daftarMobil.firstWhere((m) => m.id == id);

void main() {
  group('Garasi', () {
    test('awalnya hanya punya mobil gratis dan memakainya', () {
      final garasi = Garasi(PenyimpananMemori(), ValueNotifier(0));
      expect(garasi.dimiliki.value, {'biru'});
      expect(garasi.dipakai.value, 'biru');
      expect(garasi.mobilDipakai.harga, 0);
    });

    test('membeli mobil mengurangi koin, memakainya, dan menyimpannya', () {
      final penyimpanan = PenyimpananMemori(totalKoin: 70);
      final koin = ValueNotifier(70);
      final garasi = Garasi(penyimpanan, koin);

      expect(garasi.beli(_mobil('taksi')), HasilBeli.berhasil);

      expect(koin.value, 20);
      expect(garasi.punya('taksi'), isTrue);
      expect(garasi.dipakai.value, 'taksi');
      expect(penyimpanan.totalKoin, 20);
      expect(penyimpanan.mobilDimiliki, containsAll(['biru', 'taksi']));
      expect(penyimpanan.mobilDipakai, 'taksi');
    });

    test('koin kurang: tidak bisa membeli', () {
      final koin = ValueNotifier(100);
      final garasi = Garasi(PenyimpananMemori(), koin);

      expect(garasi.beli(_mobil('polisi')), HasilBeli.koinKurang);
      expect(koin.value, 100);
      expect(garasi.punya('polisi'), isFalse);
      expect(garasi.dipakai.value, 'biru');
    });

    test('mobil yang sudah dimiliki tidak dibeli dua kali', () {
      final koin = ValueNotifier(500);
      final garasi = Garasi(PenyimpananMemori(), koin);
      garasi.beli(_mobil('taksi'));

      expect(garasi.beli(_mobil('taksi')), HasilBeli.sudahPunya);
      expect(koin.value, 450);
    });

    test('ganti mobil hanya ke mobil yang dimiliki', () {
      final penyimpanan = PenyimpananMemori(
        mobilDimiliki: {'biru', 'taksi'},
        mobilDipakai: 'taksi',
      );
      final garasi = Garasi(penyimpanan, ValueNotifier(0));
      expect(garasi.dipakai.value, 'taksi');

      garasi.pakai(_mobil('biru'));
      expect(garasi.dipakai.value, 'biru');
      expect(penyimpanan.mobilDipakai, 'biru');

      garasi.pakai(_mobil('mewah'));
      expect(garasi.dipakai.value, 'biru');
    });

    test('data tersimpan yang rusak kembali ke mobil awal', () {
      final garasi = Garasi(
        PenyimpananMemori(mobilDipakai: 'mewah'),
        ValueNotifier(0),
      );
      expect(garasi.dipakai.value, 'biru');
    });
  });

  testWidgets('menu → garasi: beli taksi lalu kembali ke menu', (tester) async {
    final game = GameUtama(
      penyimpanan: PenyimpananMemori(totalKoin: 60),
      mulaiDiMenu: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameWidget<GameUtama>(
            game: game,
            initialActiveOverlays: const [GameUtama.overlayMenu],
            overlayBuilderMap: {
              GameUtama.overlayMenu: (_, game) => MenuOverlay(game: game),
              GameUtama.overlayGarasi: (_, game) => GarasiOverlay(game: game),
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await game.loaded;
      await game.ready();
    });
    await tester.pump();

    await tester.tap(find.text('GARASI'));
    await tester.pump();
    expect(find.text('Taksi'), findsOneWidget);
    expect(find.text('Kurang 60 koin'), findsOneWidget); // Polisi 120

    await tester.tap(find.widgetWithText(FilledButton, 'Beli').first);
    await tester.pump();

    expect(game.garasi.dipakai.value, 'taksi');
    expect(game.totalKoin.value, 10);
    expect(find.text('Taksi dibeli dan dipakai!'), findsOneWidget);
    expect(find.text('Dipakai'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    expect(find.text('KREN KAMU'), findsOneWidget);
  });
}
