import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'game_utama.dart';
import 'player.dart';

/// Barang di jalan yang menguntungkan bila diambil (koin, jam). Jatuh secepat
/// jebakan dan diambil saat mengenai mobil.
abstract class BarangAmbilan extends PositionComponent
    with HasGameReference<GameUtama>, CollisionCallbacks {
  /// [x] opsional untuk menentukan posisi horizontal (dipakai di test).
  BarangAmbilan({this._x, required double ukuran}) {
    size = Vector2.all(ukuran);
  }

  final double? _x;
  late final double _kecepatanJatuh;

  /// Efek barang saat diambil mobil.
  void diambil();

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    _kecepatanJatuh = game.levelConfig.kecepatanJebakan;
    final acakX = game.random.nextDouble() * (game.size.x - size.x);
    position = Vector2(_x ?? acakX, -50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;
    position.y += _kecepatanJatuh * dt;
    if (position.y > game.size.y) removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && !game.isGameOver) {
      diambil();
      removeFromParent();
    }
  }
}
