import 'dart:io';

import 'package:flutter/foundation.dart';

/// Satu-satunya tempat ID unit iklan.
///
/// - Debug/profile (`fvm flutter run`): selalu memakai ID test Google, aman
///   diklik dan tidak butuh akun AdMob.
/// - Release (`fvm flutter build ... --release`): memakai ID asli di bawah.
///   Selama ID asli masih kosong, banner tidak ditampilkan di build release.
abstract class AdConfig {
  // TODO: isi dengan ID unit iklan banner asli dari AdMob.
  static const _bannerAndroidAsli = '';
  static const _bannerIosAsli = '';

  static const _bannerAndroidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _bannerIosTest = 'ca-app-pub-3940256099942544/2934735716';

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
}
