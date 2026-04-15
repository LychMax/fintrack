import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/currency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../domain/budget_dto.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Планирование бюджета',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: () => ref.read(budgetProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            onPressed: () => _showBudgetDialog(context, ref),
          ),
        ],
      ),
      body: state.isLoading && state.budgets.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : state.error != null
          ? _buildError(context, ref, state.error!)
          : state.statuses.isEmpty
          ? _buildEmpty(context, ref)
          : RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(budgetProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            ...state.statuses.map(
                  (s) => _buildBudgetStatusCard(context, ref, s),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.primaryForeground,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить бюджет'),
        onPressed: () => _showBudgetDialog(context, ref),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Бюджеты автоматически сбрасываются в начале каждого периода.',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatusCard(BuildContext context, WidgetRef ref, BudgetStatusDto s) {
    final percent = (s.percentUsed.clamp(0.0, 100.0) / 100.0);
    final (progressColor, textColor, statusLabel) = _getStatusColorsAndLabel(s);

    final periodLabel = s.periodType == PeriodType.MONTHLY ? 'месяц' : 'неделю';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: s.exceeded
            ? Border.all(color: AppTheme.destructive.withOpacity(0.4), width: 1)
            : s.nearLimit
            ? Border.all(color: AppTheme.amber.withOpacity(0.4), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.categoryName,
                      style: const TextStyle(
                        color: AppTheme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'на $periodLabel',
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (s.exceeded)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.warning_rounded, color: AppTheme.destructive, size: 18),
                    )
                  else if (s.nearLimit)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.warning_amber_rounded, color: AppTheme.amber, size: 18),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.mutedForeground, size: 18),
                    onPressed: () => _showBudgetDialog(context, ref, status: s),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.destructive, size: 18),
                    onPressed: () => _confirmDelete(context, ref, s),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.spentAmount.toStringAsFixed(0)} / ${s.budgetAmount.toStringAsFixed(0)} ${s.currency}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${s.percentUsed.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            statusLabel,
            style: TextStyle(color: textColor, fontSize: 12),
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
      'Превышен на ${(s.spentAmount - s.budgetAmount).toStringAsFixed(0)} ${s.currency}'
      );
    } else if (s.nearLimit) {
      return (
      AppTheme.amber,
      AppTheme.amber,
      'Осталось ${s.remainingAmount.toStringAsFixed(0)} ${s.currency}'
      );
    } else {
      return (
      AppTheme.income,
      AppTheme.income,
      'Осталось ${s.remainingAmount.toStringAsFixed(0)} ${s.currency}'
      );
    }
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppTheme.mutedForeground.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет бюджетов',
            style: TextStyle(color: AppTheme.mutedForeground, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Установите лимиты для своих категорий',
            style: TextStyle(color: AppTheme.mutedForeground.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Добавить бюджет'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.primaryForeground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _showBudgetDialog(context, ref),
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
            onPressed: () => ref.read(budgetProvider.notifier).refresh(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, {BudgetStatusDto? status}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetFormSheet(
        status: status,
        onSaved: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, BudgetStatusDto s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Удалить бюджет?', style: TextStyle(color: AppTheme.foreground)),
        content: Text(
          'Бюджет для «${s.categoryName}» будет удалён.',
          style: const TextStyle(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Отмена', style: TextStyle(color: AppTheme.mutedForeground)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppTheme.destructive)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(budgetProvider.notifier).deleteBudget(s.id);
    }
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final BudgetStatusDto? status;
  final VoidCallback onSaved;

  const _BudgetFormSheet({this.status, required this.onSaved});

  @override
  ConsumerState<_BudgetFormSheet> createState() => __BudgetFormSheetState();
}

class __BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _amountController = TextEditingController();
  int? _selectedCategoryId;
  PeriodType _selectedPeriod = PeriodType.MONTHLY;
  late Currency _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = Currency.BYN;

    if (widget.status != null) {
      _amountController.text = widget.status!.budgetAmount.toStringAsFixed(0);
      _selectedCategoryId = widget.status!.categoryId;
      _selectedPeriod = widget.status!.periodType;
      _selectedCurrency = Currency.fromCode(widget.status!.currency);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите категорию')),
      );
      return;
    }

    try {
      await ref.read(budgetProvider.notifier).createOrUpdate(
        categoryId: _selectedCategoryId!,
        amount: double.parse(amountText),
        periodType: _selectedPeriod,
        currency: _selectedCurrency,
      );

      widget.onSaved();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бюджет сохранён'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                widget.status == null ? 'Новый бюджет' : 'Редактировать бюджет',
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              const Text('Категория', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Выберите категорию',
                    hintStyle: const TextStyle(color: AppTheme.mutedForeground),
                  ),
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.foreground),
                  items: cats
                      .map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.name),
                  ))
                      .toList(),
                  onChanged: widget.status != null
                      ? null
                      : (v) => setState(() => _selectedCategoryId = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Text(
                  'Ошибка загрузки категорий: $e',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

              const SizedBox(height: 20),

              const Text('Период', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: PeriodType.values.map((p) {
                  final selected = _selectedPeriod == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = p),
                      child: Container(
                        margin: EdgeInsets.only(right: p == PeriodType.MONTHLY ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.background,
                          border: Border.all(
                            color: selected ? AppTheme.primary : AppTheme.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            p.label,
                            style: TextStyle(
                              color: selected ? AppTheme.primary : AppTheme.mutedForeground,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              const Text('Валюта', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonFormField<Currency>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(border: InputBorder.none),
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.foreground),
                  items: Currency.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCurrency = value);
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text('Лимит', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.foreground, fontSize: 18),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: AppTheme.mutedForeground),
                  prefixText: '${_selectedCurrency.symbol} ',
                  prefixStyle: const TextStyle(color: AppTheme.mutedForeground, fontSize: 18),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.primaryForeground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.status == null ? 'Создать бюджет' : 'Сохранить',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}