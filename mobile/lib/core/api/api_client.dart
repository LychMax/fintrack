import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/features/auth/presentation/providers/auth_provider.dart';

const String _baseUrl = 'https://151.101.2.15';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final authState = ref.read(authProvider);

      if (authState.isAuthenticated && authState.token != null) {
        if (!options.path.contains('/auth/login') &&
            !options.path.contains('/auth/register')) {
          options.headers['Authorization'] = 'Bearer ${authState.token}';
        }
      }
      return handler.next(options);
    },

    onError: (DioException e, handler) async {
      final requestPath = e.requestOptions.path;

      if (e.response?.statusCode == 401) {
        final isPasswordChange = requestPath.contains('/auth/profile/password');

        if (isPasswordChange) {
          return handler.next(e);
        } else {
          await ref.read(authProvider.notifier).logout();
        }
      }

      return handler.next(e);
    },
  ));

  return dio;
});