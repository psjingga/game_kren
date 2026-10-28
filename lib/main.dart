import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/ad_config.dart';
import 'game/penyimpanan.dart';
import 'layar_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Jalan memanjang ke atas: game hanya untuk posisi HP tegak.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (AdConfig.isSupportedPlatform) {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
    );
  }
  final penyimpanan = await PenyimpananHp.buka();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LayarGame(penyimpanan: penyimpanan),
    ),
  );
}
