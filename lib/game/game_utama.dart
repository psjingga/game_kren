import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'barang_ambilan.dart';
import 'efek_crash.dart';
import 'gambar_game.dart';
import 'garis_finish.dart';
import 'jam.dart';
import 'jalan.dart';
import 'jebakan.dart';
import 'koin.dart';
import 'level_config.dart';
import 'penyimpanan.dart';
import 'player.dart';

/// Mengatur dunia game: menu, munculnya jebakan, koin & jam, skor, level,
/// jeda, dan game over.
class GameUtama extends FlameGame with HasCollisionDetection {
  GameUtama({
    Random? random,
    this.onGameOver,
    Penyimpanan? penyimpanan,
    bool mulaiDiMenu = false,
  }) : random = random ?? Random(),
       _penyimpanan = penyimpanan ?? PenyimpananMemori(),
       _diMenu = mulaiDiMenu {
    _rekorSebelumMain = rekor.value;
  }

  static const overlayMenu = 'menu';
  static const overlayHud = 'hud';
  static const overlayJeda = 'jeda';
  static const overlayLevelSelesai = 'levelSelesai';
  static const overlayGameOver = 'gameOver';

  /// Lama efek tabrakan & terbakar sebelum layar Game Over muncul (detik).
  static const jedaGameOver = 1.2;

  /// Jeda antar kemunculan koin (detik).
  static const jedaMunculKoin = 1.0;

  /// Jeda antar kemunculan jam (detik). Lebih jarang dari koin supaya
  /// terasa istimewa.
  static const jedaMunculJam = 5.0;

  /// Potongan sisa waktu level setiap mengambil jam (detik).
  static const potonganWaktuJam = 3.0;

  final Random random;

  /// Dipanggil saat layar Game Over muncul (misalnya untuk iklan layar
  /// penuh). Game sendiri tidak tahu apa-apa soal iklan.
  final VoidCallback? onGameOver;

  final Penyimpanan _penyimpanan;

  /// Didengarkan oleh overlay Flutter (menu, HUD, Level Selesai, Game Over).
  final level = ValueNotifier<int>(1);
  final skor = ValueNotifier<int>(0);
  final dihindariDiLevelIni = ValueNotifier<int>(0);

  /// Koin yang diambil di permainan ini.
  final koin = ValueNotifier<int>(0);

  /// Skor tertinggi dan koin terkumpul sepanjang masa (tersimpan di HP).
  late final rekor = ValueNotifier<int>(_penyimpanan.rekor);
  late final totalKoin = ValueNotifier<int>(_penyimpanan.totalKoin);

  /// Sisa waktu level dalam detik (dibulatkan ke atas) untuk HUD.
  final sisaDetik = ValueNotifier<int>(LevelConfig.durasiLevel.ceil());

  late final GambarGame gambar;
  late Player _player;
  double _waktuMunculJebakan = 0;
  double _waktuMunculKoin = 0;
  double _waktuMunculJam = 0;
  double _waktuLevel = 0;
  bool _diMenu;
  bool _dijeda = false;
  bool _isGameOver = false;
  bool _menungguLanjut = false;
  bool _menujuFinish = false;
  bool _sudahLanjutDenganIklan = false;
  bool _kiriDitekan = false;
  bool _kananDitekan = false;
  int _koinBelumDisimpan = 0;
  late int _rekorSebelumMain;

  bool get diMenu => _diMenu;
  bool get dijeda => _dijeda;
  bool get isGameOver => _isGameOver;

  /// `true` saat level selesai dan menunggu pemain menekan "Lanjut".
  bool get menungguLanjut => _menungguLanjut;

  /// `true` saat waktu habis dan garis finish sedang mendekati mobil.
  bool get menujuFinish => _menujuFinish;

  /// Posisi y bagian depan mobil; garis finish yang mencapai titik ini
  /// berarti sudah dilewati.
  double get posisiDepanMobil => _player.position.y;

  /// Lanjut main lewat iklan berhadiah hanya boleh sekali per permainan.
  bool get bisaLanjutDenganIklan => !_sudahLanjutDenganIklan;

  /// Skor permainan ini melewati rekor sebelum permainan dimulai.
  bool get rekorBaru => skor.value > _rekorSebelumMain;

  /// -1 = ke kiri, 1 = ke kanan, 0 = diam (tidak ada atau kedua tombol
  /// ditekan, atau sedang tidak bermain).
  double get arahMobil {
    if (!_sedangBermain) return 0;
    return (_kananDitekan ? 1.0 : 0.0) - (_kiriDitekan ? 1.0 : 0.0);
  }

