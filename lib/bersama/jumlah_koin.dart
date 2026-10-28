import 'package:flutter/material.dart';

/// Ikon koin kecil + jumlah, dipakai di semua game dan di beranda.
class JumlahKoin extends StatelessWidget {
  const JumlahKoin(
    this.jumlah, {
    super.key,
    this.ukuran = 18,
    this.warna = Colors.white,
  });

  final int jumlah;
  final double ukuran;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on, color: Colors.amber, size: ukuran + 4),
        const SizedBox(width: 4),
        Text(
          '$jumlah',
          style: TextStyle(
            color: warna,
            fontSize: ukuran,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
