import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/ad_config.dart';
import 'ads/layanan_iklan.dart';
import 'beranda.dart';
import 'bersama/layanan.dart';
import 'bersama/penyimpanan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Semua game dibuat untuk posisi HP tegak.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final adaIklan = AdConfig.isSupportedPlatform;
  if (adaIklan) {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
    );
  }
  final layanan = Layanan(
    penyimpanan: await PenyimpananHp.buka(),
    iklan: adaIklan ? (LayananIklan()..muat()) : null,
    tampilkanBanner: adaIklan,
  );
  runApp(
    MaterialApp(
      title: 'Kren Kamu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: Beranda(layanan: layanan),
    ),
  );
}
