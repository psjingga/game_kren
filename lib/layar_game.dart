import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'ads/banner_ad_slot.dart';
import 'game/game_utama.dart';
import 'game/level_selesai_overlay.dart';
import 'game/overlays.dart';

/// Game di atas, banner iklan di bawah. Area game otomatis menyesuaikan
/// sisa layar, jadi pemain dan meteor tidak tertutup iklan.
class LayarGame extends StatefulWidget {
  const LayarGame({super.key, this.showAds = true});

  /// `false` untuk test, karena iklan butuh native view Android/iOS.
  final bool showAds;

  @override
  State<LayarGame> createState() => _LayarGameState();
}

class _LayarGameState extends State<LayarGame> {
  // Dibuat sekali; membuat game baru di build() akan mereset permainan.
  final _game = GameUtama();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            // Clip supaya meteor yang lewat batas bawah tidak menimpa iklan.
            child: ClipRect(
              child: GameWidget<GameUtama>(
                game: _game,
                initialActiveOverlays: const [GameUtama.overlayHud],
                overlayBuilderMap: {
                  GameUtama.overlayHud: (_, game) => HudOverlay(game: game),
                  GameUtama.overlayLevelSelesai: (_, game) =>
                      LevelSelesaiOverlay(game: game),
                  GameUtama.overlayGameOver: (_, game) =>
                      GameOverOverlay(game: game),
                },
              ),
            ),
          ),
          if (widget.showAds) const BannerAdSlot(),
        ],
      ),
    );
  }
}
