import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/person_ledger.dart';
import '../services/android_sms_service.dart';
import '../services/notification_parser_service.dart';
import '../services/sms_parser.dart';

class FinanceProvider extends ChangeNotifier {
  static const String _storageKey = 'honeyyyb_transactions_v1';
  static const String _budgetKey = 'honeyyyb_budget_v1';
  static const String _goalsKey = 'honeyyyb_goals_v1';
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  BudgetModel _budget = BudgetModel();
  List<GoalModel> _goals = [];

  bool _isLoading = true;
  bool _isSyncingSms = false;
  SmsSyncResult? _lastSyncResult;
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  String _dateFilterMode = 'All'; // 'All', 'Today', 'This Week', 'This Month', 'Last 4 Months', 'Custom'
  DateTimeRange? _customDateRange;
  String _currencySymbol = '₹';

  List<TransactionModel> get transactions => _transactions;
  BudgetModel get budget => _budget;
  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get isSyncingSms => _isSyncingSms;
  SmsSyncResult? get lastSyncResult => _lastSyncResult;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;
  String get dateFilterMode => _dateFilterMode;
  DateTimeRange? get customDateRange => _customDateRange;
  String get currencySymbol => _currencySymbol;

  FinanceProvider() {
    _loadFromStorage();
  }

  // --- Financial Calculations ---
  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  double get thisMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get thisMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.income && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get thisMonthRomanceSpend {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year &&
            (t.category.contains('Romance') || t.category.contains('💖')))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // --- Filtered Transactions ---
  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();

