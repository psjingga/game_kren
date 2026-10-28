import '../ads/layanan_iklan.dart';
import 'dompet.dart';
import 'hadiah_harian.dart';
import 'penyimpanan.dart';

/// Semua yang dipakai bersama oleh beranda dan setiap game: penyimpanan,
/// koin, hadiah harian, dan iklan.
class Layanan {
  Layanan({
    required this.penyimpanan,
    this.iklan,
    this.tampilkanBanner = true,
    this.jam,
  }) : dompet = Dompet(penyimpanan) {
    hadiahHarian = HadiahHarian(penyimpanan, dompet, jam: jam);
  }

  /// Untuk test: tanpa iklan dan data hanya di memori.
  factory Layanan.uji({DateTime Function()? jam}) => Layanan(
    penyimpanan: PenyimpananMemori(),
    tampilkanBanner: false,
    jam: jam,
  );

  final Penyimpanan penyimpanan;
  final Dompet dompet;
  late final HadiahHarian hadiahHarian;

  /// `null` = tanpa iklan layar penuh & berhadiah (test, platform lain).
  final LayananIklan? iklan;

  /// `false` di test, karena banner butuh native view Android/iOS.
  final bool tampilkanBanner;

  final DateTime Function()? jam;

  void dispose() {
    iklan?.dispose();
    hadiahHarian.dispose();
    dompet.dispose();
  }
}
