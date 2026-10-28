import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game_utama.dart';

const _kuning = Colors.amber;

final _gayaTombolUtama = FilledButton.styleFrom(
  backgroundColor: _kuning,
  foregroundColor: Colors.black,
  minimumSize: const Size(220, 52),
  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
);

final _gayaTombolKedua = OutlinedButton.styleFrom(
  foregroundColor: Colors.white,
  side: const BorderSide(color: Colors.white54),
  minimumSize: const Size(220, 48),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
);

/// Ikon koin kecil + jumlah, dipakai di HUD, menu, garasi, dan Game Over.
class JumlahKoin extends StatelessWidget {
  const JumlahKoin(this.jumlah, {super.key, this.ukuran = 18});

  final int jumlah;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on, color: _kuning, size: ukuran + 4),
        const SizedBox(width: 4),
        Text(
          '$jumlah',
          style: TextStyle(
            color: Colors.white,
            fontSize: ukuran,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Layar awal: judul, rekor, total koin, dan tombol Main.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_filled, color: _kuning, size: 72),
            const Text(
              'KREN KAMU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'Hindari jebakan, kumpulkan koin!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ValueListenableBuilder<int>(
              valueListenable: game.rekor,
              builder: (_, rekor, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: _kuning),
                  const SizedBox(width: 6),
                  Text(
                    'Rekor $rekor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: game.totalKoin,
              builder: (_, total, _) => JumlahKoin(total, ukuran: 20),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: game.mulai,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('MAIN'),
              style: _gayaTombolUtama,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: game.bukaGarasi,
              icon: const Icon(Icons.garage_rounded),
              label: const Text('GARASI'),
              style: _gayaTombolKedua,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tahan tombol ◀ ▶ untuk menyetir',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Level, skor, sisa waktu, dan koin; tombol jeda di kanan atas; tombol
/// setir ◀ ▶ di bawah.
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
          children: [
            _buildAtas(gaya),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TombolSetir(
                  ikon: Icons.arrow_back_ios_new_rounded,
                  label: 'Kiri',
                  onTekan: (ditekan) => game.tekanKiri(ditekan: ditekan),
                ),
                _TombolSetir(
                  ikon: Icons.arrow_forward_ios_rounded,
                  label: 'Kanan',
                  onTekan: (ditekan) => game.tekanKanan(ditekan: ditekan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtas(TextStyle gaya) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
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
                sisa == 0
                    ? 'Menuju finish! 🏁'
                    : 'Sisa waktu ${_formatWaktu(sisa)}',
                style: gaya.copyWith(
                  color: sisa <= 5 ? Colors.orangeAccent : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ValueListenableBuilder<int>(
              valueListenable: game.koin,
              builder: (_, koin, _) => JumlahKoin(koin),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filled(
          onPressed: game.jeda,
          tooltip: 'Jeda',
          icon: const Icon(Icons.pause_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black38,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Tombol setir: mobil bergerak selama tombol ditahan.
///
/// Memakai [Listener] (bukan onPressed) supaya mobil langsung bergerak saat
/// jari menyentuh dan berhenti saat jari diangkat, dan kedua tombol bisa
/// ditekan bersamaan tanpa saling membatalkan.
class _TombolSetir extends StatefulWidget {
  const _TombolSetir({
    required this.ikon,
    required this.label,
    required this.onTekan,
  });

  final IconData ikon;
  final String label;
  final ValueChanged<bool> onTekan;

  @override
  State<_TombolSetir> createState() => _TombolSetirState();
}

class _TombolSetirState extends State<_TombolSetir> {
  bool _ditekan = false;

  void _ubah(bool ditekan) {
    if (_ditekan == ditekan) return;
    setState(() => _ditekan = ditekan);
    widget.onTekan(ditekan);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _ubah(true),
        onPointerUp: (_) => _ubah(false),
        onPointerCancel: (_) => _ubah(false),
        child: AnimatedScale(
          scale: _ditekan ? 0.92 : 1,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: 112,
            height: 84,
            decoration: BoxDecoration(
              color: _ditekan
                  ? _kuning.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Icon(
              widget.ikon,
              size: 40,
              color: _ditekan ? Colors.black : Colors.white,
            ),
          ),
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

/// Layar jeda: lanjut, main ulang, atau kembali ke menu.
class JedaOverlay extends StatelessWidget {
  const JedaOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'JEDA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: game.lanjutkanJeda,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Lanjut'),
              style: _gayaTombolUtama,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: game.mainLagi,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Main Ulang'),
              style: _gayaTombolKedua,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: game.kembaliKeMenu,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Menu Utama'),
              style: _gayaTombolKedua,
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar kalah: skor, rekor, koin, dan pilihan lanjut lewat iklan berhadiah.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.game,
    this.iklanSiap,
    this.onTontonIklan,
  });

  final GameUtama game;

  /// `true` saat iklan berhadiah siap ditonton. `null` = tanpa iklan.
  final ValueListenable<bool>? iklanSiap;

  /// Menampilkan iklan berhadiah; hadiahnya [GameUtama.lanjutSetelahIklan].
  final VoidCallback? onTontonIklan;

  @override
  Widget build(BuildContext context) {
    final rekorBaru = game.rekorBaru;
    final iklanSiap = this.iklanSiap;
    final onTontonIklan = this.onTontonIklan;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.65),
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
            const SizedBox(height: 12),
            if (rekorBaru)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _kuning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🏆 REKOR BARU!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Skor ${game.skor.value} • Level ${game.level.value}',
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            if (!rekorBaru)
              Text(
                'Rekor ${game.rekor.value}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                JumlahKoin(game.koin.value),
              ],
            ),
            const SizedBox(height: 28),
            if (iklanSiap != null &&
                onTontonIklan != null &&
                game.bisaLanjutDenganIklan)
              ValueListenableBuilder<bool>(
                valueListenable: iklanSiap,
                builder: (_, siap, _) => siap
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FilledButton.icon(
                          onPressed: onTontonIklan,
                          icon: const Icon(Icons.smart_display_rounded),
                          label: const Text('Lanjut (Tonton Iklan)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(220, 52),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            FilledButton.icon(
              onPressed: game.mainLagi,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Main Lagi'),
              style: _gayaTombolUtama,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: game.kembaliKeMenu,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Menu Utama'),
              style: _gayaTombolKedua,
            ),
          ],
        ),
      ),
    );
  }
}
