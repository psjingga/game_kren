import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/dompet.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/garasi.dart';
import 'package:game_kren_kamu/game/garasi_overlay.dart';
import 'package:game_kren_kamu/game/overlays.dart';
import 'package:game_kren_kamu/game/penyimpanan.dart';

DataMobil _mobil(String id) => daftarMobil.firstWhere((m) => m.id == id);

void main() {
  group('Garasi', () {
    test('awalnya hanya punya mobil gratis dan memakainya', () {
      final penyimpanan = PenyimpananMemori();
      final garasi = Garasi(penyimpanan, Dompet(penyimpanan));
      expect(garasi.dimiliki.value, {'biru'});
      expect(garasi.dipakai.value, 'biru');
      expect(garasi.mobilDipakai.harga, 0);
    });

    test('membeli mobil mengurangi koin, memakainya, dan menyimpannya', () {
      final penyimpanan = PenyimpananMemori(totalKoin: 70);
      final dompet = Dompet(penyimpanan);
      final garasi = Garasi(penyimpanan, dompet);

      expect(garasi.beli(_mobil('taksi')), HasilBeli.berhasil);

      expect(dompet.saldo.value, 20);
      expect(garasi.punya('taksi'), isTrue);
      expect(garasi.dipakai.value, 'taksi');

      // Dibuka lagi (aplikasi dibuka ulang): data tetap.
      final dibukaLagi = Garasi(penyimpanan, Dompet(penyimpanan));
      expect(dibukaLagi.dimiliki.value, containsAll(['biru', 'taksi']));
      expect(dibukaLagi.dipakai.value, 'taksi');
      expect(Dompet(penyimpanan).saldo.value, 20);
    });

    test('koin kurang: tidak bisa membeli', () {
      final penyimpanan = PenyimpananMemori(totalKoin: 100);
      final dompet = Dompet(penyimpanan);
      final garasi = Garasi(penyimpanan, dompet);

      expect(garasi.beli(_mobil('polisi')), HasilBeli.koinKurang);
      expect(dompet.saldo.value, 100);
      expect(garasi.punya('polisi'), isFalse);
      expect(garasi.dipakai.value, 'biru');
    });

    test('mobil yang sudah dimiliki tidak dibeli dua kali', () {
      final penyimpanan = PenyimpananMemori(totalKoin: 500);
      final dompet = Dompet(penyimpanan);
      final garasi = Garasi(penyimpanan, dompet)..beli(_mobil('taksi'));

      expect(garasi.beli(_mobil('taksi')), HasilBeli.sudahPunya);
      expect(dompet.saldo.value, 450);
    });

    test('ganti mobil hanya ke mobil yang dimiliki', () {
      final penyimpanan = PenyimpananMemori(totalKoin: 50);
      final garasi = Garasi(penyimpanan, Dompet(penyimpanan))
        ..beli(_mobil('taksi'));
      expect(garasi.dipakai.value, 'taksi');

      garasi.pakai(_mobil('biru'));
      expect(garasi.dipakai.value, 'biru');
      expect(Garasi(penyimpanan, Dompet(penyimpanan)).dipakai.value, 'biru');

      garasi.pakai(_mobil('mewah'));
      expect(garasi.dipakai.value, 'biru');
    });

    test('data tersimpan yang rusak kembali ke mobil awal', () {
      final penyimpanan = PenyimpananMemori();
      penyimpanan.data['mobil_dipakai'] = 'mewah'; // belum dibeli
      final garasi = Garasi(penyimpanan, Dompet(penyimpanan));
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
              GameUtama.overlayHadiahHarian: (_, _) => const SizedBox(),
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
