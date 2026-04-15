import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../../core/models/currency.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '/core/api/api_client.dart';

final storage = FlutterSecureStorage();

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  ref.watch(currentAuthUserProvider);
  return ProfileNotifier(ref);
});

class ProfileState {
  final String? username;
  final String? email;
  final Currency mainCurrency;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.username,
    this.email,
    this.mainCurrency = Currency.BYN,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    String? username,
    String? email,
    Currency? mainCurrency,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      username: username ?? this.username,
      email: email ?? this.email,
      mainCurrency: mainCurrency ?? this.mainCurrency,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/profile');

      final data = response.data as Map<String, dynamic>;

      state = state.copyWith(
        username: data['username'] as String?,
        email: data['email'] as String?,
        mainCurrency: Currency.fromCode(data['mainCurrency'] as String?),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateProfile(String username, String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/auth/profile', data: {
        'username': username,
        'email': email,
      });

      state = state.copyWith(
        username: username,
        email: email,
        isLoading: false,
      );

      ref.read(authProvider.notifier).updateUserInfo(username, email);
    } catch (e) {
      String message = 'Не удалось обновить профиль';
      if (e is DioException && e.response != null) {
        message = (e.response!.statusCode == 400 || e.response!.statusCode == 409)
            ? 'Логин или email уже используется'
            : 'Ошибка сервера';
      }
      state = state.copyWith(isLoading: false, error: message);
      rethrow;
    }
  }

  Future<void> updateMainCurrency(Currency newCurrency) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.put('/auth/profile', data: {
        'mainCurrency': newCurrency.code,
      });

      final data = response.data as Map<String, dynamic>;
      final newToken = data['token'] as String?;

      if (newToken != null && newToken.isNotEmpty) {
        await storage.write(key: 'jwt_token', value: newToken);

        final payload = Jwt.parseJwt(newToken);
        final currencyCode = payload['mainCurrency'] as String?;
        final currency = Currency.fromCode(currencyCode);

        state = state.copyWith(mainCurrency: currency, isLoading: false);

        ref.read(authProvider.notifier).updateUserInfo(
          ref.read(authProvider).username ?? '',
          ref.read(authProvider).email ?? '',
          mainCurrency: currency,
        );

        await Future.delayed(const Duration(milliseconds: 300));

        await ref.read(dashboardProvider.notifier).refresh();
        await ref.read(transactionsProvider.notifier).refresh();
        await ref.read(reportsProvider.notifier).refresh();
        await ref.read(budgetProvider.notifier).refresh();
      } else {
        state = state.copyWith(mainCurrency: newCurrency, isLoading: false);
        ref.read(authProvider.notifier).updateUserInfo(
          ref.read(authProvider).username ?? '',
          ref.read(authProvider).email ?? '',
          mainCurrency: newCurrency,
        );
        await ref.read(dashboardProvider.notifier).refresh();
      }
    } catch (e) {
      String message = 'Не удалось изменить валюту';
      if (e is DioException && e.response != null) {
        message = e.response!.data?['message']?.toString() ?? 'Ошибка сервера';
      }
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    state = ProfileState(
      username: state.username,
      email: state.email,
      mainCurrency: state.mainCurrency,
      isLoading: true,
      error: null,
    );

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/auth/profile/password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      state = ProfileState(
        username: state.username,
        email: state.email,
        mainCurrency: state.mainCurrency,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      String message = 'Ошибка сервера. Попробуйте позже';
      if (e is DioException && e.response != null) {
        if (e.response!.statusCode == 400 || e.response!.statusCode == 401) {
          message = 'Неверный текущий пароль';
        }
      }
      state = ProfileState(
        username: state.username,
        email: state.email,
        mainCurrency: state.mainCurrency,
        isLoading: false,
        error: message,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}