import 'dart:io';

import 'package:flutter/foundation.dart';

/// Satu-satunya tempat ID unit iklan.
///
/// - Debug/profile (`fvm flutter run`): selalu memakai ID test Google, aman
///   diklik dan tidak butuh akun AdMob.
/// - Release (`fvm flutter build ... --release`): memakai ID asli di bawah.
///   Selama ID asli masih kosong, iklan tersebut tidak ditampilkan di build
///   release.
abstract class AdConfig {
  // TODO: isi dengan ID unit iklan banner asli dari AdMob.
  static const _bannerAndroidAsli = '';
  static const _bannerIosAsli = '';

  // TODO: isi dengan ID unit iklan interstitial (layar penuh) asli dari
  // AdMob. Aktifkan jenis iklan video saat membuat unitnya.
  static const _interstitialAndroidAsli = '';
  static const _interstitialIosAsli = '';

  // TODO: isi dengan ID unit iklan berhadiah (rewarded) asli dari AdMob.
  static const _rewardedAndroidAsli = '';
  static const _rewardedIosAsli = '';

  static const _bannerAndroidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _bannerIosTest = 'ca-app-pub-3940256099942544/2934735716';

  // ID test Google untuk interstitial video.
  static const _interstitialAndroidTest =
      'ca-app-pub-3940256099942544/8691691433';
  static const _interstitialIosTest = 'ca-app-pub-3940256099942544/5135589807';

  static const _rewardedAndroidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _rewardedIosTest = 'ca-app-pub-3940256099942544/1712485313';

  /// Iklan layar penuh muncul setiap kali game over ke-N. `1` = setiap game
  /// over. Dibuat jarang karena pemain sudah bisa memilih iklan berhadiah
  /// untuk lanjut main.
  static const interstitialSetiapGameOver = 3;

  /// ID perangkat yang selalu menerima iklan test walaupun memakai ID asli.
  /// ID muncul di log saat aplikasi jalan di HP, cari teks "test device".
  static const testDeviceIds = <String>[];

  static bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerAdUnitId {
    if (!kReleaseMode) {
      return Platform.isAndroid ? _bannerAndroidTest : _bannerIosTest;
    }
    return Platform.isAndroid ? _bannerAndroidAsli : _bannerIosAsli;
  }

  static bool get isBannerEnabled =>
      isSupportedPlatform && bannerAdUnitId.isNotEmpty;

  static String get interstitialAdUnitId {
    if (!kReleaseMode) {
      return Platform.isAndroid
          ? _interstitialAndroidTest
          : _interstitialIosTest;
    }
    return Platform.isAndroid ? _interstitialAndroidAsli : _interstitialIosAsli;
  }

  static bool get isInterstitialEnabled =>
      isSupportedPlatform && interstitialAdUnitId.isNotEmpty;

  static String get rewardedAdUnitId {
    if (!kReleaseMode) {
      return Platform.isAndroid ? _rewardedAndroidTest : _rewardedIosTest;
    }
    return Platform.isAndroid ? _rewardedAndroidAsli : _rewardedIosAsli;
  }

  static bool get isRewardedEnabled =>
      isSupportedPlatform && rewardedAdUnitId.isNotEmpty;
}
