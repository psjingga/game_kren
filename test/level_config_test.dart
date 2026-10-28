import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/game/level_config.dart';

void main() {
  test('level 1 sama dengan game awal', () {
    final config = LevelConfig.forLevel(1);
    expect(config.kecepatanJebakan, 250);
    expect(config.jedaMunculJebakan, 1.5);
  });

  test('level 2: jebakan 15% lebih cepat, jebakan lebih sering', () {
    final config = LevelConfig.forLevel(2);
    expect(config.kecepatanJebakan, closeTo(287.5, 0.001));
    expect(config.jedaMunculJebakan, closeTo(1.32, 0.001));
  });

  test('kecepatan terus naik tanpa batas di setiap level', () {
    var sebelumnya = LevelConfig.forLevel(1);
    for (var level = 2; level <= 50; level++) {
      final config = LevelConfig.forLevel(level);
      expect(config.kecepatanJebakan, greaterThan(sebelumnya.kecepatanJebakan));
      sebelumnya = config;
    }
  });

  test('jeda kemunculan jebakan tidak kurang dari 0,4 detik', () {
    expect(LevelConfig.forLevel(100).jedaMunculJebakan, 0.4);
  });

  test('level di bawah 1 diperlakukan sebagai level 1', () {
    expect(LevelConfig.forLevel(0).level, 1);
  });
}
