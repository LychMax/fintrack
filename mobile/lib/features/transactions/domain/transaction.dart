import 'package:fintrack_mobile/core/models/currency.dart';

class Transaction {
  final int id;
  final double amount;
  final String type;
  final Category category;
  final DateTime date;
  final String? description;
  final Currency originalCurrency;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.originalCurrency = Currency.BYN,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      originalCurrency: Currency.fromCode(json['currency'] as String?),
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}