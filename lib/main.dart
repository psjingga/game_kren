import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/ad_config.dart';
import 'layar_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AdConfig.isSupportedPlatform) {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
    );
  }
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LayarGame()),
  );
}
