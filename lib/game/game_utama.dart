import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'barang_ambilan.dart';
import 'dompet.dart';
import 'efek_crash.dart';
import 'gambar_game.dart';
import 'garasi.dart';
import 'garis_finish.dart';
import 'hadiah_harian.dart';
import 'jam.dart';
import 'jalan.dart';
import 'jebakan.dart';
import 'koin.dart';
import 'level_config.dart';
import 'misi.dart';
import 'mobil_lawan.dart';
import 'oli.dart';
import 'penyimpanan.dart';
import 'player.dart';
import 'power_up.dart';
import 'rintangan.dart';

/// Mengatur dunia game: menu, munculnya rintangan & barang, skor, level,
/// power-up, jeda, dan game over.
class GameUtama extends FlameGame with HasCollisionDetection {
  GameUtama({
    Random? random,
    this.onGameOver,
    Penyimpanan? penyimpanan,
    bool mulaiDiMenu = false,
    this._jam,
  }) : random = random ?? Random(),
       _penyimpanan = penyimpanan ?? PenyimpananMemori(),
       _diMenu = mulaiDiMenu {
    _rekorSebelumMain = rekor.value;
  }

  static const overlayMenu = 'menu';
  static const overlayGarasi = 'garasi';
  static const overlayMisi = 'misi';
  static const overlayHadiahHarian = 'hadiahHarian';
  static const overlayHud = 'hud';
  static const overlayJeda = 'jeda';
  static const overlayLevelSelesai = 'levelSelesai';
  static const overlayGameOver = 'gameOver';

  /// Lama efek tabrakan & terbakar sebelum layar Game Over muncul (detik).
  static const jedaGameOver = 1.2;

  /// Jeda antar kemunculan barang (detik). Jam & power-up lebih jarang dari
  /// koin supaya terasa istimewa.
  static const jedaMunculKoin = 1.0;
  static const jedaMunculJam = 5.0;
  static const jedaMunculPowerUp = 9.0;

  /// Potongan sisa waktu level setiap mengambil jam (detik).
  static const potonganWaktuJam = 3.0;

  /// Skor tambahan saat melewati rintangan dengan jarak sangat tipis.
  static const bonusNyaris = 2;

  /// Lebar rumput di kiri & kanan jalan, dan jumlah lajur.
  static const lebarBahu = 28.0;
  static const jumlahLajur = 3;

  /// Lama kebal setelah perisai menahan tabrakan (detik), supaya jebakan
  /// di sebelahnya tidak langsung mengenai.
  static const _lamaKebal = 0.6;

  final Random random;

  /// Dipanggil saat layar Game Over muncul (misalnya untuk iklan layar
  /// penuh). Game sendiri tidak tahu apa-apa soal iklan.
  final VoidCallback? onGameOver;

  final Penyimpanan _penyimpanan;
  final DateTime Function()? _jam;

  /// Didengarkan oleh overlay Flutter (menu, HUD, Level Selesai, Game Over).
  final level = ValueNotifier<int>(1);
  final skor = ValueNotifier<int>(0);
  final dihindariDiLevelIni = ValueNotifier<int>(0);

  /// Koin yang diambil di permainan ini.
  final koin = ValueNotifier<int>(0);

  /// Skor tertinggi sepanjang masa (tersimpan di HP).
  late final rekor = ValueNotifier<int>(
    _penyimpanan.bacaInt(KunciSimpan.rekor) ?? 0,
  );

  /// Total koin sepanjang masa, dipakai di garasi.
  late final dompet = Dompet(_penyimpanan);
  ValueNotifier<int> get totalKoin => dompet.saldo;

  late final garasi = Garasi(_penyimpanan, dompet);
  late final hadiahHarian = HadiahHarian(_penyimpanan, dompet, jam: _jam);
  late final misi = MisiHarian(_penyimpanan, dompet, jam: _jam);
  final status = StatusPowerUp();

  /// Sisa waktu level dalam detik (dibulatkan ke atas) untuk HUD.
  final sisaDetik = ValueNotifier<int>(LevelConfig.durasiLevel.ceil());

  late final GambarGame gambar;
  late Player _player;
  double _waktuMunculJebakan = 0;
  double _waktuMunculKoin = 0;
  double _waktuMunculJam = 0;
  double _waktuMunculPowerUp = 0;
  double _waktuLevel = 0;
  double _sisaKebal = 0;
  double _sisaGoyang = 0;
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

  /// Kotak tabrakan mobil di koordinat layar.
  Rect get kotakMobil => _player.kotakTabrak;

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
  Suasana get suasana => Suasana.untukLevel(level.value);

  /// Tepi kiri & kanan aspal; mobil dan barang tetap di antara keduanya.
  double get batasKiri => lebarBahu;
  double get batasKanan => size.x - lebarBahu;

