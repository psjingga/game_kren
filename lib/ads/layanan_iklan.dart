import 'iklan_berhadiah.dart';
import 'iklan_layar_penuh.dart';

/// Iklan layar penuh & berhadiah yang dipakai bersama semua game, supaya
/// hitungan "iklan setiap N kali game over" berlaku untuk seluruh aplikasi.
class LayananIklan {
  final layarPenuh = IklanLayarPenuh();
  final berhadiah = IklanBerhadiah();

  void muat() {
    layarPenuh.muat();
    berhadiah.muat();
  }

  void dispose() {
    layarPenuh.dispose();
    berhadiah.dispose();
  }
}
