import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/greencoin_service.dart';
import '../models/greencoin_transaction.dart';

final greenCoinServiceProvider =
    Provider<GreenCoinService>((ref) => GreenCoinService());

final greenCoinTransactionsProvider =
    FutureProvider<List<GreenCoinTransaction>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.read(greenCoinServiceProvider).fetchTransactions(user.id);
});

final greenCoinBalanceProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(greenCoinServiceProvider).fetchBalance(user.id);
});
