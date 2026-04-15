import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/currency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budget/presentation/screens/budget_screen.dart';
import '../providers/profile_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    final username = profileState.username ?? authState.username ?? 'Пользователь';
    final email = profileState.email ?? authState.email ?? '';
    final currency = profileState.mainCurrency ?? authState.mainCurrency ?? Currency.BYN;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Профиль',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.destructive),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 30),

            CircleAvatar(
              radius: 55,
              backgroundColor: AppTheme.primary.withOpacity(0.25),
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 48,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.foreground,
              ),
            ),

            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  email,
                  style: TextStyle(fontSize: 16, color: AppTheme.mutedForeground),
                ),
              ),

            const SizedBox(height: 40),

            _buildMenuCard(
              context,
              title: 'Редактировать профиль',
              subtitle: 'Логин и email',
              icon: Icons.person_outline_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              title: 'Сменить пароль',
              subtitle: 'Изменить пароль аккаунта',
              icon: Icons.lock_outline_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              title: 'Планирование бюджета',
              subtitle: 'Лимиты по категориям',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              ),
              accentColor: AppTheme.primary,
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              title: 'Основная валюта',
              subtitle: currency.displayName,
              icon: Icons.currency_exchange_rounded,
              onTap: () => _showCurrencyChangeDialog(context, ref, currency),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
        Color? accentColor,
      }) {
    final color = accentColor ?? AppTheme.primary;

    return Card(
      color: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.mutedForeground)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedForeground),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Выход', style: TextStyle(color: AppTheme.foreground)),
        content: const Text(
          'Вы действительно хотите выйти из аккаунта?',
          style: TextStyle(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Выйти', style: TextStyle(color: AppTheme.destructive)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCurrencyChangeDialog(
      BuildContext context,
      WidgetRef ref,
      Currency currentCurrency,
      ) async {
    Currency? selected = currentCurrency;

    final result = await showDialog<Currency>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Основная валюта', style: TextStyle(color: AppTheme.foreground)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: Currency.values.map((c) {
                return RadioListTile<Currency>(
                  title: Text(c.displayName, style: const TextStyle(color: AppTheme.foreground)),
                  value: c,
                  groupValue: selected,
                  activeColor: AppTheme.primary,
                  onChanged: (value) => setState(() => selected = value),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: AppTheme.mutedForeground)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Сохранить', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (result != null && result != currentCurrency) {
      try {
        await ref.read(profileProvider.notifier).updateMainCurrency(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Валюта изменена на ${result.displayName}'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось изменить валюту'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}