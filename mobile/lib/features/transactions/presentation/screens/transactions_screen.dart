import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../domain/transaction.dart';
import '../providers/transactions_provider.dart';

final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'ru');

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();

  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  String? _filterType;
  int? _filterCategoryId;

  bool get _hasActiveFilters =>
      _filterFromDate != null ||
          _filterToDate != null ||
          _filterType != null ||
          _filterCategoryId != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(transactionsProvider.notifier).loadMore());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsProvider.notifier).loadMore();
    }
  }

  void _showFiltersBottomSheet(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(categoriesProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось загрузить категории: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final categoriesAsync = ref.watch(categoriesProvider);
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Фильтры',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground,
                          ),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _filterFromDate = null;
                                _filterToDate = null;
                                _filterType = null;
                                _filterCategoryId = null;
                              });
                              setState(() {});
                            },
                            child: const Text('Сбросить', style: TextStyle(color: AppTheme.primary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Период', style: TextStyle(color: AppTheme.mutedForeground, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDateField('От', _filterFromDate, true, setModalState)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateField('До', _filterToDate, false, setModalState)),
                      ],
                    ),
                    const SizedBox(height: 28),

                    const Text('Тип', style: TextStyle(color: AppTheme.mutedForeground, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildChoiceChip('Все', null, _filterType == null, () => setModalState(() => _filterType = null)),
                        _buildChoiceChip('Доход', 'INCOME', _filterType == 'INCOME', () => setModalState(() => _filterType = 'INCOME')),
                        _buildChoiceChip('Расход', 'EXPENSE', _filterType == 'EXPENSE', () => setModalState(() => _filterType = 'EXPENSE')),
                      ],
                    ),
                    const SizedBox(height: 28),

                    const Text('Категория', style: TextStyle(color: AppTheme.mutedForeground, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      data: (cats) => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildChoiceChip('Все', null, _filterCategoryId == null, () => setModalState(() => _filterCategoryId = null)),
                          ...cats.map((cat) => _buildChoiceChip(
                            cat.name,
                            cat.id,
                            _filterCategoryId == cat.id,
                                () => setModalState(() => _filterCategoryId = cat.id),
                          )),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Ошибка загрузки категорий', style: TextStyle(color: Colors.redAccent)),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.background,
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Закрыть'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.background,
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Применить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, bool isFrom, StateSetter setModalState) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate == null) return;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );
        if (pickedTime == null) return;

        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setModalState(() {
          if (isFrom) {
            _filterFromDate = newDateTime;
          } else {
            _filterToDate = newDateTime;
          }
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? dateFormat.format(value) : label,
              style: TextStyle(color: value != null ? AppTheme.foreground : AppTheme.mutedForeground),
            ),
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, dynamic value, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primary.withOpacity(0.22),
      backgroundColor: AppTheme.card,
      side: selected ? const BorderSide(color: AppTheme.primary, width: 1.5) : null,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primary : AppTheme.foreground,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsProvider);
    final authState = ref.watch(authProvider);

    final mainCurrency = authState.mainCurrency;
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: mainCurrency.symbol,
      decimalDigits: mainCurrency.decimalDigits,
    );

    final filteredTransactions = transactionsState.transactions.where((t) {
      if (_filterFromDate != null && t.date.isBefore(_filterFromDate!)) return false;
      if (_filterToDate != null && t.date.isAfter(_filterToDate!)) return false;
      if (_filterType != null && t.type != _filterType) return false;
      if (_filterCategoryId != null && t.category.id != _filterCategoryId) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Транзакции',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppTheme.mutedForeground),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.background, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Фильтры',
            onPressed: () => _showFiltersBottomSheet(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.read(transactionsProvider.notifier).refresh(),
        child: Builder(
          builder: (context) {
            if (transactionsState.isLoading && transactionsState.transactions.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            if (transactionsState.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ошибка: ${transactionsState.error}', style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => ref.read(transactionsProvider.notifier).refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (filteredTransactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_off_rounded, size: 80, color: AppTheme.mutedForeground.withOpacity(0.6)),
                    const SizedBox(height: 16),
                    Text('Нет транзакций по фильтру', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Попробуйте изменить фильтры', style: TextStyle(color: AppTheme.mutedForeground.withOpacity(0.7))),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length + (transactionsState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredTransactions.length) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary)),
                  );
                }

                final t = filteredTransactions[index];
                return _buildTransactionCard(t, currencyFormat, mainCurrency);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.primaryForeground,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
        onPressed: () => _showTransactionForm(context, ref),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction t, NumberFormat currencyFormat, Currency mainCurrency) {
    final isIncome = t.type == 'INCOME';
    final color = isIncome ? AppTheme.income : AppTheme.expense;
    final sign = isIncome ? '+' : '-';

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.destructive,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text('Удалить?', style: TextStyle(color: AppTheme.foreground)),
            content: Text(
              'Транзакция «${t.category.name}» будет удалена',
              style: const TextStyle(color: AppTheme.mutedForeground),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Удалить', style: TextStyle(color: AppTheme.destructive)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(transactionsProvider.notifier).deleteTransaction(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.category.name} удалена')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionForm(context, ref, transaction: t),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(
                    isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.category.name,
                        style: const TextStyle(
                          color: AppTheme.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (t.description != null && t.description!.isNotEmpty)
                        Text(
                          t.description!,
                          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(t.date),
                        style: TextStyle(color: AppTheme.mutedForeground.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign ${currencyFormat.format(t.amount.abs())}',
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionForm(BuildContext context, WidgetRef ref, {Transaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransactionFormBottomSheet(
        transaction: transaction,
        onSaved: () {
          ref.read(transactionsProvider.notifier).refresh();
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _TransactionFormBottomSheet extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final VoidCallback onSaved;

  const _TransactionFormBottomSheet({this.transaction, required this.onSaved});

  @override
  ConsumerState<_TransactionFormBottomSheet> createState() => __TransactionFormBottomSheetState();
}

class __TransactionFormBottomSheetState extends ConsumerState<_TransactionFormBottomSheet> {
  late bool isIncome;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  DateTime _selectedDateTime = DateTime.now();
  late Currency _selectedCurrency;

  @override
  void initState() {
    super.initState();
    isIncome = widget.transaction?.type == 'INCOME' || widget.transaction == null;
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toStringAsFixed(2) ?? '',
    );
    _descriptionController = TextEditingController(text: widget.transaction?.description ?? '');
    _selectedCategoryId = widget.transaction?.category.id;
    _selectedDateTime = widget.transaction?.date ?? DateTime.now();
    _selectedCurrency = widget.transaction?.originalCurrency ?? Currency.BYN;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim().replaceAll(' ', '');
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректную сумму')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите категорию')));
      return;
    }

    final amount = double.parse(amountText);
    final type = isIncome ? 'INCOME' : 'EXPENSE';

    try {
      final dio = ref.read(dioProvider);
      final data = {
        'amount': amount,
        'date': _selectedDateTime.toIso8601String(),
        'description': _descriptionController.text.trim(),
        'type': type,
        'categoryId': _selectedCategoryId,
        'currency': _selectedCurrency.code,
      };

      if (widget.transaction != null) {
        await dio.put('/api/transactions/${widget.transaction!.id}', data: data);
      } else {
        await dio.post('/api/transactions', data: data);
      }

      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.transaction != null ? 'Транзакция обновлена' : 'Транзакция добавлена'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
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
                Row(
                  children: [
                    Expanded(child: _buildTypeButton('Доход', true, isIncome)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTypeButton('Расход', false, !isIncome)),
                  ],
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.foreground, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Сумма',
                    labelStyle: const TextStyle(color: AppTheme.mutedForeground),
                    prefixText: '${_selectedCurrency.symbol} ',
                    prefixStyle: const TextStyle(color: AppTheme.foreground, fontSize: 20),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Валюта', style: TextStyle(color: AppTheme.mutedForeground, fontWeight: FontWeight.w500)),
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
                    items: Currency.values.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.displayName),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedCurrency = value);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Категория',
                      labelStyle: const TextStyle(color: AppTheme.mutedForeground),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    dropdownColor: AppTheme.card,
                    style: const TextStyle(color: AppTheme.foreground),
                    items: categories.map((cat) => DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.name),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Ошибка категорий: $err', style: const TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 20),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Дата и время', style: TextStyle(color: AppTheme.mutedForeground)),
                  trailing: Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(_selectedDateTime),
                    style: const TextStyle(color: AppTheme.foreground, fontSize: 16),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;

                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (time == null) return;

                    setState(() {
                      _selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.foreground),
                  decoration: InputDecoration(
                    labelText: 'Описание (необязательно)',
                    labelStyle: const TextStyle(color: AppTheme.mutedForeground),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: Text(widget.transaction != null ? 'Сохранить изменения' : 'Добавить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(String label, bool income, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => isIncome = income),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.background,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.mutedForeground,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}