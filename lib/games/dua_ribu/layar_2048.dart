import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bersama/jumlah_koin.dart';
import '../../bersama/layanan.dart';
import '../../bersama/layar_dengan_banner.dart';
import '../../bersama/penyimpanan.dart';
import 'papan_2048.dart';

/// Koin untuk ubin terbesar yang pertama kali dicapai dalam satu permainan.
const hadiahUbin = {128: 5, 256: 10, 512: 20, 1024: 40, 2048: 80, 4096: 150};

/// Game 2048: geser untuk menggabungkan angka. Permainan tersimpan otomatis,
/// jadi bisa dilanjutkan setelah aplikasi ditutup.
class Layar2048 extends StatefulWidget {
  const Layar2048({super.key, required this.layanan, this.random});

  final Layanan layanan;

  /// Untuk test (ubin baru yang bisa ditebak).
  final Random? random;

  @override
  State<Layar2048> createState() => _Layar2048State();
}

class _Layar2048State extends State<Layar2048> {
  static const _kunciPapan = 'papan_2048';
  static const _kunciSkor = 'skor_2048';
  static const _kunciUbinDihadiahi = 'hadiah_ubin_2048';

  late Papan2048 _papan;
  late int _rekor;

  /// Ubin terbesar yang sudah diberi koin di permainan ini.
  int _ubinDihadiahi = 0;

  /// Naik setiap geseran, untuk memicu ulang animasi ubin.
  int _langkah = 0;

  Penyimpanan get _simpan => widget.layanan.penyimpanan;

  @override
  void initState() {
    super.initState();
    _rekor = _simpan.bacaInt(KunciSimpan.rekor2048) ?? 0;
    _papan = _muatPapan() ?? Papan2048(random: widget.random);
  }

  /// Permainan yang belum selesai dari sesi sebelumnya.
  Papan2048? _muatPapan() {
    final tersimpan = _simpan.bacaDaftar(_kunciPapan);
    if (tersimpan == null || tersimpan.length != Papan2048.jumlahSel) {
      return null;
    }
    final papan = Papan2048(
      random: widget.random,
      sel: [for (final s in tersimpan) int.tryParse(s) ?? 0],
      skor: _simpan.bacaInt(_kunciSkor) ?? 0,
    );
    if (!papan.bisaGerak || papan.ubinTerbesar == 0) return null;
    _ubinDihadiahi = _simpan.bacaInt(_kunciUbinDihadiahi) ?? 0;
    return papan;
  }

  void _simpanPapan() {
    _simpan
      ..tulisDaftar(_kunciPapan, [for (final s in _papan.sel) '$s'])
      ..tulisInt(_kunciSkor, _papan.skor)
      ..tulisInt(_kunciUbinDihadiahi, _ubinDihadiahi);
  }

  void _geser(Arah arah) {
    if (!_papan.bisaGerak) return;
    if (!_papan.geser(arah)) return;
    HapticFeedback.selectionClick();

    setState(() {
      _langkah++;
      if (_papan.skor > _rekor) {
        _rekor = _papan.skor;
        _simpan.tulisInt(KunciSimpan.rekor2048, _rekor);
      }
    });
    _beriHadiahUbin();
    _simpanPapan();

    if (!_papan.bisaGerak) {
      widget.layanan.iklan?.layarPenuh.gameOver();
    }
  }

