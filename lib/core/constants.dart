import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const saffron = Color(0xFFC45C12);
  static const saffronLight = Color(0xFFF5E6D8);
  static const saffronDark = Color(0xFF9B3E0A);

  // Backgrounds
  static const warmBg = Color(0xFFFAF8F4);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFEAE6DF);
  static const border2 = Color(0xFFF0EDE8);

  // Text
  static const text1 = Color(0xFF1A1A18);
  static const text2 = Color(0xFF4B4B47);
  static const text3 = Color(0xFF8A8A85);

  // Payment sources
  static const paytm = Color(0xFF002970);
  static const paytmBg = Color(0xFFEEF1FB);
  static const gpay = Color(0xFF1A73E8);
  static const gpayBg = Color(0xFFE8F1FD);
  static const phonePe = Color(0xFF5F259F);
  static const phonePeBg = Color(0xFFF0EAF9);
  static const cash = Color(0xFF0F6E56);
  static const cashBg = Color(0xFFE6F4EF);
  static const udhar = Color(0xFF9B3522);
  static const udharBg = Color(0xFFFCEEE9);

  // Status
  static const success = Color(0xFF0F6E56);
  static const warning = Color(0xFFBA7517);
  static const danger = Color(0xFFC13B2F);
  static const info = Color(0xFF1A73E8);
}

class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text1, letterSpacing: -0.5);
  static const heading2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1);
  static const heading3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text1);
  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1);
  static const titleMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text2);
  static const bodySm = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.text2);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.text3);
  static const captionBold = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text3);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text3, letterSpacing: 0.06);
  static const amount = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text1);
  static const amountSm = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text1);
  static const mono = TextStyle(fontFamily: 'monospace', fontSize: 13);
}

class AppConstants {
  AppConstants._();

  static const storeName = 'My Store';
  static const ownerPin = '1234';
  static const staffPin = '5678';
  static const creditDueDays = 7;
  static const storeId = 'default_store';

  // Firebase collections
  static const colCustomers = 'customers';
  static const colTransactions = 'transactions';
  static const colSmsQueue = 'smsQueue';
  static const colStaff = 'staff';

  // SharedPreferences keys
  static const keyRole = 'sangam_role';
  static const keyApiKey = 'sangam_api_key';
  static const keyOnboarded = 'sangam_onboarded';
}

class AppDimensions {
  AppDimensions._();

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radiusFull = 999.0;

  static const paddingPage = EdgeInsets.symmetric(horizontal: 16);
  static const paddingCard = EdgeInsets.all(16);
  static const paddingCardSm = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
}