  /// Titik tengah lajur ke-[lajur] (0 = paling kiri).
  double tengahLajur(int lajur) =>
      batasKiri + (batasKanan - batasKiri) / jumlahLajur * (lajur + 0.5);

  bool get _sedangBermain =>
      !_diMenu && !_dijeda && !_isGameOver && !_menungguLanjut;

  @override
  Future<void> onLoad() async {
    gambar = await GambarGame.muat();
    add(Jalan());
    _player = Player();
    add(_player);
    add(LapisanSuasana());
    if (_diMenu && hadiahHarian.tersedia.value) {
      overlays.add(overlayHadiahHarian);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sisaGoyang = max(_sisaGoyang - dt, 0);
    if (!_sedangBermain) return;
    status.update(dt);
    _sisaKebal = max(_sisaKebal - dt, 0);

    // Menuju finish: tidak ada rintangan atau barang baru, tinggal melewati
    // garis finish (dan menghindari rintangan yang masih ada di jalan).
    if (_menujuFinish) return;

    _waktuLevel += dt;
    final sisa = LevelConfig.durasiLevel - _waktuLevel;
    sisaDetik.value = max(sisa, 0).ceil();
    if (sisa <= 0) {
      _munculkanFinish();
      return;
    }

    _waktuMunculJebakan += dt;
    if (_waktuMunculJebakan > levelConfig.jedaMunculJebakan) {
      _munculkanRintangan();
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

    _waktuMunculPowerUp += dt;
    if (_waktuMunculPowerUp > jedaMunculPowerUp) {
      _munculkanPowerUp();
      _waktuMunculPowerUp = 0;
    }
  }

  /// Layar bergetar sebentar saat tabrakan.
  @override
  void render(Canvas canvas) {
    if (_sisaGoyang <= 0) return super.render(canvas);
    final kuat = 7 * _sisaGoyang / 0.35;
    canvas
      ..save()
      ..translate(
        (random.nextDouble() * 2 - 1) * kuat,
        (random.nextDouble() * 2 - 1) * kuat,
      );
    super.render(canvas);
    canvas.restore();
  }

  /// Rintangan makin beragam di level tinggi: oli mulai level 2, mobil lain
  /// mulai level 3, barisan jebakan bercelah mulai level 4.
  void _munculkanRintangan() {
    final lv = level.value;
    final acak = random.nextDouble();
    if (lv >= 4 && acak < 0.15) {
      _munculkanBarisan();
    } else if (lv >= 3 && acak >= 0.15 && acak < 0.35) {
      add(MobilLawan());
    } else if (lv >= 2 && acak >= 0.35 && acak < 0.5) {
      add(Oli());
    } else {
      add(Jebakan());
    }
  }

  /// Deretan jebakan selebar jalan dengan satu celah yang cukup untuk mobil.
  void _munculkanBarisan() {
    const lebarCelah = 120.0;
    const jarak = 44.0;
    final mulaiCelah =
        batasKiri + random.nextDouble() * (batasKanan - batasKiri - lebarCelah);
    for (var x = batasKiri + 2; x + 40 <= batasKanan; x += jarak) {
      final diCelah = x + 40 > mulaiCelah && x < mulaiCelah + lebarCelah;
      if (!diCelah) add(Jebakan(x: x));
    }
  }

  void _munculkanPowerUp() {
    final pilihan = [
      for (final j in JenisPowerUp.values)
        if (j != JenisPowerUp.perisai || !status.perisai.value) j,
    ];
    add(PowerUp(pilihan[random.nextInt(pilihan.length)]));
  }

  void _teks(String teks, Vector2 posisi, Color warna) =>
      add(TeksMelayang(teks, position: posisi, warna: warna));

  Vector2 get _diAtasMobil => Vector2(_player.center.x, _player.y - 10);

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

  /// Membuka layar dari menu awal ([overlayGarasi] atau [overlayMisi]).
  void bukaDariMenu(String layar) {
    if (!_diMenu) return;
    overlays
      ..remove(overlayMenu)
      ..add(layar);
  }

  void kembaliDariLayar(String layar) {
    overlays
      ..remove(layar)
      ..add(overlayMenu);
  }

  /// Dari tombol "Klaim" di jendela hadiah harian.
  int klaimHadiahHarian() {
    final jumlah = hadiahHarian.klaim();
    overlays.remove(overlayHadiahHarian);
    return jumlah;
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

  /// Dipanggil oleh [Rintangan] saat lolos melewati layar bawah.
  void jebakanDihindari() {
    if (!_sedangBermain) return;
    skor.value++;
    dihindariDiLevelIni.value++;
    misi.catat(JenisMisi.hindari);
  }

  /// Dipanggil oleh [Rintangan] yang dilewati dengan jarak sangat tipis.
  void nyaris(Vector2 posisi) {
    if (!_sedangBermain) return;
    skor.value += bonusNyaris;
    misi.catat(JenisMisi.nyaris);
    _teks('NYARIS! +$bonusNyaris', posisi, const Color(0xFFFFA726));
    HapticFeedback.selectionClick();
  }

  /// Dipanggil oleh [Koin] saat diambil mobil.
  void ambilKoin() {
    if (!_sedangBermain) return;
    final nilai = status.koinGandaAktif ? 2 : 1;
    koin.value += nilai;
    _koinBelumDisimpan += nilai;
    misi.catat(JenisMisi.koin, nilai);
  }

  /// Dipanggil oleh [Jam] saat diambil mobil: sisa waktu level dipotong,
  /// jadi level selesai lebih cepat.
  void ambilJam() {
    if (!_sedangBermain || _menujuFinish) return;
    _waktuLevel = min(_waktuLevel + potonganWaktuJam, LevelConfig.durasiLevel);
    sisaDetik.value = (LevelConfig.durasiLevel - _waktuLevel).ceil();
    misi.catat(JenisMisi.jam);
    _teks(
      '-${potonganWaktuJam.toInt()} detik',
      _diAtasMobil,
      const Color(0xFF4FC3F7),
    );
  }

  /// Dipanggil oleh [PowerUp] saat diambil mobil.
  void ambilPowerUp(JenisPowerUp jenis) {
    if (!_sedangBermain) return;
    status.aktifkan(jenis);
    misi.catat(JenisMisi.powerUp);
    final teks = switch (jenis) {
      JenisPowerUp.perisai => 'PERISAI!',
      JenisPowerUp.magnet => 'MAGNET!',
      JenisPowerUp.koinGanda => 'KOIN ×2!',
    };
    _teks(teks, _diAtasMobil, jenis.warna);
  }

  /// Dipanggil oleh [Rintangan] berbahaya yang mengenai mobil.
  void kenaRintangan(Rintangan rintangan) {
    if (!_sedangBermain) return;
    if (_sisaKebal > 0) return;

    if (status.pakaiPerisai()) {
      // Perisai pecah: rintangan hancur, mobil selamat.
      rintangan.removeFromParent();
      add(buatLedakan(rintangan.absoluteCenter, random));
      _sisaKebal = _lamaKebal;
      _sisaGoyang = 0.2;
      HapticFeedback.mediumImpact();
      _teks('PERISAI PECAH!', _diAtasMobil, JenisPowerUp.perisai.warna);
      return;
    }

    if (rintangan is Jebakan) rintangan.removeFromParent(); // hancur meledak
    gameOver(titikTabrakan: rintangan.absoluteCenter);
  }

  /// Dipanggil oleh [Oli] saat dilindas mobil.
  void kenaOli() {
    if (!_sedangBermain) return;
    _player.mulaiSelip();
    HapticFeedback.lightImpact();
    _teks('SELIP!', _diAtasMobil, const Color(0xFFB0BEC5));
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
    misi.catatLevel(level.value);
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

  /// Mobil tertabrak.
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
    _sisaGoyang = 0.35;
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
    hadiahHarian.periksaLagi();
    if (hadiahHarian.tersedia.value) overlays.add(overlayHadiahHarian);
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
    status.reset();
    _sisaKebal = 0;
    _isGameOver = false;
    _menungguLanjut = false;
    _dijeda = false;
    _sudahLanjutDenganIklan = false;
    _lepasTombol();
  }

  /// Rekor baru dan koin yang diambil disimpan ke HP.
  void _simpanHasil() {
    if (skor.value > rekor.value) {
      rekor.value = skor.value;
      _penyimpanan.tulisInt(KunciSimpan.rekor, rekor.value);
    }
    dompet.tambah(_koinBelumDisimpan);
    _koinBelumDisimpan = 0;
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
    removeAll(children.whereType<Rintangan>());
    removeAll(children.whereType<BarangAmbilan>());
    removeAll(children.whereType<TeksMelayang>());
    removeAll(children.whereType<ParticleSystemComponent>());
    _waktuMunculJebakan = 0;
    _waktuMunculKoin = 0;
    _waktuMunculJam = 0;
    _waktuMunculPowerUp = 0;
  }

  @override
  void onRemove() {
    for (final notifier in [level, skor, dihindariDiLevelIni, koin, rekor]) {
      notifier.dispose();
    }
    sisaDetik.dispose();
    dompet.dispose();
    garasi.dispose();
    hadiahHarian.dispose();
    misi.dispose();
    status.dispose();
    super.onRemove();
  }
}
