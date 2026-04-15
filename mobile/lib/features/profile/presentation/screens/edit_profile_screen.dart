import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late String _originalUsername;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    final auth = ref.read(authProvider);

    final currentUsername = profile.username ?? auth.username ?? '';
    _originalUsername = currentUsername;

    _usernameController = TextEditingController(text: currentUsername);
    _emailController = TextEditingController(text: profile.email ?? auth.email ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || email.isEmpty) {
      _showSnackBar('Заполните все поля', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Введите корректный email', isError: true);
      return;
    }

    final usernameChanged = username != _originalUsername;

    try {
      await ref.read(profileProvider.notifier).updateProfile(username, email);

      if (usernameChanged) {
        _showSnackBar('Логин изменён. Пожалуйста, войдите заново.', isError: false);
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      } else {
        _showSnackBar('Профиль успешно обновлён', isError: false);
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      final errorMsg = ref.read(profileProvider).error ?? 'Не удалось обновить профиль';
      _showSnackBar(errorMsg, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Редактировать профиль',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: profileState.isLoading ? null : _saveProfile,
            child: Text(
              profileState.isLoading ? 'Сохранение...' : 'Сохранить',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 60,
                  color: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Личные данные',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.foreground,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Измените логин или email вашего аккаунта',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 40),

            _buildTextField(
              controller: _usernameController,
              label: 'Логин',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: profileState.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: profileState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Сохранить изменения',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (profileState.error != null)
              Center(
                child: Text(
                  profileState.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.foreground, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.mutedForeground),
        prefixIcon: Icon(icon, color: AppTheme.mutedForeground),
        filled: true,
        fillColor: AppTheme.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}