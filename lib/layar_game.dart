import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'ads/banner_ad_slot.dart';
import 'ads/iklan_berhadiah.dart';
import 'ads/iklan_layar_penuh.dart';
import 'game/game_utama.dart';
import 'game/level_selesai_overlay.dart';
import 'game/overlays.dart';
import 'game/penyimpanan.dart';

/// Banner iklan di atas dan di bawah, game di tengah. Area game otomatis
/// menyesuaikan sisa layar, jadi pemain dan jebakan tidak tertutup iklan.
class LayarGame extends StatefulWidget {
  const LayarGame({super.key, this.showAds = true, this.penyimpanan});

  /// `false` untuk test, karena iklan butuh native view Android/iOS.
  final bool showAds;

  /// Tempat rekor & total koin disimpan. `null` = hanya di memori.
  final Penyimpanan? penyimpanan;

  @override
  State<LayarGame> createState() => _LayarGameState();
}

class _LayarGameState extends State<LayarGame> {
  IklanLayarPenuh? _iklanLayarPenuh;
  IklanBerhadiah? _iklanBerhadiah;

  // Dibuat sekali; membuat game baru di build() akan mereset permainan.
  late final _game = GameUtama(
    onGameOver: () => _iklanLayarPenuh?.gameOver(),
    penyimpanan: widget.penyimpanan,
    mulaiDiMenu: true,
  );

  @override
  void initState() {
    super.initState();
    if (widget.showAds) {
      _iklanLayarPenuh = IklanLayarPenuh()..muat();
      _iklanBerhadiah = IklanBerhadiah()..muat();
    }
  }

  @override
  void dispose() {
    _iklanLayarPenuh?.dispose();
    _iklanBerhadiah?.dispose();
    super.dispose();
  }

  GameOverOverlay _buatGameOver(GameUtama game) {
    final iklan = _iklanBerhadiah;
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
    return Scaffold(
      backgroundColor: Colors.black,
      // SafeArea di luar supaya iklan atas tidak tertutup status bar dan HUD
      // tidak menambah jarak status bar lagi.
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showAds) const BannerAdSlot(),
            Expanded(
              // Clip supaya jebakan yang lewat batas layar tidak menimpa iklan.
              child: ClipRect(
                child: GameWidget<GameUtama>(
                  game: _game,
                  initialActiveOverlays: const [GameUtama.overlayMenu],
                  // Tampil selama gambar mobil & jebakan dimuat.
                  loadingBuilder: (_) => const ColoredBox(
                    color: Color(0xFF4A4A4F),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  overlayBuilderMap: {
                    GameUtama.overlayMenu: (_, game) => MenuOverlay(game: game),
                    GameUtama.overlayHud: (_, game) => HudOverlay(game: game),
                    GameUtama.overlayJeda: (_, game) => JedaOverlay(game: game),
                    GameUtama.overlayLevelSelesai: (_, game) =>
                        LevelSelesaiOverlay(game: game),
                    GameUtama.overlayGameOver: (_, game) => _buatGameOver(game),
                  },
                ),
              ),
            ),
            if (widget.showAds) const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}
