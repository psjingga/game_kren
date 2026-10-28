import 'package:flutter/material.dart';

import 'game_utama.dart';

/// Level, skor, dan sisa waktu level di pojok kiri atas.
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
              valueListenable: game.sisaDetik,
              builder: (_, sisa, _) => Text(
                'Sisa waktu ${_formatWaktu(sisa)}',
                style: gaya.copyWith(
                  color: sisa <= 5 ? Colors.orangeAccent : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `75` -> `1:15`
String _formatWaktu(int detik) {
  final menit = detik ~/ 60;
  return '$menit:${(detik % 60).toString().padLeft(2, '0')}';
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
