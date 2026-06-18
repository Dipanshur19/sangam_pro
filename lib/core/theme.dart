import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand palette ─────────────────────────────────────
// NOTE: the primary brand color is exposed under the historical name
// `saffron` so the whole app keeps compiling, but the values below are the
// new professional indigo/emerald scheme.
class AppColors {
  AppColors._();

  // Primary brand — indigo (kept under the `saffron` name for compatibility)
  static const saffron       = Color(0xFF4F46E5);
  static const saffronLight  = Color(0xFFE0E7FF);
  static const saffronDark   = Color(0xFF3730A3);
  static const saffronGlow   = Color(0x404F46E5);

  // Emerald accent (for contrast + depth)
  static const indigo        = Color(0xFF0F766E);
  static const indigoLight   = Color(0xFFCCFBF1);

  // Clean cool surfaces
  static const background    = Color(0xFFF8FAFC);
  static const surface       = Color(0xFFFFFFFF);
  static const surfaceWarm   = Color(0xFFF8FAFF);
  static const surfaceTinted = Color(0xFFEEF2FF);
  static const border        = Color(0xFFE2E8F0);
  static const borderLight   = Color(0xFFEEF2F6);

  // Text — slate
  static const text1         = Color(0xFF0F172A);
  static const text2         = Color(0xFF475569);
  static const text3         = Color(0xFF94A3B8);
  static const text4         = Color(0xFFCBD5E1);

  // Payment source — brand-accurate
  static const paytm         = Color(0xFF002970);
  static const paytmBg       = Color(0xFFEEF2FF);
  static const paytmGlow     = Color(0x30002970);
  static const gpay          = Color(0xFF1A73E8);
  static const gpayBg        = Color(0xFFE8F1FD);
  static const gpayGlow      = Color(0x301A73E8);
  static const phonePe       = Color(0xFF5F259F);
  static const phonePeBg     = Color(0xFFF3EEFF);
  static const phonePeGlow   = Color(0x305F259F);
  static const cash          = Color(0xFF059669);
  static const cashBg        = Color(0xFFD1FAE5);
  static const cashGlow      = Color(0x30059669);
  static const udhar         = Color(0xFFE11D48);
  static const udharBg       = Color(0xFFFFE4E6);
  static const udharGlow     = Color(0x30E11D48);

  // Semantic
  static const success       = Color(0xFF059669);
  static const successBg     = Color(0xFFD1FAE5);
  static const warning       = Color(0xFFD97706);
  static const warningBg     = Color(0xFFFEF3C7);
  static const error         = Color(0xFFE11D48);
  static const errorBg       = Color(0xFFFFE4E6);
  static const info          = Color(0xFF0284C7);
  static const infoBg        = Color(0xFFE0F2FE);

  // Glass effect
  static const glass         = Color(0xAAFFFFFF);
  static const glassBorder   = Color(0x60FFFFFF);
  static const glassDark     = Color(0x20000000);
}

class AppGradients {
  AppGradients._();

  static const saffron = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const saffronRadial = RadialGradient(
    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
    center: Alignment(-0.3, -0.3), radius: 1.2,
  );
  static const card = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const darkCard = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const paytm = LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF002970)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gpay  = LinearGradient(colors: [Color(0xFF4A9EF0), Color(0xFF1A73E8)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const phonePe = LinearGradient(colors: [Color(0xFF8B4EC4), Color(0xFF5F259F)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const cash  = LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const udhar = LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> sm = [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))];
  static List<BoxShadow> md = [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))];
  static List<BoxShadow> lg = [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 8))];
  static List<BoxShadow> saffron = [BoxShadow(color: AppColors.saffron.withOpacity(0.32), blurRadius: 20, offset: const Offset(0, 6))];
  static List<BoxShadow> glow(Color c) => [BoxShadow(color: c.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)];
}

class AppRadius {
  AppRadius._();
  static const sm   = 8.0;
  static const md   = 12.0;
  static const lg   = 16.0;
  static const xl   = 20.0;
  static const xxl  = 28.0;
  static const full = 999.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class AppTextStyles {
  AppTextStyles._();
  static const _f = 'Poppins';

  static const display  = TextStyle(fontFamily: _f, fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.text1, height: 1.1, letterSpacing: -1.5);
  static const h1       = TextStyle(fontFamily: _f, fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text1, height: 1.15, letterSpacing: -1.0);
  static const h2       = TextStyle(fontFamily: _f, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1, height: 1.2, letterSpacing: -0.5);
  static const h3       = TextStyle(fontFamily: _f, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text1, height: 1.3);
  static const h4       = TextStyle(fontFamily: _f, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text1, height: 1.35);
  static const body     = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.text2, height: 1.5);
  static const bodySm   = TextStyle(fontFamily: _f, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.text2, height: 1.5);
  static const bodyMd   = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text1, height: 1.5);
  static const caption  = TextStyle(fontFamily: _f, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.text3, height: 1.4);
  static const label    = TextStyle(fontFamily: _f, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text3, letterSpacing: 0.08, height: 1.4);
  static const labelCaps = TextStyle(fontFamily: _f, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.12, height: 1.3);
  static const amount   = TextStyle(fontFamily: _f, fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.text1, letterSpacing: -1.5, height: 1.1);
  static const amountMd = TextStyle(fontFamily: _f, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1, letterSpacing: -0.5, height: 1.2);
  static const amountSm = TextStyle(fontFamily: _f, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1, letterSpacing: -0.5, height: 1.3);
  static const btn      = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.2);
  static const btnSm    = TextStyle(fontFamily: _f, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.1);
  static const mono     = TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.5);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.saffron,
      primary: AppColors.saffron,
      secondary: AppColors.indigo,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: AppTextStyles.h4,
      iconTheme: const IconThemeData(color: AppColors.text1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.saffron,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.btn,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.saffron,
        textStyle: AppTextStyles.btn,
        side: const BorderSide(color: AppColors.saffron, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.saffron, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.text4),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl), side: const BorderSide(color: AppColors.borderLight, width: 0.5)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 0.5, space: 0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.saffron,
      unselectedItemColor: AppColors.text4,
      elevation: 0, type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 10),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      contentTextStyle: AppTextStyles.bodySm.copyWith(color: Colors.white),
      backgroundColor: AppColors.text1,
    ),
  );
}
