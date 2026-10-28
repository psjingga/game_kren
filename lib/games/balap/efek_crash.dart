import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

const _warnaApi = [
  Color(0xFFFFF176), // kuning terang
  Color(0xFFFFB300), // oranye kekuningan
  Color(0xFFFF6D00), // oranye
  Color(0xFFE53935), // merah
];

/// Ledakan sekali: percikan api menyembur ke segala arah lalu memudar,
/// ditambah gumpalan asap.
ParticleSystemComponent buatLedakan(Vector2 posisi, Random random) {
  Particle percikan(int _) {
    final sudut = random.nextDouble() * 2 * pi;
    final laju = 80 + random.nextDouble() * 220;
    final warna = _warnaApi[random.nextInt(_warnaApi.length)];
    final jariJari = 3 + random.nextDouble() * 5;
    return AcceleratedParticle(
      speed: Vector2(cos(sudut), sin(sudut)) * laju,
      acceleration: Vector2(0, 120),
      child: ComputedParticle(
        renderer: (canvas, partikel) {
          final sisa = 1 - partikel.progress;
          canvas.drawCircle(
            Offset.zero,
            jariJari * (0.4 + sisa),
            Paint()..color = warna.withValues(alpha: sisa),
          );
        },
      ),
    );
  }

  Particle asap(int _) {
    final sudut = random.nextDouble() * 2 * pi;
    final laju = 20 + random.nextDouble() * 50;
    return AcceleratedParticle(
      speed: Vector2(cos(sudut) * laju, sin(sudut) * laju - 30),
      acceleration: Vector2(0, -20),
      child: ComputedParticle(
        renderer: (canvas, partikel) {
          final p = partikel.progress;
          canvas.drawCircle(
            Offset.zero,
            8 + 22 * p,
            Paint()
              ..color = Colors.grey.shade800.withValues(alpha: 0.6 * (1 - p)),
          );
        },
      ),
    );
  }

  return ParticleSystemComponent(
    position: posisi,
    priority: 10,
    particle: Particle.generate(
      count: 50,
      lifespan: 0.9,
      generator: (i) => i < 36 ? percikan(i) : asap(i),
    ),
  );
}

/// Api yang terus menyala di atas mobil yang terbakar, dengan asap naik.
/// Ditempel sebagai child mobil supaya ikut posisinya.
class ApiTerbakar extends Component {
  ApiTerbakar({required this.lebar, required this.random})
    : super(priority: 10);

  /// Lebar area api (biasanya lebar mobil).
  final double lebar;
  final Random random;

  static const _jeda = 0.04;
  double _waktu = 0;

  @override
  void update(double dt) {
    _waktu += dt;
    while (_waktu >= _jeda) {
      _waktu -= _jeda;
      add(_lidahApi());
      if (random.nextDouble() < 0.35) add(_asapNaik());
    }
  }

  ParticleSystemComponent _lidahApi() {
    final warna = _warnaApi[random.nextInt(_warnaApi.length)];
    final jariJari = 5 + random.nextDouble() * 6;
    return ParticleSystemComponent(
      position: Vector2(
        lebar * 0.2 + random.nextDouble() * lebar * 0.6,
        20 + random.nextDouble() * 40,
      ),
      particle: AcceleratedParticle(
        lifespan: 0.5 + random.nextDouble() * 0.3,
        speed: Vector2((random.nextDouble() - 0.5) * 30, -60),
        acceleration: Vector2(0, -80),
        child: ComputedParticle(
          renderer: (canvas, partikel) {
            final sisa = 1 - partikel.progress;
            canvas.drawCircle(
              Offset.zero,
              jariJari * sisa,
              Paint()..color = warna.withValues(alpha: 0.9 * sisa),
            );
          },
        ),
      ),
    );
  }

  ParticleSystemComponent _asapNaik() {
    return ParticleSystemComponent(
      position: Vector2(lebar / 2 + (random.nextDouble() - 0.5) * lebar, 10),
      particle: AcceleratedParticle(
        lifespan: 1.2,
        speed: Vector2((random.nextDouble() - 0.5) * 20, -50),
        child: ComputedParticle(
          renderer: (canvas, partikel) {
            final p = partikel.progress;
            canvas.drawCircle(
              Offset.zero,
              6 + 16 * p,
              Paint()
                ..color = Colors.grey.shade700.withValues(
                  alpha: 0.45 * (1 - p),
                ),
            );
          },
        ),
      ),
    );
  }
}
