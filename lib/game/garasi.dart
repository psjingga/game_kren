import 'package:flutter/foundation.dart';

import 'dompet.dart';
import 'penyimpanan.dart';

/// Satu mobil di garasi.
class DataMobil {
  const DataMobil({required this.id, required this.nama, required this.harga});

  final String id;
  final String nama;

  /// Harga dalam koin; `0` = gratis (mobil awal).
  final int harga;

  /// Gambar di `assets/images/`.
  String get file => 'mobil_$id.svg';
}

/// Daftar mobil, urut dari yang termurah. Tambah mobil baru di sini dan
/// buat gambarnya `assets/images/mobil_<id>.svg` (ukuran 52x80, menghadap
/// ke atas).
const daftarMobil = [
  DataMobil(id: 'biru', nama: 'Sport Biru', harga: 0),
  DataMobil(id: 'taksi', nama: 'Taksi', harga: 50),
  DataMobil(id: 'polisi', nama: 'Polisi', harga: 120),
  DataMobil(id: 'balap', nama: 'Balap F1', harga: 250),
  DataMobil(id: 'mewah', nama: 'Hitam Emas', harga: 500),
];

/// Hasil menekan tombol di kartu mobil.
enum HasilBeli { berhasil, koinKurang, sudahPunya }

/// Mobil yang dimiliki dan dipakai, dibeli dengan koin.
class Garasi {
  Garasi(this._penyimpanan, this._dompet)
    : dimiliki = ValueNotifier({
        daftarMobil.first.id,
        ...?_penyimpanan.bacaDaftar(_kunciDimiliki),
      }),
      dipakai = ValueNotifier(_penyimpanan.bacaTeks(_kunciDipakai) ?? '') {
    // Belum pernah memilih, atau data rusak: kembali ke mobil awal.
    if (!dimiliki.value.contains(dipakai.value)) {
      dipakai.value = daftarMobil.first.id;
    }
  }

  static const _kunciDimiliki = 'mobil_dimiliki';
  static const _kunciDipakai = 'mobil_dipakai';

  final Penyimpanan _penyimpanan;
  final Dompet _dompet;

  final ValueNotifier<Set<String>> dimiliki;
  final ValueNotifier<String> dipakai;

  DataMobil get mobilDipakai =>
      daftarMobil.firstWhere((m) => m.id == dipakai.value);

  bool punya(String id) => dimiliki.value.contains(id);

  /// Membeli mobil dengan koin lalu langsung memakainya.
  HasilBeli beli(DataMobil mobil) {
    if (punya(mobil.id)) return HasilBeli.sudahPunya;
    if (!_dompet.bayar(mobil.harga)) return HasilBeli.koinKurang;

    dimiliki.value = {...dimiliki.value, mobil.id};
    _penyimpanan.tulisDaftar(_kunciDimiliki, dimiliki.value.toList());
    _pakai(mobil.id);
    return HasilBeli.berhasil;
  }

  void pakai(DataMobil mobil) {
    if (!punya(mobil.id) || dipakai.value == mobil.id) return;
    _pakai(mobil.id);
  }

  void _pakai(String id) {
    dipakai.value = id;
    _penyimpanan.tulisTeks(_kunciDipakai, id);
  }

  void dispose() {
    dimiliki.dispose();
    dipakai.dispose();
  }
}
