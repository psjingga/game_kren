import 'package:flutter/material.dart';

import 'hadiah_harian.dart';

/// Menampilkan jendela hadiah harian; selesai saat hadiah diklaim.
Future<void> tampilkanHadiahHarian(BuildContext context, HadiahHarian hadiah) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => HadiahHarianDialog(
      hadiah: hadiah,
      onKlaim: () {
        hadiah.klaim();
        Navigator.of(context).pop();
      },
    ),
  );
}

/// Kotak hari 1–7 dengan hadiah hari ini disorot, dan tombol klaim.
class HadiahHarianDialog extends StatelessWidget {
  const HadiahHarianDialog({
    super.key,
    required this.hadiah,
    required this.onKlaim,
  });

  final HadiahHarian hadiah;
  final VoidCallback onKlaim;

  @override
  Widget build(BuildContext context) {
    final hariKe = hadiah.hariKe;
    return Dialog(
      backgroundColor: const Color(0xFF263238),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.amber,
              size: 56,
            ),
            const Text(
              'HADIAH HARIAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buka setiap hari, hadiahnya makin besar!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var hari = 1; hari <= HadiahHarian.hadiah.length; hari++)
                  _KotakHari(
                    hari: hari,
                    koin: HadiahHarian.hadiah[hari - 1],
                    status: hari < hariKe
                        ? _StatusHari.sudah
                        : hari == hariKe
                        ? _StatusHari.hariIni
                        : _StatusHari.nanti,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onKlaim,
              icon: const Icon(Icons.monetization_on),
              label: Text('KLAIM +${hadiah.hadiahHariIni}'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 52),
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

enum _StatusHari { sudah, hariIni, nanti }

class _KotakHari extends StatelessWidget {
  const _KotakHari({
    required this.hari,
    required this.koin,
    required this.status,
  });

  final int hari;
  final int koin;
  final _StatusHari status;

  @override
  Widget build(BuildContext context) {
    final hariIni = status == _StatusHari.hariIni;
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hariIni ? Colors.amber : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Hari $hari',
            style: TextStyle(
              color: hariIni ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (status == _StatusHari.sudah)
            const Icon(Icons.check_circle, color: Colors.green, size: 22)
          else
            Icon(
              Icons.monetization_on,
              color: hariIni ? Colors.black : Colors.amber,
              size: 22,
            ),
          Text(
            '$koin',
            style: TextStyle(
              color: hariIni ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
