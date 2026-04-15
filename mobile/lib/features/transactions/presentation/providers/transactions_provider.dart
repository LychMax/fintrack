import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '/core/api/api_client.dart';
import '../../domain/transaction.dart';

final transactionsProvider =
StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  ref.watch(currentAuthUserProvider);
  return TransactionsNotifier(ref);
});

class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final Ref ref;

  TransactionsNotifier(this.ref) : super(TransactionsState()) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final page = state.currentPage + 1;
      const size = 20;

      final response = await dio.get(
        '/transactions',
        queryParameters: {'page': page - 1, 'size': size, 'sort': 'date,desc'},
      );

      final Map<String, dynamic> data = response.data;
      final List<dynamic> content = data['content'] ?? [];
      final newTransactions = content.map((json) => Transaction.fromJson(json)).toList();
      final bool hasMorePages = newTransactions.length == size;

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoading: false,
        hasMore: hasMorePages,
        currentPage: page,
      );
    } on DioException catch (e) {
      String errorMsg = 'Ошибка загрузки транзакций';
      if (e.response != null) errorMsg += ' (${e.response?.statusCode})';
      state = state.copyWith(isLoading: false, error: errorMsg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Неизвестная ошибка: $e');
    }
  }

  Future<void> loadFiltered({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    int? categoryId,
  }) async {
    state = TransactionsState(isLoading: true, hasMore: false);

    try {
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{
        'page': 0,
        'size': 200,
        'sort': 'date,desc',
      };

      if (fromDate != null) params['from'] = fromDate.toIso8601String();
      if (toDate != null) params['to'] = toDate.toIso8601String();
      if (type != null) params['type'] = type;
      if (categoryId != null) params['categoryId'] = categoryId;

      final response = await dio.get(
        '/transactions/filtered',
        queryParameters: params,
      );

      final Map<String, dynamic> data = response.data;
      final List<dynamic> content = data['content'] ?? [];
      final transactions = content.map((json) => Transaction.fromJson(json)).toList();

      state = TransactionsState(
        transactions: transactions,
        isLoading: false,
        hasMore: false,
      );
    } on DioException catch (e) {
      String errorMsg = 'Ошибка загрузки транзакций';
      if (e.response != null) errorMsg += ' (${e.response?.statusCode})';
      state = TransactionsState(isLoading: false, error: errorMsg);
    } catch (e) {
      state = TransactionsState(isLoading: false, error: 'Неизвестная ошибка: $e');
    }
  }

  Future<void> refresh() async {
    state = TransactionsState();
    await loadMore();
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/transactions/$id');
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Не удалось удалить транзакцию: $e');
    }
  }
}