  LevelConfig get levelConfig => LevelConfig.forLevel(level.value);

  bool get _sedangBermain =>
      !_diMenu && !_dijeda && !_isGameOver && !_menungguLanjut;

  @override
  Future<void> onLoad() async {
    gambar = await GambarGame.muat();
    add(Jalan());
    _player = Player();
    add(_player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Menuju finish: tidak ada jebakan atau barang baru, tinggal melewati
    // garis finish (dan menghindari jebakan yang masih ada di jalan).
    if (!_sedangBermain || _menujuFinish) return;

    _waktuLevel += dt;
    final sisa = LevelConfig.durasiLevel - _waktuLevel;
    sisaDetik.value = max(sisa, 0).ceil();
    if (sisa <= 0) {
      _munculkanFinish();
      return;
    }

    _waktuMunculJebakan += dt;
    if (_waktuMunculJebakan > levelConfig.jedaMunculJebakan) {
      add(Jebakan());
      _waktuMunculJebakan = 0;
    }

    _waktuMunculKoin += dt;
    if (_waktuMunculKoin > jedaMunculKoin) {
      add(Koin());
      _waktuMunculKoin = 0;
    }

    _waktuMunculJam += dt;
    if (_waktuMunculJam > jedaMunculJam) {
      add(Jam());
      _waktuMunculJam = 0;
    }
  }

  /// Dari tombol ◀ di HUD: mobil ke kiri selama tombol ditahan.
  void tekanKiri({required bool ditekan}) => _kiriDitekan = ditekan;

  /// Dari tombol ▶ di HUD: mobil ke kanan selama tombol ditahan.
  void tekanKanan({required bool ditekan}) => _kananDitekan = ditekan;

  /// Tombol yang masih tertahan saat layar berganti (jeda, game over) tidak
  /// pernah menerima "lepas", jadi dilepas di sini.
  void _lepasTombol() {
    _kiriDitekan = false;
    _kananDitekan = false;
  }

  /// Aplikasi ditinggal (misalnya ada telepon) saat bermain: jeda otomatis.
  /// Hanya `hidden`, karena GameWidget juga mengirim `paused` saat dibuang.
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden) jeda();
    super.lifecycleStateChange(state);
  }

  /// Dari tombol "Main" di menu awal.
  void mulai() {
    if (!_diMenu) return;
    _diMenu = false;
    overlays
      ..remove(overlayMenu)
      ..add(overlayHud);
  }

  void jeda() {
    if (!_sedangBermain) return;
    _dijeda = true;
    _lepasTombol();
    overlays.add(overlayJeda);
    pauseEngine();
  }

  void lanjutkanJeda() {
    if (!_dijeda) return;
    _dijeda = false;
    overlays.remove(overlayJeda);
    resumeEngine();
  }

  /// Dipanggil oleh [Jebakan] saat lolos melewati layar bawah.
  void jebakanDihindari() {
    if (!_sedangBermain) return;
    skor.value++;
    dihindariDiLevelIni.value++;
  }

  /// Dipanggil oleh [Koin] saat diambil mobil.
  void ambilKoin() {
    if (!_sedangBermain) return;
    koin.value++;
    _koinBelumDisimpan++;
  }

  /// Dipanggil oleh [Jam] saat diambil mobil: sisa waktu level dipotong,
  /// jadi level selesai lebih cepat.
  void ambilJam() {
    if (!_sedangBermain || _menujuFinish) return;
    _waktuLevel = min(_waktuLevel + potonganWaktuJam, LevelConfig.durasiLevel);
    sisaDetik.value = (LevelConfig.durasiLevel - _waktuLevel).ceil();
    add(
      TeksMelayang(
        '-${potonganWaktuJam.toInt()} detik',
        position: Vector2(_player.center.x, _player.y - 10),
        warna: const Color(0xFF4FC3F7),
      ),
    );
  }

  /// Waktu level habis: garis finish muncul dari atas.
  void _munculkanFinish() {
    _menujuFinish = true;
    add(GarisFinish());
  }

  /// Dipanggil oleh [GarisFinish] saat mobil melewatinya.
  void melewatiFinish() {
    if (!_menujuFinish || !_sedangBermain) return;
    _menujuFinish = false;
    _levelSelesai();
  }

  /// Mobil melewati garis finish dengan selamat.
  void _levelSelesai() {
    _menungguLanjut = true;
    _lepasTombol();
    overlays.add(overlayLevelSelesai);
    pauseEngine();
  }

  /// Dipanggil dari tombol "Lanjut" di layar Level Selesai.
  void lanjutLevel() {
    if (!_menungguLanjut) return;
    level.value++;
    _mulaiLevel();
    overlays.remove(overlayLevelSelesai);
    _menungguLanjut = false;
    resumeEngine();
  }

  /// Dipanggil oleh [Jebakan] saat mengenai pemain.
  ///
  /// Mobil meledak dan terbakar dulu; layar Game Over muncul setelah
  /// [jedaGameOver] detik. Game tidak di-pause supaya api tetap menyala.
  void gameOver({Vector2? titikTabrakan}) {
    if (!_sedangBermain) return;
    _isGameOver = true;
    _lepasTombol();
    _simpanHasil();

    _player.tabrakan();
    add(buatLedakan(titikTabrakan ?? _player.center, random));
    HapticFeedback.heavyImpact();
    add(
      TimerComponent(
        period: jedaGameOver,
        removeOnFinish: true,
        onTick: () {
          overlays.add(overlayGameOver);
          onGameOver?.call();
        },
      ),
    );
  }

  /// Hadiah iklan: lanjut dengan level, skor, koin, dan sisa waktu yang sama,
  /// mobil yang sudah pulih, dan jalan yang bersih.
  void lanjutSetelahIklan() {
    if (!_isGameOver || _sudahLanjutDenganIklan) return;
    _sudahLanjutDenganIklan = true;
    _lepasTombol();
    _bersihkanJalan();
    removeAll(children.whereType<TimerComponent>());
    _player.pulihkan();
    _isGameOver = false;
    overlays.remove(overlayGameOver);
  }

  void mainLagi() {
    _ulangPermainan();
    overlays
      ..remove(overlayGameOver)
      ..remove(overlayLevelSelesai)
      ..remove(overlayJeda)
      ..add(overlayHud);
    resumeEngine();
  }

  void kembaliKeMenu() {
    _ulangPermainan();
    _diMenu = true;
    overlays
      ..remove(overlayGameOver)
      ..remove(overlayLevelSelesai)
      ..remove(overlayJeda)
      ..remove(overlayHud)
      ..add(overlayMenu);
    resumeEngine(); // jalan tetap bergerak di belakang menu
  }

  void _ulangPermainan() {
    _simpanHasil(); // permainan yang ditinggal dari jeda tetap dihitung
    level.value = 1;
    skor.value = 0;
    koin.value = 0;
    _rekorSebelumMain = rekor.value;
    _mulaiLevel();
    removeAll(children.whereType<TimerComponent>());
    _player.pulihkan();
    _isGameOver = false;
    _menungguLanjut = false;
    _dijeda = false;
    _sudahLanjutDenganIklan = false;
    _lepasTombol();
  }

  /// Rekor baru dan koin yang diambil disimpan ke HP.
  void _simpanHasil() {
    if (skor.value <= rekor.value && _koinBelumDisimpan == 0) return;
    rekor.value = max(rekor.value, skor.value);
    totalKoin.value += _koinBelumDisimpan;
    _koinBelumDisimpan = 0;
    _penyimpanan.simpan(rekor: rekor.value, totalKoin: totalKoin.value);
  }

  /// Layar bersih untuk level baru.
  void _mulaiLevel() {
    _bersihkanJalan();
    removeAll(children.whereType<GarisFinish>());
    _menujuFinish = false;
    dihindariDiLevelIni.value = 0;
    _waktuLevel = 0;
    sisaDetik.value = LevelConfig.durasiLevel.ceil();
  }

  void _bersihkanJalan() {
    removeAll(children.whereType<Jebakan>());
    removeAll(children.whereType<BarangAmbilan>());
    removeAll(children.whereType<TeksMelayang>());
    removeAll(children.whereType<ParticleSystemComponent>());
    _waktuMunculJebakan = 0;
    _waktuMunculKoin = 0;
    _waktuMunculJam = 0;
  }

  @override
  void onRemove() {
    for (final notifier in [
      level,
      skor,
      dihindariDiLevelIni,
      koin,
      rekor,
      totalKoin,
      sisaDetik,
    ]) {
      notifier.dispose();
    }
    super.onRemove();
  }
}
