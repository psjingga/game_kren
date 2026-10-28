import 'package:flutter/material.dart';

import '../../bersama/jumlah_koin.dart';
import 'game_utama.dart';
import 'misi.dart';

/// Layar misi harian: tiga misi dengan progres dan tombol klaim hadiah.
class MisiOverlay extends StatelessWidget {
  const MisiOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([game.misi.daftar, game.totalKoin]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          game.kembaliDariLayar(GameUtama.overlayMisi),
                      tooltip: 'Kembali',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                    const Text(
                      'MISI HARIAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    JumlahKoin(game.totalKoin.value, ukuran: 20),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Misi baru setiap hari. Selesaikan sambil bermain, lalu '
                  'ambil hadiahnya di sini.',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: game.misi.daftar.value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _KartuMisi(
                    misi: game.misi.daftar.value[i],
                    onKlaim: () => _klaim(context, i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _klaim(BuildContext context, int indeks) {
    final jumlah = game.misi.klaim(indeks);
    if (jumlah == 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('+$jumlah koin!'),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _KartuMisi extends StatelessWidget {
  const _KartuMisi({required this.misi, required this.onKlaim});

  final Misi misi;
  final VoidCallback onKlaim;

  static IconData _ikon(JenisMisi jenis) => switch (jenis) {
    JenisMisi.koin => Icons.monetization_on,
    JenisMisi.jam => Icons.timer_rounded,
    JenisMisi.hindari => Icons.warning_amber_rounded,
    JenisMisi.nyaris => Icons.bolt_rounded,
    JenisMisi.powerUp => Icons.auto_awesome_rounded,
    JenisMisi.level => Icons.sports_score_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: misi.bisaDiklaim ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: misi.bisaDiklaim ? Colors.amber : Colors.white24,
          width: misi.bisaDiklaim ? 2.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white12,
            child: Icon(_ikon(misi.jenis), color: Colors.amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  misi.deskripsi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: misi.progres / misi.target,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    color: misi.selesai ? Colors.green : Colors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${misi.progres} / ${misi.target}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (misi.diklaim)
            const Icon(Icons.check_circle, color: Colors.green, size: 32)
          else
            FilledButton(
              onPressed: misi.bisaDiklaim ? onKlaim : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${misi.hadiah}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
