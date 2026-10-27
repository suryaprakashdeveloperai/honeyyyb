import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialPersonName;
  final TransactionType? initialType;
  final String? initialCategory;

  const AddTransactionScreen({
    super.key,
    this.initialPersonName,
    this.initialType,
    this.initialCategory,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _personController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.expense;
    _selectedCategory = widget.initialCategory ?? 'Food & Dining 🍔';
    if (widget.initialPersonName != null && widget.initialPersonName!.isNotEmpty) {
      _personController.text = widget.initialPersonName!;
      _titleController.text = 'Payment with ${widget.initialPersonName}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _personController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectPerson(String name) {
    setState(() {
      _personController.text = name;
      if (_titleController.text.isEmpty || _titleController.text.startsWith('Payment with')) {
        _titleController.text = 'Payment with $name';
      }
    });
  }

  void _submitForm() {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in title and amount!',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
          backgroundColor: NeoColors.spiderRed,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount!',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
          backgroundColor: NeoColors.spiderRed,
        ),
      );
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final person = _personController.text.trim().isNotEmpty ? _personController.text.trim() : null;

    final newTx = TransactionModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: amount,
      type: _type,
      category: _selectedCategory,
      date: _selectedDate,
      personName: person,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      source: 'manual_entry',
    );

    provider.addTransaction(newTx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final knownPeople = provider.knownPeople;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.borderBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADD TRANSACTION 💸',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: NeoColors.borderBlack,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: NeoColors.borderBlack, height: 3.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income / Expense Toggle
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      color: _type == TransactionType.expense ? NeoColors.spiderRed : NeoColors.cardWhite,
                      onPressed: () => setState(() => _type = TransactionType.expense),
                      child: Text(
                        'EXPENSE 🔴',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _type == TransactionType.expense ? Colors.white : NeoColors.borderBlack,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeoButton(
                      color: _type == TransactionType.income ? NeoColors.mintGreen : NeoColors.cardWhite,
                      onPressed: () => setState(() => _type = TransactionType.income),
                      child: Text(
                        'INCOME 🟢',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _type == TransactionType.income ? Colors.white : NeoColors.borderBlack,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Field
              NeoTextField(
                controller: _titleController,
                label: 'TITLE / ITEM NAME',
                hint: 'e.g. Lunch with Prasath JR / Swiggy / Jio Recharge',
                prefixIcon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: 16),

              // Amount Field
              NeoTextField(
                controller: _amountController,
                label: 'AMOUNT (${provider.currencySymbol})',
                hint: 'e.g. 500',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee_rounded,
              ),
              const SizedBox(height: 16),

              // Person Name Field with Autocomplete & Quick Chips
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeoTextField(
                    controller: _personController,
                    label: 'PERSON / MERCHANT NAME (OPTIONAL)',
                    hint: 'e.g. Prasath JR / SANGEETHA P / Divya T',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  if (knownPeople.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'QUICK CONTACT SELECTOR:',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black54,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: knownPeople.take(8).length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 6),
                        itemBuilder: (ctx, i) {
                          final pName = knownPeople[i];
                          final isCurrent = _personController.text.trim().toLowerCase() == pName.toLowerCase();
                          return ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: NeoColors.honeyYellow,
                              child: Text(
                                pName.isNotEmpty ? pName[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                            label: Text(
                              pName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? Colors.white : NeoColors.borderBlack,
                              ),
                            ),
                            backgroundColor: isCurrent ? NeoColors.borderBlack : NeoColors.cardWhite,
                            side: const BorderSide(color: NeoColors.borderBlack, width: 1.5),
                            onPressed: () => _selectPerson(pName),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text(
                'SELECT CATEGORY',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: NeoColors.borderBlack,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TransactionModel.defaultCategories.map((cat) {
                  final isSelected = _selectedCategory == cat.name;
                  return ChoiceChip(
                    label: Text(
                      cat.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.borderBlack,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: NeoColors.cardWhite,
                    side: const BorderSide(color: NeoColors.borderBlack, width: 2),
                    elevation: isSelected ? 3 : 0,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat.name);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date Picker
              NeoCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: NeoColors.neonTeal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: NeoColors.borderBlack),
                        const SizedBox(width: 8),
                        Text(
                          'DATE: ${DateFormat('dd MMM yyyy HH:mm').format(_selectedDate)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Text(
                        'CHANGE',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                          color: NeoColors.borderBlack,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Note Field
              NeoTextField(
                controller: _noteController,
                label: 'NOTES / MEMO',
                hint: 'e.g. UPI Ref: 615282315505 / Split bill / Dinner',
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Submit Button
              NeoButton(
                isFullWidth: true,
                color: NeoColors.honeyYellow,
                onPressed: _submitForm,
                child: Text(
                  'SAVE TRANSACTION 💾',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.borderBlack,
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
