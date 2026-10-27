import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/ai_advisor_service.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/honey_ai_avatar_widget.dart';
import '../widgets/neo_badge.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _AiChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AiChatMessage> _messages = [];
  bool _isThinking = false;

  final List<String> _quickPrompts = [
    'How much did I spend on Priya? 💖',
    'Can I afford a ₹2,500 date night? 🍷',
    'Where is most of my money going? 📊',
    'How can I save ₹10,000 this month? 💰',
    'What is my safe daily spending limit? ⚡',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _AiChatMessage(
        text: 'Konnichiwa Surya! 🌸 I\'m **Honey AI**, your personal financial co-pilot & romance budget advisor. Ask me anything about your spending, dates with Priya, savings goals, or date affordability!',
        isUser: false,
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final userMsg = text.trim();
    _queryController.clear();

    setState(() {
      _messages.add(_AiChatMessage(text: userMsg, isUser: true));
      _isThinking = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final reply = AiAdvisorService.processQuery(
        query: userMsg,
        transactions: provider.transactions,
        budget: provider.budget,
        currency: provider.currencySymbol,
      );

      setState(() {
        _isThinking = false;
        _messages.add(_AiChatMessage(text: reply, isUser: false));
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = provider.currencySymbol;
    final formatter = NumberFormat('#,##0');

    final report = AiAdvisorService.generateReport(
      transactions: provider.transactions,
      budget: provider.budget,
      currency: currency,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Row(
          children: [
            const HoneyAiAvatarWidget(size: 32, showBorder: false),
            const SizedBox(width: 8),
            Text(
              'HONEY AI CO-PILOT 🌸',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: NeoColors.borderBlack, height: 3.0),
        ),
      ),
      body: Column(
        children: [
          // Collapsible Financial Health Header
          Container(
            color: NeoColors.cardWhite,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: NeoCard(
              backgroundColor: NeoColors.honeyYellow,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: NeoColors.cardWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: NeoColors.borderBlack, width: 2),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: NeoColors.borderBlack, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HEALTH SCORE',
                            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      NeoBadge(
                        label: report.rating,
                        color: report.healthScore >= 75 ? NeoColors.mintGreen : NeoColors.pastelPink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${report.healthScore}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '/100',
                        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Safe Daily Spend: $currency${formatter.format(report.safeDailySpend)}/day',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Savings Rate: ${report.savingsRate.toStringAsFixed(1)}% of income',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Quick Prompt Chips
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _sendMessage(prompt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeoColors.cardWhite,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: NeoColors.borderBlack, offset: Offset(2, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          prompt,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, thickness: 2, color: NeoColors.borderBlack),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isThinking) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: NeoColors.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NeoColors.borderBlack, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.borderBlack),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BeeAI is analyzing your ledger...',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    child: NeoCard(
                      backgroundColor: msg.isUser ? NeoColors.honeyYellow : NeoColors.cardWhite,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                msg.isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                                size: 14,
                                color: msg.isUser ? NeoColors.borderBlack : NeoColors.spiderRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                msg.isUser ? 'YOU' : 'HONEY AI 🌸',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            msg.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: NeoColors.honeyYellow,
              border: Border(top: BorderSide(color: NeoColors.borderBlack, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Ask BeeAI anything (e.g. "Priya spends")...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black45),
                      filled: true,
                      fillColor: NeoColors.cardWhite,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                NeoButton(
                  color: NeoColors.borderBlack,
                  padding: const EdgeInsets.all(12),
                  onPressed: () => _sendMessage(_queryController.text),
                  child: const Icon(Icons.send_rounded, color: NeoColors.cardWhite, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
