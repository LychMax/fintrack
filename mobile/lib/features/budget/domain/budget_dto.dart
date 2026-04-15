enum PeriodType { MONTHLY, WEEKLY }

extension PeriodTypeLabel on PeriodType {
  String get label => this == PeriodType.MONTHLY ? 'Месяц' : 'Неделя';
}

class BudgetDto {
  final int id;
  final int categoryId;
  final String categoryName;
  final double amount;
  final PeriodType periodType;
  final String currency;

  const BudgetDto({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.periodType,
    required this.currency,
  });

  factory BudgetDto.fromJson(Map<String, dynamic> json) {
    return BudgetDto(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      amount: (json['amount'] as num).toDouble(),
      periodType: json['periodType'] == 'WEEKLY' ? PeriodType.WEEKLY : PeriodType.MONTHLY,
      currency: json['currency'] as String? ?? 'BYN',
    );
  }
}

class BudgetStatusDto {
  final int id;
  final int categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final double percentUsed;
  final PeriodType periodType;
  final String currency;
  final bool nearLimit;
  final bool exceeded;

  const BudgetStatusDto({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentUsed,
    required this.periodType,
    required this.currency,
    required this.nearLimit,
    required this.exceeded,
  });

  factory BudgetStatusDto.fromJson(Map<String, dynamic> json) {
    return BudgetStatusDto(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      percentUsed: (json['percentUsed'] as num).toDouble(),
      periodType: json['periodType'] == 'WEEKLY' ? PeriodType.WEEKLY : PeriodType.MONTHLY,
      currency: json['currency'] as String? ?? 'BYN',
      nearLimit: json['nearLimit'] as bool? ?? false,
      exceeded: json['exceeded'] as bool? ?? false,
    );
  }
}