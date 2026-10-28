import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'ads/banner_ad_slot.dart';
import 'game/game_utama.dart';
import 'game/level_selesai_overlay.dart';
import 'game/overlays.dart';

/// Banner iklan di atas dan di bawah, game di tengah. Area game otomatis
/// menyesuaikan sisa layar, jadi pemain dan jebakan tidak tertutup iklan.
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
                  initialActiveOverlays: const [GameUtama.overlayHud],
                  // Tampil selama gambar mobil & jebakan dimuat.
                  loadingBuilder: (_) => const ColoredBox(
                    color: Color(0xFF4A4A4F),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
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
      ),
    );
  }
}
