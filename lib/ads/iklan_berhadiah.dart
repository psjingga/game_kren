import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Iklan berhadiah (rewarded): pemain memilih menonton iklan sampai selesai
/// untuk mendapat hadiah, di game ini lanjut main setelah tertabrak.
class IklanBerhadiah {
  RewardedAd? _iklan;
  bool _dibuang = false;

  /// `true` saat iklan sudah dimuat dan tombol "tonton iklan" boleh tampil.
  final siap = ValueNotifier<bool>(false);

  void muat() {
    if (!AdConfig.isRewardedEnabled || _dibuang || _iklan != null) return;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (iklan) {
          if (_dibuang) {
            iklan.dispose();
            return;
          }
          _iklan = iklan;
          siap.value = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Iklan berhadiah gagal dimuat: ${error.message}');
        },
      ),
    );
  }

  /// Menampilkan iklan. [onHadiah] dipanggil setelah iklan ditutup, hanya
  /// jika pemain menontonnya sampai mendapat hadiah.
  void tampilkan({required VoidCallback onHadiah}) {
    final iklan = _iklan;
    if (iklan == null) return;
    _iklan = null;
    siap.value = false;

    var dapatHadiah = false;
    iklan.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (iklan) {
        iklan.dispose();
        if (dapatHadiah) onHadiah();
        muat(); // siapkan untuk permainan berikutnya
      },
      onAdFailedToShowFullScreenContent: (iklan, error) {
        debugPrint('Iklan berhadiah gagal tampil: ${error.message}');
        iklan.dispose();
        muat();
      },
    );
    iklan.show(onUserEarnedReward: (_, _) => dapatHadiah = true);
  }

  void dispose() {
    _dibuang = true;
    _iklan?.dispose();
    _iklan = null;
    siap.dispose();
  }
}
