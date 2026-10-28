import 'package:flutter/material.dart';

import 'bersama/hadiah_harian_dialog.dart';
import 'bersama/jumlah_koin.dart';
import 'bersama/layanan.dart';
import 'bersama/layar_dengan_banner.dart';
import 'bersama/penyimpanan.dart';
import 'games/balap/layar_balap.dart';
import 'games/dua_ribu/layar_2048.dart';
import 'games/terbang/layar_terbang.dart';

/// Satu game di beranda.
class InfoGame {
  const InfoGame({
    required this.nama,
    required this.deskripsi,
    required this.ikon,
    required this.warna,
    required this.kunciRekor,
    required this.buka,
  });

  final String nama;
  final String deskripsi;
  final IconData ikon;
  final List<Color> warna;

  /// Kunci penyimpanan rekor game ini.
  final String kunciRekor;
  final Widget Function(Layanan layanan) buka;
}

/// Daftar game. Tambah game baru di sini.
final daftarGame = [
  InfoGame(
    nama: 'Balap Kren',
    deskripsi: 'Hindari jebakan, kumpulkan koin, capai garis finish.',
    ikon: Icons.directions_car_filled_rounded,
    warna: const [Color(0xFF1E88E5), Color(0xFF0D47A1)],
    kunciRekor: KunciSimpan.rekor,
    buka: (layanan) => LayarBalap(layanan: layanan),
  ),
  InfoGame(
    nama: 'Terbang Kren',
    deskripsi: 'Ketuk untuk terbang melewati celah pipa.',
    ikon: Icons.flutter_dash_rounded,
    warna: const [Color(0xFF43A047), Color(0xFF1B5E20)],
    kunciRekor: KunciSimpan.rekorTerbang,
    buka: (layanan) => LayarTerbang(layanan: layanan),
  ),
  InfoGame(
    nama: '2048',
    deskripsi: 'Geser dan gabungkan angka sampai 2048.',
    ikon: Icons.grid_view_rounded,
    warna: const [Color(0xFFFF8F00), Color(0xFFE65100)],
    kunciRekor: KunciSimpan.rekor2048,
    buka: (layanan) => Layar2048(layanan: layanan),
  ),
];

/// Layar pertama aplikasi: daftar game, total koin, dan hadiah harian.
class Beranda extends StatefulWidget {
  const Beranda({super.key, required this.layanan});

  final Layanan layanan;

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  Layanan get _layanan => widget.layanan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tawarkanHadiah());
  }

  void _tawarkanHadiah() {
    _layanan.hadiahHarian.periksaLagi();
    if (!mounted || !_layanan.hadiahHarian.tersedia.value) return;
    tampilkanHadiahHarian(context, _layanan.hadiahHarian);
  }

  Future<void> _main(InfoGame game) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => game.buka(_layanan)));
    if (!mounted) return;
    setState(() {}); // rekor mungkin berubah
    _tawarkanHadiah(); // hari mungkin berganti selama bermain
  }

  @override
  Widget build(BuildContext context) {
    return LayarDenganBanner(
      layanan: _layanan,
      warnaLatar: const Color(0xFF12162B),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildKepala()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList.separated(
              itemCount: daftarGame.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _KartuGame(
                game: daftarGame[i],
                rekor:
                    _layanan.penyimpanan.bacaInt(daftarGame[i].kunciRekor) ?? 0,
                onTap: () => _main(daftarGame[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKepala() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KREN KAMU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Kumpulan mini game',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _layanan.dompet.saldo,
            builder: (_, saldo, _) => JumlahKoin(saldo, ukuran: 20),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _layanan.hadiahHarian.tersedia,
            builder: (_, tersedia, _) => IconButton(
              onPressed: tersedia ? _tawarkanHadiah : null,
              tooltip: 'Hadiah harian',
              icon: Badge(
                isLabelVisible: tersedia,
                smallSize: 10,
                child: const Icon(Icons.card_giftcard_rounded),
              ),
              color: Colors.amber,
              disabledColor: Colors.white24,
              iconSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuGame extends StatelessWidget {
  const _KartuGame({
    required this.game,
    required this.rekor,
    required this.onTap,
  });

  final InfoGame game;
  final int rekor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: game.warna,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(game.ikon, color: Colors.white, size: 46),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.nama,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.deskripsi,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rekor $rekor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
