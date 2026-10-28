import 'package:flutter/foundation.dart';

import 'penyimpanan.dart';

/// Total koin pemain sepanjang masa. Setiap perubahan langsung disimpan.
class Dompet {
  Dompet(this._penyimpanan)
    : saldo = ValueNotifier(_penyimpanan.bacaInt(KunciSimpan.totalKoin) ?? 0);

  final Penyimpanan _penyimpanan;
  final ValueNotifier<int> saldo;

  void tambah(int jumlah) {
    if (jumlah <= 0) return;
    saldo.value += jumlah;
    _simpan();
  }

  /// `false` (tanpa mengubah saldo) jika koin tidak cukup.
  bool bayar(int jumlah) {
    if (saldo.value < jumlah) return false;
    saldo.value -= jumlah;
    _simpan();
    return true;
  }

  void _simpan() => _penyimpanan.tulisInt(KunciSimpan.totalKoin, saldo.value);

  void dispose() => saldo.dispose();
}
