import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/ai_advisor_service.dart';
import '../services/voice_assistant_service.dart';
import '../theme/neo_brutalism_theme.dart';
import 'honey_ai_avatar_widget.dart';
import 'neo_button.dart';

class ChatMessageItem {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessageItem({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class SnapchatAiChatModal extends StatefulWidget {
  final String currentScreenName;

  const SnapchatAiChatModal({
    super.key,
    this.currentScreenName = 'Dashboard',
  });

  static Future<void> show(BuildContext context, {String currentScreenName = 'Dashboard'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SnapchatAiChatModal(currentScreenName: currentScreenName),
    );
  }

  @override
  State<SnapchatAiChatModal> createState() => _SnapchatAiChatModalState();
}

class _SnapchatAiChatModalState extends State<SnapchatAiChatModal> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageItem> _messages = [];
  bool _isAiTyping = false;
  bool _voiceAutoSpeak = true;

  @override
  void initState() {
    super.initState();
    _voiceAutoSpeak = VoiceAssistantService.autoSpeakEnabled;
    _initWelcomeMessage();
  }

  @override
  void dispose() {
    VoiceAssistantService.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initWelcomeMessage() {
    String contextTip = '';
    if (widget.currentScreenName == 'People Tracker') {
      contextTip = ' People Tracker paakureengala? Want to check friend spends or settle balances?';
    } else if (widget.currentScreenName == 'Analytics' || widget.currentScreenName == 'History') {
      contextTip = ' Monthly analytics and savings status paakalaama?';
    } else {
      contextTip = ' En kooda casually pesalaam illa budget pathi check pannalaam!';
    }

    final welcomeText = 'Vanakkam sweetheart! 🌸 I\'m **Honey AI**, your personal companion & finance bestie! 🐝$contextTip';

    _messages.add(
      ChatMessageItem(
        text: welcomeText,
        isUser: false,
        time: DateTime.now(),
      ),
    );

    if (_voiceAutoSpeak) {
      Future.delayed(const Duration(milliseconds: 300), () {
        VoiceAssistantService.speak('Vanakkam sweetheart! I am Honey AI. En kooda personal ah pesalaam illa money pathi check pannalaam!');
      });
    }
  }

  void _sendMessage(String queryText) {
    final text = queryText.trim();
    if (text.isEmpty) return;

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    setState(() {
      _messages.add(
        ChatMessageItem(
          text: text,
          isUser: true,
          time: DateTime.now(),
        ),
      );
      _isAiTyping = true;
    });

    _inputController.clear();
    _scrollToBottom();

    // Natural conversation pause
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final response = AiAdvisorService.processQuery(
        query: text,
        transactions: provider.transactions,
        budget: provider.budget,
        currency: provider.currencySymbol,
      );

      setState(() {
        _isAiTyping = false;
        _messages.add(
          ChatMessageItem(
            text: response,
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();

      // Speak response out loud like a real human!
      if (_voiceAutoSpeak) {
        VoiceAssistantService.speak(response);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: NeoColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: NeoColors.borderBlack, width: 3.5),
          left: BorderSide(color: NeoColors.borderBlack, width: 3.5),
          right: BorderSide(color: NeoColors.borderBlack, width: 3.5),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: NeoColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: NeoColors.borderBlack, width: 2.5),
              ),
            ),
            child: Row(
              children: [
                const HoneyAiAvatarWidget(size: 44, showOnlineIndicator: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Honey AI',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.borderBlack,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🌸', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: NeoColors.honeyYellow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NeoColors.borderBlack, width: 1),
                            ),
                            child: Text(
                              'MY AI',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Personal Voice & Finance Co-Pilot',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NeoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Voice Auto-Speak Toggle Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _voiceAutoSpeak = !_voiceAutoSpeak;
                      VoiceAssistantService.autoSpeakEnabled = _voiceAutoSpeak;
                      if (!_voiceAutoSpeak) {
                        VoiceAssistantService.stop();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _voiceAutoSpeak ? NeoColors.mintGreen : NeoColors.creamBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _voiceAutoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          size: 16,
                          color: NeoColors.borderBlack,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _voiceAutoSpeak ? 'VOICE ON' : 'MUTED',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: NeoColors.borderBlack, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages Thread
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingBubble();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Quick Prompt Chips
          Container(
            height: 42,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildQuickChip('🌸 Epdi iruka da?', 'Vanakkam epdi iruka?'),
                _buildQuickChip('🍛 Saptya?', 'Saptya da?'),
                _buildQuickChip('😂 Oru joke sollu', 'Oru joke sollu'),
                _buildQuickChip('💰 Kaasu evlo iruku?', 'Kaasu evlo iruku?'),
                _buildQuickChip('💖 Sweet ah pesu', 'Sweet ah pesu da'),
                _buildQuickChip('🥂 Priya summary', 'Priya koodana summary sollu'),
                _buildQuickChip('🛍️ Vaangalama?', 'Can I afford ₹2000?'),
                _buildQuickChip('💬 Bore adikudhu', 'Bore adikudhu en kooda pesu'),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 10 + bottomInset),
            decoration: const BoxDecoration(
              color: NeoColors.cardWhite,
              border: Border(
                top: BorderSide(color: NeoColors.borderBlack, width: 2.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: NeoColors.creamBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.borderBlack,
                      ),
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Talk to Honey AI (eg: Can I afford dinner?)...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: NeoColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 44,
                  child: NeoButton(
                    color: NeoColors.honeyYellow,
                    padding: EdgeInsets.zero,
                    onPressed: () => _sendMessage(_inputController.text),
                    child: const Icon(Icons.send_rounded, color: NeoColors.borderBlack, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: NeoColors.cardWhite,
        side: const BorderSide(color: NeoColors.borderBlack, width: 1.5),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: NeoColors.borderBlack,
          ),
        ),
        onPressed: () => _sendMessage(query),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: NeoColors.pastelPink,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(2),
            ),
            border: Border.all(color: NeoColors.borderBlack, width: 2),
            boxShadow: [
              BoxShadow(
                color: NeoColors.borderBlack.withValues(alpha: 0.15),
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.borderBlack,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HoneyAiAvatarWidget(size: 32, showOnlineIndicator: false),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: NeoColors.cardWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: NeoColors.borderBlack, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: NeoColors.borderBlack.withValues(alpha: 0.15),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.borderBlack,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => VoiceAssistantService.speak(msg.text),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: NeoColors.honeyYellow.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NeoColors.borderBlack, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 12, color: NeoColors.borderBlack),
                                const SizedBox(width: 3),
                                Text(
                                  'Speak',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: NeoColors.borderBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        child: Row(
          children: [
            const HoneyAiAvatarWidget(size: 32, showOnlineIndicator: false),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: NeoColors.honeyYellow.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.borderBlack, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Honey AI is speaking & thinking 🌸',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.borderBlack),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
