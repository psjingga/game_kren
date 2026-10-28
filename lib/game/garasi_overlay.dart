import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'garasi.dart';
import 'game_utama.dart';
import 'overlays.dart';

/// Layar garasi: daftar mobil untuk dibeli dengan koin atau dipakai.
class GarasiOverlay extends StatelessWidget {
  const GarasiOverlay({super.key, required this.game});

  final GameUtama game;

  @override
  Widget build(BuildContext context) {
    final garasi = game.garasi;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            garasi.dimiliki,
            garasi.dipakai,
            game.totalKoin,
          ]),
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: game.tutupGarasi,
                      tooltip: 'Kembali',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                    const Text(
                      'GARASI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    JumlahKoin(game.totalKoin.value, ukuran: 20),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: daftarMobil.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _KartuMobil(game: game, mobil: daftarMobil[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuMobil extends StatelessWidget {
  const _KartuMobil({required this.game, required this.mobil});

  final GameUtama game;
  final DataMobil mobil;

  void _beli(BuildContext context) {
    if (game.garasi.beli(mobil) != HasilBeli.berhasil) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${mobil.nama} dibeli dan dipakai!'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final garasi = game.garasi;
    final dipakai = garasi.dipakai.value == mobil.id;
    final punya = garasi.punya(mobil.id);
    final kurang = mobil.harga - game.totalKoin.value;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dipakai ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dipakai ? Colors.amber : Colors.white24,
          width: dipakai ? 2.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Opacity(
              opacity: punya ? 1 : 0.55,
              child: SvgPicture.asset(
                'assets/images/${mobil.file}',
                width: 52,
                height: 80,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mobil.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (punya)
                  Text(
                    mobil.harga == 0 ? 'Mobil awal' : 'Sudah dimiliki',
                    style: const TextStyle(color: Colors.white60),
                  )
                else
                  JumlahKoin(mobil.harga, ukuran: 16),
                if (!punya && kurang > 0)
                  Text(
                    'Kurang $kurang koin',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (dipakai)
            const Chip(
              avatar: Icon(Icons.check_circle, color: Colors.white, size: 18),
              label: Text('Dipakai'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide.none,
            )
          else if (punya)
            OutlinedButton(
              onPressed: () => garasi.pakai(mobil),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('Pakai'),
            )
          else
            FilledButton.icon(
              onPressed: kurang > 0 ? null : () => _beli(context),
              // Koin kurang: tombol tetap terlihat (abu-abu + gembok).
              icon: Icon(
                kurang > 0 ? Icons.lock_rounded : Icons.shopping_cart_rounded,
                size: 18,
              ),
              label: const Text('Beli'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
