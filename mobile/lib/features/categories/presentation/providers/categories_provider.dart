import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '/../core/api/api_client.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(currentAuthUserProvider);

  final dio = ref.read(dioProvider);

  try {
    final response = await dio.get('/categories');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки категорий: ${response.statusCode}');
    }
  } on DioException catch (e) {
    throw Exception('Ошибка сети: ${e.message}');
  }
});

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}