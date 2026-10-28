import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';
import 'layanan.dart';

/// Kerangka layar dengan banner iklan di bawah (dan opsional di atas).
/// Isi layar mengisi sisa ruang, jadi tidak pernah tertutup iklan.
class LayarDenganBanner extends StatelessWidget {
  const LayarDenganBanner({
    super.key,
    required this.layanan,
    required this.child,
    this.bannerAtas = false,
    this.warnaLatar = Colors.black,
  });

  final Layanan layanan;
  final Widget child;
  final bool bannerAtas;
  final Color warnaLatar;

  @override
  Widget build(BuildContext context) {
    final banner = layanan.tampilkanBanner;
    return Scaffold(
      backgroundColor: warnaLatar,
      // SafeArea di luar supaya iklan atas tidak tertutup status bar dan isi
      // layar tidak menambah jarak status bar lagi.
      body: SafeArea(
        child: Column(
          children: [
            if (banner && bannerAtas) const BannerAdSlot(),
            // Clip supaya benda game yang lewat tepi tidak menimpa iklan.
            Expanded(child: ClipRect(child: child)),
            if (banner) const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}