  /// Ubin terbesar baru mencapai 128, 256, ... : beri koin sekali.
  void _beriHadiahUbin() {
    final terbesar = _papan.ubinTerbesar;
    if (terbesar <= _ubinDihadiahi) return;
    final koin = hadiahUbin.entries
        .where((e) => e.key > _ubinDihadiahi && e.key <= terbesar)
        .fold(0, (total, e) => total + e.value);
    _ubinDihadiahi = terbesar;
    if (koin == 0) return;
    widget.layanan.dompet.tambah(koin);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            terbesar >= 2048
                ? '🎉 $terbesar! Kamu menang! +$koin koin'
                : 'Ubin $terbesar! +$koin koin',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _mainBaru() {
    setState(() {
      _papan = Papan2048(random: widget.random);
      _ubinDihadiahi = 0;
      _langkah++;
    });
    _simpanPapan();
  }

  /// Usapan: arah dengan kecepatan terbesar.
  void _usap(DragEndDetails detail) {
    final v = detail.velocity.pixelsPerSecond;
    if (v.distance < 150) return;
    if (v.dx.abs() > v.dy.abs()) {
      _geser(v.dx > 0 ? Arah.kanan : Arah.kiri);
    } else {
      _geser(v.dy > 0 ? Arah.bawah : Arah.atas);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayarDenganBanner(
      layanan: widget.layanan,
      warnaLatar: const Color(0xFFFAF8EF),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanEnd: _usap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildKepala(),
              const SizedBox(height: 16),
              _buildSkor(),
              const SizedBox(height: 8),
              const Text(
                'Geser ke segala arah. Angka yang sama bergabung!',
                style: TextStyle(color: Color(0xFF776E65)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        _PapanUbin(papan: _papan, langkah: _langkah),
                        if (!_papan.bisaGerak) _buildKalah(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKepala() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Beranda',
          icon: const Icon(Icons.arrow_back_rounded),
          color: const Color(0xFF776E65),
        ),
        const Text(
          '2048',
          style: TextStyle(
            color: Color(0xFF776E65),
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        ValueListenableBuilder<int>(
          valueListenable: widget.layanan.dompet.saldo,
          builder: (_, saldo, _) =>
              JumlahKoin(saldo, ukuran: 20, warna: const Color(0xFF776E65)),
        ),
      ],
    );
  }

  Widget _buildSkor() {
    return Row(
      children: [
        _KotakSkor(judul: 'SKOR', nilai: _papan.skor),
        const SizedBox(width: 8),
        _KotakSkor(judul: 'REKOR', nilai: _rekor),
        const Spacer(),
        FilledButton.icon(
          onPressed: _mainBaru,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Baru'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8F7A66),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildKalah() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCCEEE4DA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tidak bisa bergerak lagi!',
              style: TextStyle(
                color: Color(0xFF776E65),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Skor ${_papan.skor}',
              style: const TextStyle(color: Color(0xFF776E65), fontSize: 20),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _mainBaru,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Main Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8F7A66),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KotakSkor extends StatelessWidget {
  const _KotakSkor({required this.judul, required this.nilai});

  final String judul;
  final int nilai;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            judul,
            style: const TextStyle(
              color: Color(0xFFEEE4DA),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$nilai',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PapanUbin extends StatelessWidget {
  const _PapanUbin({required this.papan, required this.langkah});

  final Papan2048 papan;
  final int langkah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.count(
        crossAxisCount: Papan2048.sisi,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < Papan2048.jumlahSel; i++)
            _Ubin(
              // Kunci berubah saat ubin baru/digabung supaya animasi diulang.
              key: ValueKey(
                i == papan.ubinBaru || papan.digabung.contains(i)
                    ? '$i-$langkah'
                    : '$i',
              ),
              nilai: papan.sel[i],
              animasi: i == papan.ubinBaru
                  ? _AnimasiUbin.muncul
                  : papan.digabung.contains(i)
                  ? _AnimasiUbin.gabung
                  : _AnimasiUbin.tidak,
            ),
        ],
      ),
    );
  }
}

enum _AnimasiUbin { tidak, muncul, gabung }

class _Ubin extends StatelessWidget {
  const _Ubin({super.key, required this.nilai, required this.animasi});

  final int nilai;
  final _AnimasiUbin animasi;

  static const _warna = {
    0: Color(0xFFCDC1B4),
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
  };

  @override
  Widget build(BuildContext context) {
    final kotak = LayoutBuilder(
      builder: (context, ukuran) {
        final digit = '$nilai'.length;
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _warna[nilai] ?? const Color(0xFF3C3A32),
            borderRadius: BorderRadius.circular(8),
          ),
          child: nilai == 0
              ? null
              : Text(
                  '$nilai',
                  style: TextStyle(
                    color: nilai <= 4 ? const Color(0xFF776E65) : Colors.white,
                    fontSize:
                        ukuran.maxWidth * (digit <= 2 ? 0.45 : 0.9 / digit),
                    fontWeight: FontWeight.w900,
                  ),
                ),
        );
      },
    );

    return switch (animasi) {
      _AnimasiUbin.tidak => kotak,
      _AnimasiUbin.muncul => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        builder: (_, s, anak) => Transform.scale(scale: s, child: anak),
        child: kotak,
      ),
      _AnimasiUbin.gabung => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.2, end: 1),
        duration: const Duration(milliseconds: 150),
        builder: (_, s, anak) => Transform.scale(scale: s, child: anak),
        child: kotak,
      ),
    };
  }
}