    return _transactions.where((t) {
      // 1. Category Filter
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          t.category.toLowerCase().contains(_selectedCategoryFilter.toLowerCase());

      // 2. Search Query Filter
      final matchesQuery = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.personName != null && t.personName!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (t.note != null && t.note!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (t.bankName != null && t.bankName!.toLowerCase().contains(_searchQuery.toLowerCase()));

      // 3. Date Filter
      bool matchesDate = true;
      if (_dateFilterMode == 'Today') {
        matchesDate = t.date.year == now.year && t.date.month == now.month && t.date.day == now.day;
      } else if (_dateFilterMode == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        matchesDate = t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } else if (_dateFilterMode == 'This Month') {
        matchesDate = t.date.year == now.year && t.date.month == now.month;
      } else if (_dateFilterMode == 'Last 4 Months') {
        final cutoff = DateTime(now.year, now.month - 4, now.day);
        matchesDate = t.date.isAfter(cutoff);
      } else if (_dateFilterMode == 'Custom' && _customDateRange != null) {
        matchesDate = t.date.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
      }

      return matchesCategory && matchesQuery && matchesDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Known People for Autocomplete / Quick Chips ---
  List<String> get knownPeople {
    final Set<String> people = {};
    for (final t in _transactions) {
      if (t.personName != null && t.personName!.trim().isNotEmpty && t.personName != 'Unknown Merchant') {
        people.add(t.personName!.trim());
      } else if (t.title.isNotEmpty &&
          !t.title.toLowerCase().contains('statement') &&
          !t.title.toLowerCase().contains('expense') &&
          !t.title.toLowerCase().contains('income') &&
          !t.title.toLowerCase().contains('transaction') &&
          !t.title.toLowerCase().contains('recharge')) {
        people.add(t.title.trim());
      }
    }
    return people.toList()..sort();
  }

  // --- Person-to-Person Ledgers ---
  List<PersonLedger> get personLedgers {
    final Map<String, List<TransactionModel>> grouped = {};

    for (final t in _transactions) {
      String? key = t.personName?.trim();
      if (key == null || key.isEmpty || key == 'Unknown Merchant') {
        // Fallback to title if it represents a contact/merchant
        final title = t.title.trim();
        if (title.isNotEmpty &&
            !title.toLowerCase().contains('statement') &&
            !title.toLowerCase().contains('expense') &&
            !title.toLowerCase().contains('income') &&
            !title.toLowerCase().contains('general')) {
          key = title;
        }
      }

      if (key != null && key.isNotEmpty) {
        grouped.putIfAbsent(key, () => []).add(t);
      }
    }

    final List<PersonLedger> ledgers = [];
    grouped.forEach((person, txs) {
      double sent = 0;
      double received = 0;
      for (final t in txs) {
        if (t.type == TransactionType.expense) {
          sent += t.amount;
        } else {
          received += t.amount;
        }
      }
      ledgers.add(
        PersonLedger(
          personName: person,
          totalSent: sent,
          totalReceived: received,
          transactions: txs..sort((a, b) => b.date.compareTo(a.date)),
        ),
      );
    });

    // Sort by most recently active
    ledgers.sort((a, b) {
      if (a.transactions.isEmpty && b.transactions.isEmpty) return 0;
      if (a.transactions.isEmpty) return 1;
      if (b.transactions.isEmpty) return -1;
      final aDate = a.transactions.first.date;
      final bDate = b.transactions.first.date;
      return bDate.compareTo(aDate);
    });

    return ledgers;
  }

  // --- Filter Actions ---
  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter(String mode, {DateTimeRange? customRange}) {
    _dateFilterMode = mode;
    _customDateRange = customRange;
    notifyListeners();
  }

  void setCurrencySymbol(String symbol) {
    _currencySymbol = symbol;
    notifyListeners();
  }

  // --- Transaction Operations ---
  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _transactions[index] = updated;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Record a 1-tap Settlement with a Person
  Future<void> settleBalance({
    required String personName,
    required double amount,
    required TransactionType type, // Income = received settlement, Expense = paid settlement
    String? note,
  }) async {
    final newTx = TransactionModel(
      id: _uuid.v4(),
      title: type == TransactionType.income ? 'Settlement from $personName' : 'Settlement to $personName',
      amount: amount,
      type: type,
      category: 'P2P Transfer 💸',
      date: DateTime.now(),
      personName: personName,
      note: note ?? 'Balance settlement clearance via Honeyyyb',
      source: 'manual_entry',
    );
    await addTransaction(newTx);
  }

  /// Ingest Push Notification (GPay / PhonePe / Paytm / Bank)
  NotificationParseResult ingestPushNotification({
    required String title,
    required String body,
    String? packageName,
  }) {
    final result = NotificationParserService.parsePushNotification(
      title: title,
      body: body,
      packageName: packageName,
    );

    if (result.isFinancial && result.transaction != null) {
      addTransaction(result.transaction!);
    }

    return result;
  }

  /// Parses raw SMS text and automatically adds it if it's a valid transaction!
  ParsedSmsResult parseAndAddSms(String smsBody) {
    final parsed = SmsParserService.parseSms(smsBody);
    if (parsed.isTransaction && parsed.amount != null && parsed.type != null) {
      final newTx = TransactionModel(
        id: _uuid.v4(),
        title: parsed.personOrMerchant != null
            ? '${parsed.type == TransactionType.expense ? 'Paid' : 'Recv'}: ${parsed.personOrMerchant}'
            : (parsed.type == TransactionType.expense ? 'Expense' : 'Income'),
        amount: parsed.amount!,
        type: parsed.type!,
        category: parsed.category,
        date: parsed.messageDate ?? DateTime.now(),
        personName: parsed.personOrMerchant,
        bankName: parsed.bankName,
        accountNumber: parsed.accountNumber,
        note: parsed.note ?? parsed.rawText,
        source: 'sms_manual',
      );
      addTransaction(newTx);
    }
    return parsed;
  }

  /// Scans inbox / SMS starting from the last 4 months and updates transactions
  Future<SmsSyncResult> syncLastFourMonthsSms() async {
    _isSyncingSms = true;
    notifyListeners();

    try {
      final syncResult = await AndroidSmsService.scanLastFourMonthsInbox(
        existingTransactions: _transactions,
      );

      if (syncResult.parsedTransactions.isNotEmpty) {
        _transactions.insertAll(0, syncResult.parsedTransactions);
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        await _saveToStorage();
      }

      _lastSyncResult = syncResult;
      return syncResult;
    } catch (e) {
      debugPrint('Error syncing 4-month SMS: $e');
      final errorResult = SmsSyncResult(
        totalScanned: 0,
        newTransactionsAdded: 0,
        duplicatesSkipped: 0,
        startDate: AndroidSmsService.getFourMonthsAgoDate(),
        endDate: DateTime.now(),
        parsedTransactions: [],
        statusMessage: 'Sync error: $e',
        isSuccess: false,
      );
      _lastSyncResult = errorResult;
      return errorResult;
    } finally {
      _isSyncingSms = false;
      notifyListeners();
    }
  }

  int importTransactionsList(List<TransactionModel> txList) {
    int addedCount = 0;
    for (final tx in txList) {
      final isDuplicate = _transactions.any((existing) =>
          existing.amount == tx.amount &&
          existing.type == tx.type &&
          existing.date.year == tx.date.year &&
          existing.date.month == tx.date.month &&
          existing.date.day == tx.date.day &&
          (existing.personName == tx.personName || existing.note == tx.note));

      if (!isDuplicate) {
        _transactions.add(tx);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _saveToStorage();
      notifyListeners();
    }

    return addedCount;
  }

  // --- Budget Operations ---
  Future<void> updateMonthlyBudget(double limit) async {
    _budget = BudgetModel(
      monthlyLimit: limit,
      categoryLimits: _budget.categoryLimits,
    );
    notifyListeners();
    await _saveBudgetsToStorage();
  }

  Future<void> updateCategoryBudget(String category, double limit) async {
    final newLimits = Map<String, double>.from(_budget.categoryLimits);
    newLimits[category] = limit;
    _budget = BudgetModel(
      monthlyLimit: _budget.monthlyLimit,
      categoryLimits: newLimits,
    );
    notifyListeners();
    await _saveBudgetsToStorage();
  }

  // --- Milestone & Romance Goals Operations ---
  Future<void> addGoal(GoalModel goal) async {
    _goals.add(goal);
    notifyListeners();
    await _saveGoalsToStorage();
  }

  Future<void> updateGoal(GoalModel goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      notifyListeners();
      await _saveGoalsToStorage();
    }
  }

  Future<void> contributeToGoal(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final current = _goals[index];
      final newAmt = current.currentAmount + amount;
      _goals[index] = current.copyWith(
        currentAmount: newAmt,
        isCompleted: newAmt >= current.targetAmount,
      );
      notifyListeners();
      await _saveGoalsToStorage();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
    await _saveGoalsToStorage();
  }

  // --- Backup & Restore ---
  String exportBackupJson() {
    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'currency': _currencySymbol,
      'budget': _budget.toJson(),
      'goals': _goals.map((g) => g.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<bool> restoreBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      if (data.containsKey('transactions')) {
        final List<dynamic> txList = data['transactions'];
        _transactions = txList.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }

      if (data.containsKey('budget')) {
        _budget = BudgetModel.fromJson(data['budget'] as Map<String, dynamic>);
      }

      if (data.containsKey('goals')) {
        final List<dynamic> goalList = data['goals'];
        _goals = goalList.map((item) => GoalModel.fromJson(item as Map<String, dynamic>)).toList();
      }

      if (data.containsKey('currency')) {
        _currencySymbol = data['currency'] as String? ?? '₹';
      }

      await _saveToStorage();
      await _saveBudgetsToStorage();
      await _saveGoalsToStorage();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    _transactions.clear();
    _goals.clear();
    _budget = BudgetModel();
    _lastSyncResult = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_budgetKey);
    await prefs.remove(_goalsKey);
  }

  // --- Persistence ---
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _transactions.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  Future<void> _saveBudgetsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_budgetKey, jsonEncode(_budget.toJson()));
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  Future<void> _saveGoalsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _goals.map((g) => g.toJson()).toList();
      await prefs.setString(_goalsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving goals: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _transactions = decoded.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      } else {
        // Initial setup: scan and load 4-month data
        final syncResult = await AndroidSmsService.scanLastFourMonthsInbox();
        _transactions = syncResult.parsedTransactions;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _lastSyncResult = syncResult;
        await _saveToStorage();
      }

      // Load Budget
      final budgetStr = prefs.getString(_budgetKey);
      if (budgetStr != null && budgetStr.isNotEmpty) {
        _budget = BudgetModel.fromJson(jsonDecode(budgetStr));
      }

      // Load Goals
      final goalsStr = prefs.getString(_goalsKey);
      if (goalsStr != null && goalsStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(goalsStr);
        _goals = list.map((item) => GoalModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        // Default sample relationship & savings goals
        _goals = [
          GoalModel(
            id: 'goal_anniversary',
            title: 'Anniversary Dinner & Gift 💖',
            targetAmount: 5000.0,
            currentAmount: 3200.0,
            emoji: '💖',
            targetDate: DateTime.now().add(const Duration(days: 45)),
          ),
          GoalModel(
            id: 'goal_vacation',
            title: 'Weekend Getaway Fund 🌴',
            targetAmount: 15000.0,
            currentAmount: 7500.0,
            emoji: '🌴',
            targetDate: DateTime.now().add(const Duration(days: 90)),
          ),
        ];
        await _saveGoalsToStorage();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
