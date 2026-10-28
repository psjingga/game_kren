import 'dart:math';

import 'package:flutter/foundation.dart';

import 'dompet.dart';
import 'hadiah_harian.dart';
import 'penyimpanan.dart';

enum JenisMisi { koin, jam, hindari, nyaris, powerUp, level }

/// Pilihan target & hadiah untuk setiap jenis misi.
const _pilihanMisi = <JenisMisi, List<(int target, int hadiah)>>{
  JenisMisi.koin: [(30, 25), (60, 50)],
  JenisMisi.jam: [(3, 20), (6, 40)],
  JenisMisi.hindari: [(40, 25), (80, 50)],
  JenisMisi.nyaris: [(3, 30), (6, 50)],
  JenisMisi.powerUp: [(2, 25), (4, 45)],
  JenisMisi.level: [(2, 30), (4, 60)],
};

class Misi {
  const Misi({
    required this.jenis,
    required this.target,
    required this.hadiah,
    this.progres = 0,
    this.diklaim = false,
  });

  final JenisMisi jenis;
  final int target;
  final int hadiah;
  final int progres;
  final bool diklaim;

  bool get selesai => progres >= target;
  bool get bisaDiklaim => selesai && !diklaim;

  String get deskripsi => switch (jenis) {
    JenisMisi.koin => 'Ambil $target koin',
    JenisMisi.jam => 'Ambil $target jam',
    JenisMisi.hindari => 'Hindari $target jebakan',
    JenisMisi.nyaris => 'Lewati $target jebakan dengan NYARIS',
    JenisMisi.powerUp => 'Ambil $target power-up',
    JenisMisi.level => 'Selesaikan level $target',
  };

  Misi salin({int? progres, bool? diklaim}) => Misi(
    jenis: jenis,
    target: target,
    hadiah: hadiah,
    progres: progres ?? this.progres,
    diklaim: diklaim ?? this.diklaim,
  );
}

/// Tiga misi berbeda setiap hari, dipilih acak dari tanggal (sama untuk
/// hari yang sama). Progres dan klaim disimpan; berganti saat hari berganti.
class MisiHarian {
  MisiHarian(this._penyimpanan, this._dompet, {DateTime Function()? jam})
    : _jam = jam ?? DateTime.now {
    daftar = ValueNotifier(_muat());
  }

  static const jumlahMisi = 3;

  static const _kunciTanggal = 'misi_tanggal';
  static const _kunciProgres = 'misi_progres';
  static const _kunciDiklaim = 'misi_diklaim';

  final Penyimpanan _penyimpanan;
  final Dompet _dompet;
  final DateTime Function() _jam;
  late String _hari;

  late final ValueNotifier<List<Misi>> daftar;

  /// Jumlah misi selesai yang hadiahnya belum diambil (untuk lencana menu).
  int get jumlahBisaDiklaim => daftar.value.where((m) => m.bisaDiklaim).length;

  List<Misi> _muat() {
    _hari = kunciHari(_jam());
    final misi = _buatMisi(_hari);
    if (_penyimpanan.bacaTeks(_kunciTanggal) != _hari) return misi;

    final progres = _penyimpanan.bacaDaftar(_kunciProgres) ?? const [];
    final diklaim = _penyimpanan.bacaDaftar(_kunciDiklaim) ?? const [];
    return [
      for (var i = 0; i < misi.length; i++)
        misi[i].salin(
          progres: i < progres.length ? int.tryParse(progres[i]) ?? 0 : 0,
          diklaim: i < diklaim.length && diklaim[i] == '1',
        ),
    ];
  }

  static List<Misi> _buatMisi(String hari) {
    // Seed dari tanggal (mis. 20261028) supaya misi sama sepanjang hari.
    final random = Random(int.parse(hari.replaceAll('-', '')));
    final jenis = [...JenisMisi.values]..shuffle(random);
    return [
      for (final j in jenis.take(jumlahMisi))
        () {
          final pilihan = _pilihanMisi[j]!;
          final (target, hadiah) = pilihan[random.nextInt(pilihan.length)];
          return Misi(jenis: j, target: target, hadiah: hadiah);
        }(),
    ];
  }

  /// Hari berganti saat game masih terbuka: misi baru.
  void _cekHari() {
    if (kunciHari(_jam()) != _hari) daftar.value = _muat();
  }

  /// Menambah progres misi berjenis [jenis].
  void catat(JenisMisi jenis, [int jumlah = 1]) {
    _ubah(jenis, (m) => m.progres + jumlah);
  }

  /// Level [level] selesai: misi "Selesaikan level N" tercapai bila N ≤ level.
  void catatLevel(int level) {
    _ubah(JenisMisi.level, (m) => max(m.progres, level));
  }

  void _ubah(JenisMisi jenis, int Function(Misi) progresBaru) {
    _cekHari();
    var berubah = false;
    final baru = [
      for (final m in daftar.value)
        if (m.jenis == jenis && !m.selesai)
          () {
            berubah = true;
            return m.salin(progres: min(progresBaru(m), m.target));
          }()
        else
          m,
    ];
    if (!berubah) return;
    daftar.value = baru;
    _simpan();
  }

  /// Mengambil hadiah misi ke-[indeks]; mengembalikan jumlah koin.
  int klaim(int indeks) {
    _cekHari();
    final misi = daftar.value[indeks];
    if (!misi.bisaDiklaim) return 0;
    _dompet.tambah(misi.hadiah);
    daftar.value = [
      for (var i = 0; i < daftar.value.length; i++)
        i == indeks ? misi.salin(diklaim: true) : daftar.value[i],
    ];
    _simpan();
    return misi.hadiah;
  }

  void _simpan() {
    _penyimpanan
      ..tulisTeks(_kunciTanggal, _hari)
      ..tulisDaftar(_kunciProgres, [
        for (final m in daftar.value) '${m.progres}',
      ])
      ..tulisDaftar(_kunciDiklaim, [
        for (final m in daftar.value) m.diklaim ? '1' : '0',
      ]);
  }

  void dispose() => daftar.dispose();
}
