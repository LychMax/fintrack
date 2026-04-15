import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/reports_provider.dart';

final dateFormat = DateFormat('dd.MM.yyyy', 'ru');

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    if (_startDate != null && _endDate != null) {
      ref.read(reportsProvider.notifier).loadReport(_startDate!, _endDate!);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final authState = ref.watch(authProvider);

    final mainCurrency = authState.mainCurrency;
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: mainCurrency.symbol,
      decimalDigits: mainCurrency.decimalDigits,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Отчёты',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
            tooltip: 'Выбрать период',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: () => ref.read(reportsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading && state.totalIncome == 0 && state.totalExpense == 0
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : state.error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка: ${state.error}', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary),
              onPressed: () => ref.read(reportsProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.read(reportsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickDateRange,
                child: Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.date_range_rounded, color: AppTheme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Период',
                                style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dateFormat.format(_startDate!)} — ${dateFormat.format(_endDate!)}',
                                style: const TextStyle(
                                  color: AppTheme.foreground,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Нажмите, чтобы изменить',
                                style: TextStyle(
                                  color: AppTheme.mutedForeground.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Доход',
                      value: state.totalIncome,
                      color: AppTheme.income,
                      icon: Icons.arrow_circle_up_rounded,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Расход',
                      value: state.totalExpense,
                      color: AppTheme.expense,
                      icon: Icons.arrow_circle_down_rounded,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                title: 'Баланс за период',
                value: state.balance,
                color: state.balance >= 0 ? AppTheme.income : AppTheme.expense,
                icon: Icons.balance_rounded,
                isLarge: true,
                currencyFormat: currencyFormat,
              ),
              const SizedBox(height: 32),

              if (state.categoryExpenses.isNotEmpty) ...[
                Text(
                  'Расходы по категориям',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.foreground),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 260,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(state.categoryExpenses),
                          centerSpaceRadius: 60,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: state.categoryExpenses.entries.map((e) {
                    final index = state.categoryExpenses.keys.toList().indexOf(e.key);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getPieColor(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e.key} — ${currencyFormat.format(e.value)}',
                          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              if (state.categoryIncomes.isNotEmpty) ...[
                Text(
                  'Доходы по категориям',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.foreground),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 260,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(state.categoryIncomes),
                          centerSpaceRadius: 60,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: state.categoryIncomes.entries.map((e) {
                    final index = state.categoryIncomes.keys.toList().indexOf(e.key);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getPieColor(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e.key} — ${currencyFormat.format(e.value)}',
                          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              if (state.dailySummaries.isNotEmpty) ...[
                Text(
                  'Доходы и расходы по дням',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.foreground),
                ),
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(width: 12, height: 12, color: AppTheme.income),
                                const SizedBox(width: 6),
                                const Text('Доходы', style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Row(
                              children: [
                                Container(width: 12, height: 12, color: AppTheme.expense),
                                const SizedBox(width: 6),
                                const Text('Расходы', style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 260,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _getMaxY(state.dailySummaries) * 1.15,
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= state.dailySummaries.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final date = state.dailySummaries[index].date;
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          DateFormat('dd.MM').format(date),
                                          style: const TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1000,
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: _generateBarGroupsFromDaily(state.dailySummaries),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final rodValue = rod.toY;
                                    final isIncomeRod = rodIndex == 0;
                                    return BarTooltipItem(
                                      '${isIncomeRod ? '+' : '-'} ${currencyFormat.format(rodValue)}',
                                      TextStyle(
                                        color: isIncomeRod ? AppTheme.income : AppTheme.expense,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (!state.isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Нет данных за выбранный период',
                      style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required Color color,
    IconData? icon,
    bool isLarge = false,
    required NumberFormat currencyFormat,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), AppTheme.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: isLarge ? 16 : 14,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: color,
                    size: isLarge ? 32 : 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyFormat.format(value),
                style: TextStyle(
                  color: color,
                  fontSize: isLarge ? 36 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, v) => sum + v);
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
    ];

    return data.entries.map((e) {
      final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
      final index = data.keys.toList().indexOf(e.key);
      return PieChartSectionData(
        value: e.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: colors[index % colors.length],
        radius: 70,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  double _getMaxY(List<DailySummary> daily) {
    if (daily.isEmpty) return 1000;
    double maxValue = 0;
    for (final d in daily) {
      if (d.income > maxValue) maxValue = d.income;
      if (d.expense > maxValue) maxValue = d.expense;
    }
    return maxValue;
  }

  List<BarChartGroupData> _generateBarGroupsFromDaily(List<DailySummary> dailySummaries) {
    return dailySummaries.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: day.income,
            color: AppTheme.income,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: day.expense,
            color: AppTheme.expense,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();
  }

  Color _getPieColor(int index) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFF97316),
    ];
    return colors[index % colors.length];
  }
}