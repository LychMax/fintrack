import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Категории',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: () => ref.refresh(categoriesProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            onPressed: () => _showAddEditDialog(context, ref),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) => _buildError(context, ref, err.toString()),
        data: (categories) => categories.isEmpty
            ? _buildEmpty()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(context, ref, categories[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.primaryForeground,
        onPressed: () => _showAddEditDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, Category cat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primary.withOpacity(0.15),
          child: Text(
            cat.name.isNotEmpty ? cat.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cat.name,
          style: const TextStyle(
            color: AppTheme.foreground,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.mutedForeground),
              onPressed: () => _showAddEditDialog(context, ref, category: cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.destructive),
              onPressed: () => _confirmDelete(context, ref, cat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Нет категорий',
            style: TextStyle(fontSize: 18, color: AppTheme.mutedForeground),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте первую категорию',
            style: TextStyle(color: AppTheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ошибка: $error', style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.refresh(categoriesProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final controller = TextEditingController(text: category?.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(category == null ? 'Новая категория' : 'Редактировать категорию'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                final dio = ref.read(dioProvider);

                if (category == null) {
                  await dio.post('/api/categories', data: {'name': name});
                } else {
                  await dio.put('/api/categories/${category.id}', data: {'name': name});
                }

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ref.refresh(categoriesProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Text(category == null ? 'Добавить' : 'Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Удалить категорию?'),
        content: Text('«${cat.name}» будет удалена навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppTheme.destructive)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('/api/categories/${cat.id}');
        if (context.mounted) ref.refresh(categoriesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось удалить: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}