import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/bersama/layanan.dart';
import 'package:game_kren_kamu/bersama/penyimpanan.dart';
import 'package:game_kren_kamu/games/dua_ribu/layar_2048.dart';
import 'package:game_kren_kamu/games/dua_ribu/papan_2048.dart';

List<int> _gabung(List<int> garis) => Papan2048.gabungGaris(garis).hasil;

Papan2048 _papan(List<int> sel) => Papan2048(random: Random(1), sel: sel);

void main() {
  group('Aturan gabung', () {
    test('ubin merapat ke depan', () {
      expect(_gabung([0, 2, 0, 4]), [2, 4, 0, 0]);
    });

    test('dua ubin sama bergabung dan menambah poin', () {
      final r = Papan2048.gabungGaris([2, 2, 0, 0]);
      expect(r.hasil, [4, 0, 0, 0]);
      expect(r.poin, 4);
      expect(r.gabung, [0]);
    });

    test('empat ubin sama menjadi dua pasang, bukan satu', () {
      expect(_gabung([2, 2, 2, 2]), [4, 4, 0, 0]);
    });

    test('hasil gabungan tidak bergabung lagi di geseran yang sama', () {
      expect(_gabung([2, 2, 4, 0]), [4, 4, 0, 0]);
    });

    test('tiga ubin sama: dua terdepan yang bergabung', () {
      expect(_gabung([4, 4, 4, 0]), [8, 4, 0, 0]);
    });
  });

  group('Papan', () {
    test('papan baru berisi dua ubin', () {
      final papan = Papan2048(random: Random(1));
      expect(papan.sel.where((n) => n != 0), hasLength(2));
    });

    test('geser kanan & bawah memakai arah yang benar', () {
      // Baris 0: 4 _ 4 8 → kanan → _ _ 8 8
      final kanan = _papan([4, 0, 4, 8, ...List.filled(12, 0)]);
      expect(kanan.geser(Arah.kanan), isTrue);
      expect(kanan.sel.sublist(2, 4), [8, 8]);
      expect(kanan.skor, 8);

      // Kolom 0: 2,2,_,_ → bawah → ...,4 di baris terakhir
      final bawah = _papan([2, 0, 0, 0, 2, ...List.filled(11, 0)]);
      expect(bawah.geser(Arah.bawah), isTrue);
      expect(bawah.sel[12], 4);
    });

    test('setelah bergerak muncul tepat satu ubin baru', () {
      final papan = _papan([2, 0, 0, 0, ...List.filled(12, 0)]);
      papan.geser(Arah.kanan);
      expect(papan.sel.where((n) => n != 0), hasLength(2));
      expect(papan.ubinBaru, isNotNull);
    });

    test('tidak ada yang bergerak: tidak ada ubin baru', () {
      final papan = _papan([2, 4, 0, 0, ...List.filled(12, 0)]);
      expect(papan.geser(Arah.kiri), isFalse);
      expect(papan.sel.where((n) => n != 0), hasLength(2));
    });

    test('papan penuh tanpa pasangan sama: tidak bisa bergerak', () {
      final papan = _papan([
        2, 4, 2, 4, //
        4, 2, 4, 2,
        2, 4, 2, 4,
        4, 2, 4, 2,
      ]);
      expect(papan.bisaGerak, isFalse);

      papan.sel[1] = 2; // sekarang ada pasangan 2-2 di baris 0
      expect(papan.bisaGerak, isTrue);
    });
  });

  group('Layar 2048', () {
    Future<Layanan> buka(WidgetTester tester, {Layanan? layanan}) async {
      final l = layanan ?? Layanan.uji();
      await tester.pumpWidget(
        MaterialApp(
          home: Layar2048(layanan: l, random: Random(3)),
        ),
      );
      return l;
    }

    Future<void> usap(WidgetTester tester, Offset arah) async {
      await tester.fling(find.byType(GridView), arah, 1000);
      await tester.pumpAndSettle();
    }

    testWidgets('usapan menggabungkan ubin, menambah skor & rekor', (
      tester,
    ) async {
      final layanan = Layanan.uji();
      await layanan.penyimpanan.tulisDaftar('papan_2048', [
        '2', '2', '0', '0', //
        ...List.filled(12, '0'),
      ]);
      await buka(tester, layanan: layanan);

      await usap(tester, const Offset(-300, 0));

      expect(find.text('4'), findsWidgets);
      expect(layanan.penyimpanan.bacaInt(KunciSimpan.rekor2048), 4);
    });

    testWidgets('mencapai ubin 128 memberi koin sekali', (tester) async {
      final layanan = Layanan.uji();
      await layanan.penyimpanan.tulisDaftar('papan_2048', [
        '64', '64', '0', '0', //
        ...List.filled(12, '0'),
      ]);
      await buka(tester, layanan: layanan);

      await usap(tester, const Offset(-300, 0));
      expect(layanan.dompet.saldo.value, hadiahUbin[128]);
      expect(find.text('Ubin 128! +5 koin'), findsOneWidget);
    });

    testWidgets('permainan tersimpan dan dilanjutkan saat dibuka lagi', (
      tester,
    ) async {
      final layanan = await buka(tester);
      await usap(tester, const Offset(0, -300));
      final tersimpan = layanan.penyimpanan.bacaDaftar('papan_2048');

      await tester.pumpWidget(const SizedBox());
      await buka(tester, layanan: layanan);
      expect(layanan.penyimpanan.bacaDaftar('papan_2048'), tersimpan);
    });

    testWidgets('tidak bisa bergerak: layar kalah dan main lagi', (
      tester,
    ) async {
      final layanan = Layanan.uji();
      // Satu langkah sebelum buntu: geser kiri menggabungkan 2-2 lalu ubin
      // baru mengisi satu-satunya kotak kosong.
      await layanan.penyimpanan.tulisDaftar('papan_2048', [
        for (final n in [
          8, 16, 2, 2, //
          16, 8, 16, 8,
          8, 16, 8, 16,
          16, 8, 16, 8,
        ])
          '$n',
      ]);
      await buka(tester, layanan: layanan);
      await usap(tester, const Offset(-300, 0));

      // Baris 0 menjadi 8 16 4 2 (ubin baru 2 dengan random tetap): buntu.
      expect(find.text('Tidak bisa bergerak lagi!'), findsOneWidget);
      await tester.tap(find.text('Main Lagi'));
      await tester.pump();
      expect(find.text('Tidak bisa bergerak lagi!'), findsNothing);
    });
  });
}
