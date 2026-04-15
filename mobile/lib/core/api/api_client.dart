import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/features/auth/presentation/providers/auth_provider.dart';

const String _baseUrl = 'https://fintrack-server.up.railway.app';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
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
      print('→ Request: ${options.method} ${options.uri}');
      return handler.next(options);
    },

    onResponse: (response, handler) {
      print('← Response: ${response.statusCode} ${response.requestOptions.uri}');
      return handler.next(response);
    },

    onError: (DioException e, handler) async {
      print('✘ Dio Error: ${e.type}');
      print('   Message: ${e.message}');
      if (e.response != null) {
        print('   Status: ${e.response?.statusCode}');
        print('   Data: ${e.response?.data}');
      }

      if (e.response?.statusCode == 401) {
        final path = e.requestOptions.path;
        if (!path.contains('/auth/login') && !path.contains('/auth/register')) {
          await ref.read(authProvider.notifier).logout();
        }
      }

      return handler.next(e);
    },
  ));

  return dio;
});