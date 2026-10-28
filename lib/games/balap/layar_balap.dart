import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../bersama/layanan.dart';
import '../../bersama/layar_dengan_banner.dart';
import 'game_utama.dart';
import 'garasi_overlay.dart';
import 'level_selesai_overlay.dart';
import 'misi_overlay.dart';
import 'overlays.dart';

/// Game Balap Kren: banner iklan di atas dan di bawah, game di tengah.
class LayarBalap extends StatefulWidget {
  const LayarBalap({super.key, required this.layanan});

  final Layanan layanan;

  @override
  State<LayarBalap> createState() => _LayarBalapState();
}

class _LayarBalapState extends State<LayarBalap> {
  // Dibuat sekali; membuat game baru di build() akan mereset permainan.
  late final _game = GameUtama(
    onGameOver: () => widget.layanan.iklan?.layarPenuh.gameOver(),
    penyimpanan: widget.layanan.penyimpanan,
    dompet: widget.layanan.dompet,
    jam: widget.layanan.jam,
    mulaiDiMenu: true,
  );

  @override
  void dispose() {
    // Ditutup di tengah permainan: koin & rekor yang sudah didapat tetap
    // disimpan.
    _game.simpanHasil();
    super.dispose();
  }

  GameOverOverlay _buatGameOver(GameUtama game) {
    final iklan = widget.layanan.iklan?.berhadiah;
    return GameOverOverlay(
      game: game,
      iklanSiap: iklan?.siap,
      onTontonIklan: iklan == null
          ? null
          : () => iklan.tampilkan(onHadiah: game.lanjutSetelahIklan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayarDenganBanner(
      layanan: widget.layanan,
      bannerAtas: true,
      child: GameWidget<GameUtama>(
        game: _game,
        initialActiveOverlays: const [GameUtama.overlayMenu],
        // Tampil selama gambar mobil & jebakan dimuat.
        loadingBuilder: (_) => const ColoredBox(
          color: Color(0xFF4A4A4F),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        overlayBuilderMap: {
          GameUtama.overlayMenu: (_, game) => MenuOverlay(
            game: game,
            onKeBeranda: () => Navigator.of(context).maybePop(),
          ),
          GameUtama.overlayGarasi: (_, game) => GarasiOverlay(game: game),
          GameUtama.overlayMisi: (_, game) => MisiOverlay(game: game),
          GameUtama.overlayHud: (_, game) => HudOverlay(game: game),
          GameUtama.overlayJeda: (_, game) => JedaOverlay(game: game),
          GameUtama.overlayLevelSelesai: (_, game) =>
              LevelSelesaiOverlay(game: game),
          GameUtama.overlayGameOver: (_, game) => _buatGameOver(game),
        },
      ),
    );
  }
}
