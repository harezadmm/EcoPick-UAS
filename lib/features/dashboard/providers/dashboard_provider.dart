import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/dashboard_service.dart';
import '../models/dashboard_summary.dart';

final dashboardServiceProvider =
    Provider<DashboardService>((ref) => DashboardService());

final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return DashboardSummary.empty;
  final service = ref.read(dashboardServiceProvider);
  final summary = await service.fetch(user.id);
  if (summary.greenCoinBalance != user.greenCoinBalance) {
    ref.read(currentUserProvider.notifier).state =
        user.copyWith(greenCoinBalance: summary.greenCoinBalance);
  }
  return summary;
});
