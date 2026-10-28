import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/beranda.dart';
import 'package:game_kren_kamu/bersama/layanan.dart';
import 'package:game_kren_kamu/bersama/penyimpanan.dart';

void main() {
  testWidgets('beranda: hadiah harian, daftar game, buka game lalu kembali', (
    tester,
  ) async {
    final layanan = Layanan.uji(jam: () => DateTime(2026, 10, 28, 9));
    await layanan.penyimpanan.tulisInt(KunciSimpan.rekorTerbang, 12);
    await tester.pumpWidget(MaterialApp(home: Beranda(layanan: layanan)));
    await tester.pumpAndSettle();

    // Hadiah harian muncul saat dibuka.
    expect(find.text('HADIAH HARIAN'), findsOneWidget);
    await tester.tap(find.text('KLAIM +10'));
    await tester.pumpAndSettle();
    expect(find.text('HADIAH HARIAN'), findsNothing);
    expect(layanan.dompet.saldo.value, 10);

    // Ketiga game dengan rekornya.
    for (final game in daftarGame) {
      expect(find.text(game.nama), findsOneWidget);
    }
    expect(find.text('Rekor 12'), findsOneWidget);

    // Buka 2048 lalu kembali.
    await tester.tap(find.text('2048'));
    await tester.pumpAndSettle();
    expect(find.text('SKOR'), findsOneWidget);

    await tester.tap(find.byTooltip('Beranda'));
    await tester.pumpAndSettle();
    expect(find.text('KREN KAMU'), findsOneWidget);
    expect(find.text('HADIAH HARIAN'), findsNothing, reason: 'sudah diklaim');
  });
}
