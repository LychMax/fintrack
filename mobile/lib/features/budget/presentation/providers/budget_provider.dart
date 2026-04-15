import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/currency.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '/core/api/api_client.dart';
import '../../domain/budget_dto.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  ref.watch(currentAuthUserProvider);
  return BudgetNotifier(ref);
});

class BudgetState {
  final List<BudgetDto> budgets;
  final List<BudgetStatusDto> statuses;
  final bool isLoading;
  final String? error;

  BudgetState({
    this.budgets = const [],
    this.statuses = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    List<BudgetDto>? budgets,
    List<BudgetStatusDto>? statuses,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final Ref ref;

  BudgetNotifier(this.ref) : super(BudgetState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/budgets'),
        dio.get('/budgets/status'),
      ]);

      final budgets = (results[0].data as List)
          .map((j) => BudgetDto.fromJson(j as Map<String, dynamic>))
          .toList();

      final statuses = (results[1].data as List)
          .map((j) => BudgetStatusDto.fromJson(j as Map<String, dynamic>))
          .toList();

      state = state.copyWith(budgets: budgets, statuses: statuses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createOrUpdate({
    required int categoryId,
    required double amount,
    required PeriodType periodType,
    required Currency currency,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/budgets', data: {
        'categoryId': categoryId,
        'amount': amount,
        'periodType': periodType.name,
        'currency': currency.code,
      });
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Не удалось сохранить бюджет: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/budgets/$id');
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: 'Не удалось удалить бюджет: $e');
      rethrow;
    }
  }

  Future<void> refresh() => loadAll();
}