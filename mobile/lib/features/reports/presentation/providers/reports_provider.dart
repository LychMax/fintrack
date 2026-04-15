import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '/core/api/api_client.dart';

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  ref.watch(currentAuthUserProvider);
  return ReportsNotifier(ref);
});

class ReportsState {
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryExpenses;
  final Map<String, double> categoryIncomes;
  final List<DailySummary> dailySummaries;
  final bool isLoading;
  final String? error;

  ReportsState({
    this.startDate,
    this.endDate,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.balance = 0.0,
    this.categoryExpenses = const {},
    this.categoryIncomes = const {},
    this.dailySummaries = const [],
    this.isLoading = false,
    this.error,
  });

  ReportsState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    Map<String, double>? categoryExpenses,
    Map<String, double>? categoryIncomes,
    List<DailySummary>? dailySummaries,
    bool? isLoading,
    String? error,
  }) {
    return ReportsState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      categoryIncomes: categoryIncomes ?? this.categoryIncomes,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DailySummary {
  final DateTime date;
  final double income;
  final double expense;

  DailySummary({
    required this.date,
    required this.income,
    required this.expense,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date'] as String),
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final Ref ref;

  ReportsNotifier(this.ref) : super(ReportsState()) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1, 0, 0, 0);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    loadReport(start, end);
  }

  Future<void> loadReport(DateTime start, DateTime end) async {
    state = state.copyWith(isLoading: true, error: null, startDate: start, endDate: end);

    try {
      final dio = ref.read(dioProvider);

      final response = await dio.get(
        '/transactions/report',
        queryParameters: {
          'from': start.toIso8601String(),
          'to': end.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final catExpensesMap = <String, double>{};
        final catIncomesMap = <String, double>{};
        final dailyList = <DailySummary>[];

        if (data['categoryExpenses'] != null) {
          for (final item in data['categoryExpenses'] as List) {
            final name = item['categoryName'] as String;
            final amount = (item['totalExpense'] as num).toDouble();
            if (amount > 0) catExpensesMap[name] = amount;
          }
        }

        if (data['categoryIncomes'] != null) {
          for (final item in data['categoryIncomes'] as List) {
            final name = item['categoryName'] as String;
            final amount = (item['totalIncome'] as num).toDouble();
            if (amount > 0) catIncomesMap[name] = amount;
          }
        }

        if (data['dailySummaries'] != null) {
          for (final item in data['dailySummaries'] as List) {
            dailyList.add(DailySummary.fromJson(item));
          }
        }

        state = state.copyWith(
          totalIncome: (data['totalIncome'] as num? ?? 0).toDouble(),
          totalExpense: (data['totalExpense'] as num? ?? 0).toDouble(),
          balance: (data['balance'] as num? ?? 0).toDouble(),
          categoryExpenses: catExpensesMap,
          categoryIncomes: catIncomesMap,
          dailySummaries: dailyList,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    if (state.startDate != null && state.endDate != null) {
      await loadReport(state.startDate!, state.endDate!);
    } else {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      await loadReport(start, end);
    }
  }
}