import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_kren_kamu/main.dart';

final _ukuranLayar = Vector2(400, 800);

void main() {
  testWithGame<GameUtama>('pemain muncul di tengah bawah', GameUtama.new, (
    game,
  ) async {
    final player = game.children.whereType<Player>().single;
    expect(
      player.position,
      Vector2(game.size.x / 2 - player.size.x / 2, game.size.y - 120),
    );
  });

  testWithGame<GameUtama>(
    'meteor muncul setelah 1,5 detik lalu dihapus setelah lewat bawah',
    GameUtama.new,
    (game) async {
      game.onGameResize(_ukuranLayar);
      await game.ready();

      game.update(1.4);
      await game.ready();
      expect(game.children.whereType<Meteor>(), isEmpty);

      game.update(0.2);
      await game.ready();
      expect(game.children.whereType<Meteor>(), hasLength(1));

      // 250 px/detik: dari y = -50 butuh > 3,4 detik untuk melewati y = 800.
      for (var i = 0; i < 35; i++) {
        game.update(0.1);
      }
      await game.ready();
      final meteorPertama = game.children.whereType<Meteor>().where(
        (m) => m.position.y > 700,
      );
      expect(meteorPertama, isEmpty);
    },
  );

  testWidgets('ketuk kanan menggerakkan pemain ke kanan, kiri ke kiri', (
    tester,
  ) async {
    final game = GameUtama();
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: _ukuranLayar.x,
          height: _ukuranLayar.y,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final player = game.children.whereType<Player>().single;
    final xAwal = player.position.x;
    final kotak = tester.getRect(find.byType(GameWidget<GameUtama>));

    await tester.tapAt(kotak.centerRight - const Offset(20, 0));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(player.position.x, greaterThan(xAwal));

    final xSetelahKanan = player.position.x;
    await tester.tapAt(kotak.centerLeft + const Offset(20, 0));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(player.position.x, lessThan(xSetelahKanan));
  });
}
