import 'package:flutter/material.dart';

import 'game_utama.dart';
import 'level_config.dart';

/// Jeda antar level: animasi berhasil lalu tombol lanjut.
///
/// Urutan animasi (total 1,6 detik): latar memudar, trofi membal masuk,
/// tiga bintang muncul bergantian, lalu teks dan tombol naik perlahan.
class LevelSelesaiOverlay extends StatefulWidget {
  const LevelSelesaiOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  State<LevelSelesaiOverlay> createState() => _LevelSelesaiOverlayState();
}

class _LevelSelesaiOverlayState extends State<LevelSelesaiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final _latar = _interval(0.0, 0.2, Curves.easeOut);
  late final _trofi = _interval(0.1, 0.55, Curves.elasticOut);
  late final _bintang = [
    _interval(0.40, 0.65, Curves.elasticOut),
    _interval(0.50, 0.75, Curves.elasticOut),
    _interval(0.60, 0.85, Curves.elasticOut),
  ];
  late final _konten = _interval(0.70, 1.0, Curves.easeOutCubic);

  Animation<double> _interval(double mulai, double selesai, Curve curve) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(mulai, selesai, curve: curve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final level = game.level.value;
    final berikutnya = LevelConfig.forLevel(level + 1);
    final kenaikan =
        (berikutnya.kecepatanJebakan / game.levelConfig.kecepatanJebakan - 1) *
        100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => ColoredBox(
        color: Colors.black.withValues(alpha: 0.75 * _latar.value),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: _trofi.value,
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 120,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final bintang in _bintang)
                    Transform.scale(
                      scale: bintang.value,
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 44,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _konten.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - _konten.value)),
                  child: _buildKonten(game, level, kenaikan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKonten(GameUtama game, int level, double kenaikan) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LEVEL $level SELESAI!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${game.dihindariDiLevelIni.value} jebakan dihindari • '
          'Skor ${game.skor.value}',
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Level berikutnya ${kenaikan.round()}% lebih cepat',
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          // Tombol aktif setelah animasi hampir selesai, supaya tidak
          // tertekan tanpa sengaja oleh ketukan terakhir saat bermain.
          onPressed: _konten.value > 0.9 ? game.lanjutLevel : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Lanjut ke Level ${level + 1}'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
