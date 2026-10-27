import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class CategoryInfo {
  final String name;
  final String emoji;
  final Color color;

  const CategoryInfo({
    required this.name,
    required this.emoji,
    required this.color,
  });
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? personName; // Extracted recipient/sender name (e.g. "Priya", "Rahul")
  final String? note;
  final String? bankName;
  final String? accountNumber;
  final String? senderAddress; // e.g. "VK-HDFCBK", "Truecaller", "AD-SBIINB", "GPay"
  final String source; // 'sms_auto', 'truecaller_sms', 'pdf_statement', 'push_notification', 'manual_entry'

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.personName,
    this.note,
    this.bankName,
    this.accountNumber,
    this.senderAddress,
    this.source = 'manual_entry',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'personName': personName,
      'note': note,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'senderAddress': senderAddress,
      'source': source,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: json['category'] as String? ?? 'General',
      date: DateTime.parse(json['date'] as String),
      personName: json['personName'] as String?,
      note: json['note'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      senderAddress: json['senderAddress'] as String?,
      source: json['source'] as String? ?? 'manual_entry',
    );
  }

  static const List<CategoryInfo> defaultCategories = [
    CategoryInfo(name: 'Romance & Dates 💖', emoji: '💖', color: Color(0xFFFF3366)),
    CategoryInfo(name: 'Food & Dining 🍔', emoji: '🍔', color: Color(0xFFFFE600)),
    CategoryInfo(name: 'Shopping 🛍️', emoji: '🛍️', color: Color(0xFF00F0FF)),
    CategoryInfo(name: 'Transport & Fuel 🚗', emoji: '🚗', color: Color(0xFFA855F7)),
    CategoryInfo(name: 'Bills & Utilities ⚡', emoji: '⚡', color: Color(0xFFFFB7B2)),
    CategoryInfo(name: 'Entertainment 🎬', emoji: '🎬', color: Color(0xFF2ECC71)),
    CategoryInfo(name: 'P2P Transfer 💸', emoji: '💸', color: Color(0xFFFF9F43)),
    CategoryInfo(name: 'Salary & Income 💰', emoji: '💰', color: Color(0xFF2ECC71)),
    CategoryInfo(name: 'General 📌', emoji: '📌', color: Color(0xFFE5E7EB)),
  ];

  static CategoryInfo getCategoryInfo(String categoryName) {
    return defaultCategories.firstWhere(
      (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()) || categoryName.toLowerCase().contains(cat.name.toLowerCase()),
      orElse: () => CategoryInfo(name: categoryName, emoji: '📌', color: const Color(0xFF00F0FF)),
    );
  }
}

class BudgetModel {
  final double monthlyLimit;
  final Map<String, double> categoryLimits;

  BudgetModel({
    this.monthlyLimit = 35000.0,
    Map<String, double>? categoryLimits,
  }) : categoryLimits = categoryLimits ?? {
          'Romance & Dates 💖': 8000.0,
          'Food & Dining 🍔': 6000.0,
          'Shopping 🛍️': 5000.0,
          'Transport & Fuel 🚗': 3000.0,
          'Bills & Utilities ⚡': 4000.0,
        };

  Map<String, dynamic> toJson() => {
        'monthlyLimit': monthlyLimit,
        'categoryLimits': categoryLimits,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 35000.0,
        categoryLimits: (json['categoryLimits'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      );
}

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String emoji;
  final DateTime? targetDate;
  final bool isCompleted;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.emoji = '💖',
    this.targetDate,
    this.isCompleted = false,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'emoji': emoji,
        'targetDate': targetDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
        emoji: json['emoji'] as String? ?? '💖',
        targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate'] as String) : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  GoalModel copyWith({
    double? currentAmount,
    bool? isCompleted,
  }) =>
      GoalModel(
        id: id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        emoji: emoji,
        targetDate: targetDate,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
