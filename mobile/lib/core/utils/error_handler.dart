import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error, {String? defaultMessage}) {
    if (error is DioException) {
      final response = error.response;

      if (response != null) {
        final statusCode = response.statusCode;
        final data = response.data;

        switch (statusCode) {
          case 400:
            if (data is Map<String, dynamic>) {
              if (data['errors'] != null) {
                final errors = data['errors'] as List;
                return errors
                    .map((e) => e['message'] ?? e['defaultMessage'] ?? 'Некорректные данные')
                    .join('\n');
              }
              if (data['message'] != null) {
                return data['message'].toString();
              }
            }
            return 'Некорректные данные';

          case 409:
            return 'Пользователь с таким логином или email уже существует';

          case 401:
            return 'Неверный логин или пароль';

          case 500:
            return 'Внутренняя ошибка сервера';

          default:
            if (data is Map && data['message'] != null) {
              return data['message'].toString();
            }
            return 'Ошибка сервера (${statusCode ?? 'неизвестный'})';
        }
      } else {
        return error.message ?? 'Ошибка сети';
      }
    }

    return defaultMessage ?? error.toString();
  }
}