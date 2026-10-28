import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/game_utama.dart';
import 'package:game_kren_kamu/game/level_config.dart';
import 'package:game_kren_kamu/game/level_selesai_overlay.dart';

void main() {
  testWidgets('animasi level selesai lalu tombol lanjut ke level berikutnya', (
    tester,
  ) async {
    final game = GameUtama(random: Random(1));
    await tester.pumpWidget(
      MaterialApp(
        home: GameWidget<GameUtama>(
          game: game,
          overlayBuilderMap: {
            GameUtama.overlayLevelSelesai: (_, game) =>
                LevelSelesaiOverlay(game: game),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (var i = 0; i < LevelConfig.meteorPerLevel; i++) {
      game.meteorDihindari();
    }
    await tester.pump();
    expect(find.text('LEVEL 1 SELESAI!'), findsOneWidget);

    // Tombol belum aktif di awal animasi.
    final tombol = find.widgetWithText(FilledButton, 'Lanjut ke Level 2');
    expect(tester.widget<FilledButton>(tombol).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 1700));
    expect(tester.widget<FilledButton>(tombol).onPressed, isNotNull);
    expect(find.text('Level berikutnya 15% lebih cepat'), findsOneWidget);

    await tester.tap(tombol);
    await tester.pump();

    expect(game.level.value, 2);
    expect(find.text('LEVEL 1 SELESAI!'), findsNothing);
  });
}
