import 'package:flutter/material.dart';

/// Utilitas layout adaptif untuk seluruh aplikasi.
///
/// Tujuan: satu halaman harus tampil benar pada HP kecil (lebar 320dp),
/// HP umum (360–430dp), maupun tablet (>=600dp), termasuk ketika pengguna
/// membesarkan ukuran font sistem.
///
/// Aturan praktis yang dipakai di seluruh fitur:
/// - JANGAN memberi tinggi tetap pada kartu yang isinya teks.
/// - Untuk grid, pakai [gridDelegate] (berbasis lebar + tinggi absolut),
///   bukan `crossAxisCount` + `childAspectRatio` yang menurunkan tinggi dari
///   lebar — itu penyebab overflow di layar sempit.
/// - Bungkus teks di dalam `Row` dengan `Expanded`/`Flexible`.
class Responsive {
  Responsive._();

  // ── Ambang lebar layar ─────────────────────────────────────────────────────
  /// HP kecil / layar sempit (mis. 320dp, atau jendela split-screen).
  static const double compactWidth = 360;

  /// Tablet & layar lebar.
  static const double expandedWidth = 600;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// Layar sempit — perkecil padding, turunkan ukuran font besar.
  static bool isCompact(BuildContext context) => widthOf(context) < compactWidth;

  /// Tablet / layar lebar — tambah kolom grid dan batasi lebar konten.
  static bool isExpanded(BuildContext context) => widthOf(context) >= expandedWidth;

  // ── Padding & jarak ────────────────────────────────────────────────────────
  /// Padding tepi halaman yang menyesuaikan lebar layar.
  static EdgeInsets pagePadding(BuildContext context) {
    final w = widthOf(context);
    if (w < compactWidth) return const EdgeInsets.all(12);
    if (w >= expandedWidth) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  /// Jarak antar elemen yang menyesuaikan lebar layar.
  static double gap(BuildContext context, {double base = 16}) {
    if (isCompact(context)) return base * 0.75;
    if (isExpanded(context)) return base * 1.25;
    return base;
  }

  // ── Grid ───────────────────────────────────────────────────────────────────
  /// Delegate grid yang aman dari overflow.
  ///
  /// Memakai [maxCrossAxisExtent] agar jumlah kolom mengikuti lebar layar, dan
  /// [mainAxisExtent] (tinggi absolut) alih-alih `childAspectRatio` sehingga
  /// tinggi sel TIDAK menyusut saat layar menyempit.
  ///
  /// [tinggi] ditambah sedikit mengikuti skala teks sistem supaya kartu tetap
  /// muat ketika pengguna membesarkan font.
  static SliverGridDelegate gridDelegate(
    BuildContext context, {
    double lebarMaks = 220,
    required double tinggi,
    double spacing = 10,
  }) {
    final skala = MediaQuery.textScalerOf(context).scale(1);
    final tinggiEfektif = tinggi * (skala > 1 ? skala : 1);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: lebarMaks,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      mainAxisExtent: tinggiEfektif,
    );
  }

  /// Jumlah kolom yang masuk akal untuk lebar layar saat ini.
  static int kolom(BuildContext context, {int min = 1, int max = 4}) {
    final w = widthOf(context);
    final n = (w / 200).floor();
    return n.clamp(min, max);
  }

  // ── Teks ───────────────────────────────────────────────────────────────────
  /// Ukuran font yang menyusut sedikit di layar sempit.
  static double fontSize(BuildContext context, double base) {
    if (isCompact(context)) return base * 0.9;
    return base;
  }

  /// Batas lebar konten agar teks tidak terlalu melebar di tablet.
  static double lebarKontenMaks(BuildContext context) =>
      isExpanded(context) ? 720 : double.infinity;

  /// Tinggi aman untuk sheet/daftar di dalam ruang tak terbatas.
  /// Dipakai menggantikan `MediaQuery.size.height * x` yang bisa melebihi
  /// ruang tersedia saat keyboard muncul.
  static double tinggiSheet(BuildContext context, {double rasio = 0.55}) {
    final mq = MediaQuery.of(context);
    final tersedia = mq.size.height - mq.viewInsets.bottom - mq.padding.vertical;
    return (tersedia * rasio).clamp(180.0, mq.size.height * 0.8);
  }
}

/// Pintasan ergonomis: `context.isCompact`, `context.pagePadding`, dst.
extension ResponsiveContext on BuildContext {
  bool get isCompact => Responsive.isCompact(this);
  bool get isExpandedScreen => Responsive.isExpanded(this);
  EdgeInsets get pagePadding => Responsive.pagePadding(this);
  double gap({double base = 16}) => Responsive.gap(this, base: base);
}
