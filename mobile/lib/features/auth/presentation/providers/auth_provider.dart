import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import '../../../../core/models/currency.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

final storage = FlutterSecureStorage();

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentAuthUserProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isAuthenticated ? auth.username : null;
});

class AuthState {
  final String? token;
  final String? username;
  final String? email;
  final Currency mainCurrency;
  final bool isLoading;
  final String? error;

  AuthState({
    this.token,
    this.username,
    this.email,
    this.mainCurrency = Currency.BYN,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? token,
    String? username,
    String? email,
    Currency? mainCurrency,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      username: username ?? this.username,
      email: email ?? this.email,
      mainCurrency: mainCurrency ?? this.mainCurrency,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => token != null && token!.isNotEmpty;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState()) {
    _loadToken();
  }

  void updateUserInfo(String username, String email, {Currency? mainCurrency}) {
    state = state.copyWith(
      username: username,
      email: email,
      mainCurrency: mainCurrency ?? state.mainCurrency,
    );
  }

  Future<void> _loadToken() async {
    final token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      state = AuthState();
      return;
    }

    try {
      final payload = Jwt.parseJwt(token);

      final usernameFromToken = payload['sub'] as String?;
      final emailFromToken    = payload['email'] as String?;
      final currencyCode      = payload['mainCurrency'] as String?;

      state = AuthState(
        token: token,
        username: usernameFromToken,
        email: emailFromToken,
        mainCurrency: Currency.fromCode(currencyCode),
        isLoading: false,
      );

      await _fetchProfileAndUpdate();

      _refreshAllProviders();
    } catch (e) {
      await storage.delete(key: 'jwt_token');
      state = AuthState();
    }
  }

  Future<void> _fetchProfileAndUpdate() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/profile');
      final data = response.data as Map<String, dynamic>;

      final currency = Currency.fromCode(data['mainCurrency'] as String?);

      state = state.copyWith(
        username: data['username'] as String?,
        email:    data['email']    as String?,
        mainCurrency: currency,
      );
    } catch (_) {
    }
  }

  void _refreshAllProviders() {
    try {
      ref.invalidate(dashboardProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(reportsProvider);
    } catch (_) {}
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await login(username, password);
      } else {
        throw Exception('Ошибка регистрации');
      }
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMsg);
      rethrow;
    }
  }

  Future<void> login(String login, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'login': login,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await storage.write(key: 'jwt_token', value: token);

          final payload = Jwt.parseJwt(token);
          final usernameFromToken = payload['sub'] as String?;
          final emailFromToken    = payload['email'] as String?;
          final currencyCode      = payload['mainCurrency'] as String?;

          final currency = Currency.fromCode(currencyCode);

          state = AuthState(
            token: token,
            username: usernameFromToken,
            email: emailFromToken,
            mainCurrency: currency,
            isLoading: false,
            error: null,
          );

          _refreshAllProviders();
          return;
        }
      }
      throw Exception('Не удалось получить токен');
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      state = state.copyWith(isLoading: false, error: errorMsg);
      rethrow;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}