import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/store_setup/store_setup_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/add_transaction/add_transaction_screen.dart';
import 'presentation/screens/customers/customers_screen.dart';
import 'presentation/screens/customers/customer_detail_screen.dart';
import 'presentation/screens/report/report_screen.dart';
import 'presentation/screens/staff/staff_screen.dart';
import 'presentation/screens/sms_queue/sms_queue_screen.dart';
import 'presentation/screens/photo_import/photo_import_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',       builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding',   builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/store-setup',  builder: (_, __) => const StoreSetupScreen()),
    GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/otp',          builder: (_, state) => OtpScreen(phone: state.extra as String? ?? '')),
    GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/add',          builder: (_, __) => const AddTransactionScreen()),
    GoRoute(path: '/customers',    builder: (_, __) => const CustomersScreen()),
    GoRoute(path: '/customer/:id', builder: (_, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
    GoRoute(path: '/report',       builder: (_, __) => const ReportScreen()),
    GoRoute(path: '/staff',        builder: (_, __) => const StaffScreen()),
    GoRoute(path: '/sms-queue',    builder: (_, __) => const SmsQueueScreen()),
    GoRoute(path: '/photo-import', builder: (_, __) => const PhotoImportScreen()),
    GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Not found: ${state.error}'))),
);
