import 'package:flutter/material.dart';

import 'game_utama.dart';
import 'level_config.dart';

/// Level, skor, dan progres level di pojok kiri atas.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  Widget build(BuildContext context) {
    const gaya = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: game.level,
              builder: (_, level, _) => Text('Level $level', style: gaya),
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.skor,
              builder: (_, skor, _) => Text('Skor $skor', style: gaya),
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.dihindariDiLevelIni,
              builder: (_, jumlah, _) => Text(
                'Meteor $jumlah/${LevelConfig.meteorPerLevel}',
                style: gaya.copyWith(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar kalah dengan ringkasan dan tombol main lagi.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.red,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Skor ${game.skor.value} • Level ${game.level.value}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: game.mainLagi,
              child: const Text('Main Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
