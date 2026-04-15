import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/currency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budget/domain/budget_dto.dart';
import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../providers/dashboard_provider.dart';

final dateFormat = DateFormat('dd MMM yyyy', 'ru');

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dashboardProvider.notifier).refresh();
        ref.read(budgetProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final budgetState = ref.watch(budgetProvider);

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final mainCurrency = authState.mainCurrency;
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: mainCurrency.symbol,
      decimalDigits: mainCurrency.decimalDigits,
    );

    if (dashboardState.isLoading && dashboardState.recentTransactions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'FinTrack',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.mutedForeground),
            tooltip: 'Бюджеты',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.mutedForeground),
            tooltip: 'Обновить',
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
              ref.read(budgetProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refresh();
          await ref.read(budgetProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(dashboardState.balance, currencyFormat, mainCurrency),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      'Доход за месяц',
                      dashboardState.incomeThisMonth,
                      AppTheme.income,
                      currencyFormat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStat(
                      'Расход за месяц',
                      dashboardState.expenseThisMonth,
                      AppTheme.expense,
                      currencyFormat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (budgetState.statuses.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Бюджеты',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      ),
                      child: const Text('Все', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...budgetState.statuses.take(4).map((s) => _buildBudgetProgressBar(s, currencyFormat)),
                const SizedBox(height: 32),
              ] else if (!budgetState.isLoading) ...[
                _buildBudgetPromo(context),
                const SizedBox(height: 32),
              ],

              Text(
                'Последние операции',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...dashboardState.recentTransactions.map((t) => _buildTransactionItem(t, currencyFormat)).toList(),

              if (dashboardState.recentTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Пока нет операций',
                      style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, NumberFormat currencyFormat, Currency currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.card, Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Текущий баланс', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16)),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(balance),
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: AppTheme.foreground,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(currency.code, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, double value, Color accentColor, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            fmt.format(value),
            style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t, NumberFormat fmt) {
    final isIncome = t.type == 'INCOME';
    final sign = isIncome ? '+' : '-';
    final color = isIncome ? AppTheme.income : AppTheme.expense;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.25),
          radius: 24,
          child: Icon(
            isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
          ),
        ),
        title: Text(t.category.name, style: const TextStyle(color: AppTheme.foreground, fontWeight: FontWeight.w600)),
        subtitle: t.description != null && t.description!.isNotEmpty
            ? Text(
          t.description!,
          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: Text(
          '$sign ${fmt.format(t.amount.abs())}',
          style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBudgetProgressBar(BudgetStatusDto s, NumberFormat fmt) {
    final clampedPercent = s.percentUsed.clamp(0.0, 100.0) / 100.0;
    final (barColor, labelColor, statusText) = _getStatusColorsAndLabel(s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (s.exceeded)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.warning_rounded, color: AppTheme.destructive, size: 14),
                    )
                  else if (s.nearLimit)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.warning_amber_rounded, color: AppTheme.amber, size: 14),
                    ),
                  Text(
                    s.categoryName,
                    style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '${s.spentAmount.toStringAsFixed(0)} / ${s.budgetAmount.toStringAsFixed(0)} ${s.currency}',
                style: TextStyle(color: labelColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: clampedPercent,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusText, style: TextStyle(color: labelColor, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${s.percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _getStatusColorsAndLabel(BudgetStatusDto s) {
    if (s.exceeded) {
      return (
      AppTheme.destructive,
      AppTheme.destructive,
      'превышен на ${(s.spentAmount - s.budgetAmount).toStringAsFixed(0)} ${s.currency}'
      );
    } else if (s.nearLimit) {
      return (
      AppTheme.amber,
      AppTheme.amber,
      'осталось ${s.remainingAmount.toStringAsFixed(0)} ${s.currency}'
      );
    } else {
      return (
      AppTheme.income,
      AppTheme.income,
      'осталось ${s.remainingAmount.toStringAsFixed(0)} ${s.currency}'
      );
    }
  }

  Widget _buildBudgetPromo(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 28),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Планирование бюджета',
                    style: TextStyle(color: AppTheme.foreground, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Установите лимиты на категории и следите за тратами',
                    style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }
}