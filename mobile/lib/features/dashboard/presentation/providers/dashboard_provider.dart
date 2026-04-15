import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '/core/api/api_client.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  ref.watch(currentAuthUserProvider);
  return DashboardNotifier(ref);
});

class DashboardState {
  final double balance;
  final double incomeThisMonth;
  final double expenseThisMonth;
  final List<Transaction> recentTransactions;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.balance = 0.0,
    this.incomeThisMonth = 0.0,
    this.expenseThisMonth = 0.0,
    this.recentTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    double? balance,
    double? incomeThisMonth,
    double? expenseThisMonth,
    List<Transaction>? recentTransactions,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      balance: balance ?? this.balance,
      incomeThisMonth: incomeThisMonth ?? this.incomeThisMonth,
      expenseThisMonth: expenseThisMonth ?? this.expenseThisMonth,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardNotifier(this.ref) : super(DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final now = DateTime.now();

      final allTimeFrom = DateTime(2000, 1, 1);
      final allTimeTo = DateTime(now.year + 1, 1, 1);

      final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final results = await Future.wait([
        dio.get('/transactions/report', queryParameters: {
          'from': allTimeFrom.toIso8601String(),
          'to': allTimeTo.toIso8601String(),
        }),
        dio.get('/transactions/report', queryParameters: {
          'from': monthStart.toIso8601String(),
          'to': monthEnd.toIso8601String(),
        }),
        dio.get('/transactions', queryParameters: {
          'page': 0,
          'size': 5,
          'sort': 'date,desc',
        }),
      ]);

      final allTimeData = results[0].data as Map<String, dynamic>;
      final monthData = results[1].data as Map<String, dynamic>;
      final recentData = results[2].data;

      final balance = (allTimeData['balance'] as num? ?? 0).toDouble();
      final incomeMonth = (monthData['totalIncome'] as num? ?? 0).toDouble();
      final expenseMonth = (monthData['totalExpense'] as num? ?? 0).toDouble();

      final List<dynamic> content = recentData['content'] ?? recentData;
      final recent = content.map((json) => Transaction.fromJson(json)).toList();

      state = state.copyWith(
        balance: balance,
        incomeThisMonth: incomeMonth,
        expenseThisMonth: expenseMonth,
        recentTransactions: recent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async => loadDashboard();
}