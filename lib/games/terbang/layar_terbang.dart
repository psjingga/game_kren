import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../bersama/jumlah_koin.dart';
import '../../bersama/layanan.dart';
import '../../bersama/layar_dengan_banner.dart';
import 'game_terbang.dart';

/// Game Terbang Kren dengan banner iklan di bawah.
class LayarTerbang extends StatefulWidget {
  const LayarTerbang({super.key, required this.layanan});

  final Layanan layanan;

  @override
  State<LayarTerbang> createState() => _LayarTerbangState();
}

class _LayarTerbangState extends State<LayarTerbang> {
  late final _game = GameTerbang(
    penyimpanan: widget.layanan.penyimpanan,
    dompet: widget.layanan.dompet,
    onKalah: () => widget.layanan.iklan?.layarPenuh.gameOver(),
  );

  @override
  void dispose() {
    _game.simpanSebelumKeluar();
    super.dispose();
  }

  void _keBeranda() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return LayarDenganBanner(
      layanan: widget.layanan,
      warnaLatar: const Color(0xFF4FC3F7),
      child: GameWidget<GameTerbang>(
        game: _game,
        initialActiveOverlays: const [GameTerbang.overlaySiap],
        overlayBuilderMap: {
          GameTerbang.overlaySiap: (_, game) =>
              _OverlaySiap(game: game, onKeBeranda: _keBeranda),
          GameTerbang.overlayHud: (_, game) => _OverlayHud(game: game),
          GameTerbang.overlayKalah: (_, game) =>
              _OverlayKalah(game: game, onKeBeranda: _keBeranda),
        },
      ),
    );
  }
}

const _bayangan = [Shadow(color: Colors.black54, blurRadius: 6)];

class _OverlaySiap extends StatelessWidget {
  const _OverlaySiap({required this.game, required this.onKeBeranda});

  final GameTerbang game;
  final VoidCallback onKeBeranda;

  @override
  Widget build(BuildContext context) {
    // Ketukan di mana saja (selain tombol beranda) diteruskan ke game.
    return Stack(
      children: [
        Positioned(
          left: 4,
          top: 4,
          child: IconButton(
            onPressed: onKeBeranda,
            tooltip: 'Beranda',
            icon: const Icon(Icons.home_rounded, shadows: _bayangan),
            color: Colors.white,
            iconSize: 30,
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TERBANG KREN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: _bayangan,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rekor ${game.rekor.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: _bayangan,
                  ),
                ),
              ],
            ),
          ),
        ),
        const IgnorePointer(
          child: Align(
            alignment: Alignment(0, 0.45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 56,
                  shadows: _bayangan,
                ),
                Text(
                  'Ketuk untuk terbang!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: _bayangan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayHud extends StatelessWidget {
  const _OverlayHud({required this.game});

  final GameTerbang game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder<int>(
                valueListenable: game.skor,
                builder: (_, skor, _) => Text(
                  '$skor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    shadows: _bayangan,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: ValueListenableBuilder<int>(
                valueListenable: game.koin,
                builder: (_, koin, _) => JumlahKoin(koin, ukuran: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayKalah extends StatelessWidget {
  const _OverlayKalah({required this.game, required this.onKeBeranda});

  final GameTerbang game;
  final VoidCallback onKeBeranda;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF5D4037), width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'JATUH!',
                style: TextStyle(
                  color: Color(0xFFE64A19),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (game.rekorBaru)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🏆 REKOR BARU!',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Skor ${game.skor.value}',
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rekor ${game.rekor.value}',
                style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '+',
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  JumlahKoin(game.koin.value, warna: const Color(0xFF5D4037)),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: game.mainLagi,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Main Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onKeBeranda,
                icon: const Icon(Icons.home_rounded),
                label: const Text('Beranda'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5D4037),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
