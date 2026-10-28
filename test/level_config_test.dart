import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/level_config.dart';

void main() {
  test('level 1 sama dengan game awal', () {
    final config = LevelConfig.forLevel(1);
    expect(config.kecepatanMeteor, 250);
    expect(config.kecepatanPemain, 200);
    expect(config.jedaMunculMeteor, 1.5);
  });

  test('level 2: meteor dan pemain 15% lebih cepat, meteor lebih sering', () {
    final config = LevelConfig.forLevel(2);
    expect(config.kecepatanMeteor, closeTo(287.5, 0.001));
    expect(config.kecepatanPemain, closeTo(230, 0.001));
    expect(config.jedaMunculMeteor, closeTo(1.32, 0.001));
  });

  test('kecepatan terus naik tanpa batas di setiap level', () {
    var sebelumnya = LevelConfig.forLevel(1);
    for (var level = 2; level <= 50; level++) {
      final config = LevelConfig.forLevel(level);
      expect(config.kecepatanMeteor, greaterThan(sebelumnya.kecepatanMeteor));
      expect(config.kecepatanPemain, greaterThan(sebelumnya.kecepatanPemain));
      sebelumnya = config;
    }
  });

  test('jeda kemunculan meteor tidak kurang dari 0,4 detik', () {
    expect(LevelConfig.forLevel(100).jedaMunculMeteor, 0.4);
  });

  test('level di bawah 1 diperlakukan sebagai level 1', () {
    expect(LevelConfig.forLevel(0).level, 1);
  });
}
