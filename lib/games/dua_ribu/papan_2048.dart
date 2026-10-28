import 'dart:math';

enum Arah { kiri, kanan, atas, bawah }

/// Papan 4×4 game 2048, tanpa tampilan. `0` = kotak kosong.
class Papan2048 {
  Papan2048({Random? random, List<int>? sel, this.skor = 0})
    : _random = random ?? Random(),
      sel = sel ?? List.filled(jumlahSel, 0) {
    if (sel == null) {
      _tambahUbin();
      _tambahUbin();
    }
  }

  static const sisi = 4;
  static const jumlahSel = sisi * sisi;

  final Random _random;
  final List<int> sel;
  int skor;

  /// Indeks ubin baru setelah geseran terakhir (untuk animasi muncul).
  int? ubinBaru;

  /// Indeks ubin hasil gabungan pada geseran terakhir (untuk animasi).
  final digabung = <int>{};

  int get ubinTerbesar => sel.reduce(max);

  /// Masih ada kotak kosong atau dua ubin bersebelahan yang sama.
  bool get bisaGerak {
    if (sel.contains(0)) return true;
    for (var i = 0; i < jumlahSel; i++) {
      final kanan = i % sisi < sisi - 1 ? sel[i + 1] : -1;
      final bawah = i + sisi < jumlahSel ? sel[i + sisi] : -1;
      if (sel[i] == kanan || sel[i] == bawah) return true;
    }
    return false;
  }

  /// Indeks sel per baris/kolom, diurutkan searah geseran (sel pertama di
  /// setiap daftar adalah tujuan geser).
  static List<List<int>> _garis(Arah arah) {
    return [
      for (var a = 0; a < sisi; a++)
        [
          for (var b = 0; b < sisi; b++)
            switch (arah) {
              Arah.kiri => a * sisi + b,
              Arah.kanan => a * sisi + (sisi - 1 - b),
              Arah.atas => b * sisi + a,
              Arah.bawah => (sisi - 1 - b) * sisi + a,
            },
        ],
    ];
  }

  /// Menggeser semua ubin ke [arah]. Ubin sama yang bertemu bergabung sekali
  /// per geseran dan menambah skor. Jika ada yang bergerak, satu ubin baru
  /// muncul. Mengembalikan `false` jika tidak ada yang bergerak.
  bool geser(Arah arah) {
    digabung.clear();
    ubinBaru = null;
    var bergerak = false;

    for (final garis in _garis(arah)) {
      final (:hasil, :poin, :gabung) = gabungGaris([
        for (final i in garis) sel[i],
      ]);
      skor += poin;
      for (var k = 0; k < sisi; k++) {
        if (sel[garis[k]] != hasil[k]) bergerak = true;
        sel[garis[k]] = hasil[k];
      }
      digabung.addAll(gabung.map((k) => garis[k]));
    }

    if (bergerak) _tambahUbin();
    return bergerak;
  }

  /// Menggeser satu baris/kolom ke arah indeks 0: ubin merapat, dan dua
  /// ubin sama yang bertemu bergabung (setiap ubin hanya sekali).
  /// [gabung] berisi indeks (di [hasil]) ubin hasil gabungan.
  static ({List<int> hasil, int poin, List<int> gabung}) gabungGaris(
    List<int> garis,
  ) {
    final isi = garis.where((n) => n != 0).toList();
    final hasil = <int>[];
    final gabung = <int>[];
    var poin = 0;
    for (var k = 0; k < isi.length; k++) {
      if (k + 1 < isi.length && isi[k] == isi[k + 1]) {
        final nilai = isi[k] * 2;
        poin += nilai;
        gabung.add(hasil.length);
        hasil.add(nilai);
        k++;
      } else {
        hasil.add(isi[k]);
      }
    }
    while (hasil.length < garis.length) {
      hasil.add(0);
    }
    return (hasil: hasil, poin: poin, gabung: gabung);
  }

  /// Ubin 2 (90%) atau 4 (10%) di kotak kosong acak.
  void _tambahUbin() {
    final kosong = [
      for (var i = 0; i < jumlahSel; i++)
        if (sel[i] == 0) i,
    ];
    if (kosong.isEmpty) return;
    final i = kosong[_random.nextInt(kosong.length)];
    sel[i] = _random.nextDouble() < 0.9 ? 2 : 4;
    ubinBaru = i;
  }
}
