import 'package:flutter/foundation.dart';

import 'dompet.dart';
import 'penyimpanan.dart';

/// `2026-10-28` (waktu lokal), dipakai sebagai kunci hari.
String kunciHari(DateTime waktu) =>
    '${waktu.year}-${waktu.month.toString().padLeft(2, '0')}-'
    '${waktu.day.toString().padLeft(2, '0')}';

/// Koin gratis sekali sehari. Hadiah naik bila diklaim beberapa hari
/// berturut-turut, dan kembali ke hari 1 bila ada hari yang terlewat.
class HadiahHarian {
  HadiahHarian(this._penyimpanan, this._dompet, {DateTime Function()? jam})
    : _jam = jam ?? DateTime.now {
    tersedia = ValueNotifier(_cekTersedia());
  }

  /// Hadiah hari ke-1 sampai ke-7; setelah hari ke-7 kembali ke hari ke-1.
  static const hadiah = [10, 15, 20, 30, 40, 60, 100];

  static const _kunciTanggal = 'hadiah_tanggal';
  static const _kunciHari = 'hadiah_hari';

  final Penyimpanan _penyimpanan;
  final Dompet _dompet;
  final DateTime Function() _jam;

  /// `true` bila hadiah hari ini belum diklaim.
  late final ValueNotifier<bool> tersedia;

  String? get _tanggalTerakhir => _penyimpanan.bacaTeks(_kunciTanggal);

  bool _cekTersedia() => _tanggalTerakhir != kunciHari(_jam());

  /// Hari ke berapa (1–7) hadiah yang bisa diklaim sekarang.
  int get hariKe {
    final hariTerakhir = _penyimpanan.bacaInt(_kunciHari) ?? 0;
    final sekarang = _jam();
    final kemarin = DateTime(sekarang.year, sekarang.month, sekarang.day - 1);
    final beruntun = _tanggalTerakhir == kunciHari(kemarin);
    return beruntun ? hariTerakhir % hadiah.length + 1 : 1;
  }

  int get hadiahHariIni => hadiah[hariKe - 1];

  /// Mengklaim hadiah hari ini; mengembalikan jumlah koin (0 jika sudah).
  int klaim() {
    if (!_cekTersedia()) {
      tersedia.value = false;
      return 0;
    }
    final hari = hariKe;
    final jumlah = hadiah[hari - 1];
    _dompet.tambah(jumlah);
    _penyimpanan
      ..tulisTeks(_kunciTanggal, kunciHari(_jam()))
      ..tulisInt(_kunciHari, hari);
    tersedia.value = false;
    return jumlah;
  }

  /// Dipanggil saat kembali ke menu, untuk hari yang berganti saat game
  /// masih terbuka.
  void periksaLagi() => tersedia.value = _cekTersedia();

  void dispose() => tersedia.dispose();
}
