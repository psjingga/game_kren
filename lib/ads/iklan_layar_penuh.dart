import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Iklan video layar penuh (interstitial) yang tampil saat game over.
///
/// Iklan dimuat lebih dulu supaya langsung muncul tanpa menunggu. Kalau
/// belum siap (misalnya tanpa internet), game over berjalan seperti biasa.
class IklanLayarPenuh {
  InterstitialAd? _iklan;
  int _jumlahGameOver = 0;
  bool _dibuang = false;

  void muat() {
    if (!AdConfig.isInterstitialEnabled || _dibuang) return;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (iklan) {
          if (_dibuang) {
            iklan.dispose();
            return;
          }
          _iklan = iklan;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Iklan layar penuh gagal dimuat: ${error.message}');
        },
      ),
    );
  }

  /// Dipanggil setiap game over; iklan tampil tiap
  /// [AdConfig.interstitialSetiapGameOver] kali.
  void gameOver() {
    _jumlahGameOver++;
    if (_jumlahGameOver % AdConfig.interstitialSetiapGameOver != 0) return;

    final iklan = _iklan;
    if (iklan == null) {
      muat(); // coba lagi untuk game over berikutnya
      return;
    }
    _iklan = null;
    iklan.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (iklan) {
        iklan.dispose();
        muat(); // siapkan iklan untuk game over berikutnya
      },
      onAdFailedToShowFullScreenContent: (iklan, error) {
        debugPrint('Iklan layar penuh gagal tampil: ${error.message}');
        iklan.dispose();
        muat();
      },
    );
    iklan.show();
  }

  void dispose() {
    _dibuang = true;
    _iklan?.dispose();
    _iklan = null;
  }
}
