import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/bersama/dompet.dart';
import 'package:game_kren_kamu/bersama/hadiah_harian.dart';
import 'package:game_kren_kamu/games/balap/misi.dart';
import 'package:game_kren_kamu/bersama/penyimpanan.dart';

/// Jam palsu yang bisa dimajukan per hari.
class _Jam {
  DateTime sekarang = DateTime(2026, 10, 28, 9);
  DateTime call() => sekarang;
  void besok() => sekarang = sekarang.add(const Duration(days: 1));
}

void main() {
  group('Hadiah harian', () {
    late PenyimpananMemori penyimpanan;
    late Dompet dompet;
    late _Jam jam;

    HadiahHarian buat() => HadiahHarian(penyimpanan, dompet, jam: jam.call);

    setUp(() {
      penyimpanan = PenyimpananMemori();
      dompet = Dompet(penyimpanan);
      jam = _Jam();
    });

    test('hari pertama: 10 koin, lalu tidak bisa diklaim lagi hari itu', () {
      final hadiah = buat();
      expect(hadiah.tersedia.value, isTrue);
      expect(hadiah.hariKe, 1);

      expect(hadiah.klaim(), 10);
      expect(dompet.saldo.value, 10);
      expect(hadiah.tersedia.value, isFalse);
      expect(hadiah.klaim(), 0);

      // Dibuka lagi di hari yang sama.
      expect(buat().tersedia.value, isFalse);
    });

    test('berturut-turut hadiah naik; hari ke-8 kembali ke hari 1', () {
      final didapat = <int>[];
      for (var i = 0; i < 8; i++) {
        didapat.add(buat().klaim());
        jam.besok();
      }
      expect(didapat, [10, 15, 20, 30, 40, 60, 100, 10]);
    });

    test('melewatkan satu hari kembali ke hari 1', () {
      buat().klaim();
      jam.besok();
      buat().klaim(); // hari 2
      jam
        ..besok()
        ..besok(); // lewat sehari
      final hadiah = buat();
      expect(hadiah.hariKe, 1);
      expect(hadiah.klaim(), 10);
    });

    test('hari berganti saat game masih terbuka', () {
      final hadiah = buat()..klaim();
      jam.besok();
      hadiah.periksaLagi();
      expect(hadiah.tersedia.value, isTrue);
      expect(hadiah.hariKe, 2);
    });
  });

  group('Misi harian', () {
    late PenyimpananMemori penyimpanan;
    late Dompet dompet;
    late _Jam jam;

    MisiHarian buat() => MisiHarian(penyimpanan, dompet, jam: jam.call);

    setUp(() {
      penyimpanan = PenyimpananMemori();
      dompet = Dompet(penyimpanan);
      jam = _Jam();
    });

    test('tiga misi berbeda, sama sepanjang hari', () {
      final misi = buat().daftar.value;
      expect(misi, hasLength(MisiHarian.jumlahMisi));
      expect(misi.map((m) => m.jenis).toSet(), hasLength(3));

      jam.sekarang = jam.sekarang.add(const Duration(hours: 10));
      expect(
        buat().daftar.value.map((m) => m.deskripsi),
        misi.map((m) => m.deskripsi),
      );
    });

    test('progres naik sampai target, lalu hadiah bisa diklaim sekali', () {
      final misiHarian = buat();
      final misi = misiHarian.daftar.value.first;

      for (var i = 0; i < misi.target + 5; i++) {
        misi.jenis == JenisMisi.level
            ? misiHarian.catatLevel(i + 1)
            : misiHarian.catat(misi.jenis);
      }
      final selesai = misiHarian.daftar.value.first;
      expect(selesai.progres, misi.target, reason: 'tidak melebihi target');
      expect(selesai.bisaDiklaim, isTrue);
      expect(misiHarian.jumlahBisaDiklaim, 1);

      expect(misiHarian.klaim(0), misi.hadiah);
      expect(dompet.saldo.value, misi.hadiah);
      expect(misiHarian.klaim(0), 0);
      expect(misiHarian.jumlahBisaDiklaim, 0);
    });

    test('misi yang belum selesai tidak bisa diklaim', () {
      final misiHarian = buat();
      expect(misiHarian.klaim(0), 0);
      expect(dompet.saldo.value, 0);
    });

    test('progres tersimpan, dan misi baru keesokan harinya', () {
      final misiHarian = buat();
      final jenis = misiHarian.daftar.value.first.jenis;
      jenis == JenisMisi.level
          ? misiHarian.catatLevel(1)
          : misiHarian.catat(jenis);

      expect(buat().daftar.value.first.progres, 1);

      jam.besok();
      expect(buat().daftar.value.every((m) => m.progres == 0), isTrue);
    });
  });
}
