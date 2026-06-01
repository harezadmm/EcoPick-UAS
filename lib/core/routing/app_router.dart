import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/landing_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/user_dashboard_page.dart';
import '../../features/ecodrop/models/ecodrop_result.dart';
import '../../features/ecodrop/presentation/ecodrop_page.dart';
import '../../features/ecodrop/presentation/ecodrop_success_page.dart';
import '../../features/ecopick/models/ecopick_result.dart';
import '../../features/ecopick/presentation/ecopick_page.dart';
import '../../features/ecopick/presentation/ecopick_success_page.dart';
import '../../features/greencoin/models/withdraw_request.dart';
import '../../features/greencoin/presentation/greencoin_page.dart';
import '../../features/greencoin/presentation/withdraw_success_page.dart';
import '../../features/marketplace/presentation/marketplace_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/status/presentation/status_page.dart';
import '../../features/admin/dashboard/admin_dashboard_page.dart';
import '../../features/admin/master_data/admin_master_data_page.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const UserDashboardPage(),
          ),
          GoRoute(
            path: '/ecopick',
            name: 'ecopick',
            builder: (context, state) => const EcoPickPage(),
          ),
          GoRoute(
            path: '/ecodrop',
            name: 'ecodrop',
            builder: (context, state) => const EcoDropPage(),
          ),
          GoRoute(
            path: '/greencoin',
            name: 'greencoin',
            builder: (context, state) => const GreenCoinPage(),
          ),
          GoRoute(
            path: '/marketplace',
            name: 'marketplace',
            builder: (context, state) => const MarketplacePage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/ecopick/success',
        name: 'ecopick-success',
        builder: (context, state) => EcoPickSuccessPage(
          result: state.extra as EcoPickResult?,
        ),
      ),
      GoRoute(
        path: '/ecodrop/success',
        name: 'ecodrop-success',
        builder: (context, state) => EcoDropSuccessPage(
          result: state.extra as EcoDropResult?,
        ),
      ),
      GoRoute(
        path: '/withdraw/success',
        name: 'withdraw-success',
        builder: (context, state) => WithdrawSuccessPage(
          request: state.extra as WithdrawRequest?,
        ),
      ),
      GoRoute(
        path: '/status',
        name: 'status',
        builder: (context, state) => const StatusPage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/master-data',
        name: 'admin-master-data',
        builder: (context, state) => const AdminMasterDataPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.uri}'),
      ),
    ),
  );
});
