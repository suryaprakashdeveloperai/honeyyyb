import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/live_notification_service.dart';
import '../services/voice_assistant_service.dart';
import '../theme/neo_brutalism_theme.dart';
import '../widgets/honey_ai_avatar_widget.dart';
import '../widgets/honeybee_logo.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import 'pdf_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationListenerEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final enabled = await LiveNotificationService.isListenerEnabled();
    if (mounted) {
      setState(() {
        _isNotificationListenerEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeoColors.honeyYellow,
        elevation: 0,
        title: Text(
          'APP SETTINGS ⚙️',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding Card
            NeoCard(
              backgroundColor: NeoColors.honeyYellow,
              child: Column(
                children: [
                  const HoneyBeeLogo(
                    size: 48,
                    backgroundColor: NeoColors.cardWhite,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Honeyyyb',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                  Text(
                    'CREATED BY SURYA PRAKASH',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NeoColors.cardWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeoColors.borderBlack, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Text('🕷️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '"No Matter the universe i Still choose her🕷️"',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live GPay & PhonePe Notification Detection & Voice AI Section
            Text(
              'LIVE NOTIFICATIONS & VOICE AI ⚡',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 10),

            NeoCard(
              backgroundColor: NeoColors.cardWhite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isNotificationListenerEnabled ? NeoColors.neonGreen : NeoColors.pastelPink,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NeoColors.borderBlack, width: 2),
                        ),
                        child: Icon(
                          _isNotificationListenerEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                          color: NeoColors.borderBlack,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Detect GPay & PhonePe',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.borderBlack,
                              ),
                            ),
                            Text(
                              _isNotificationListenerEnabled
                                  ? 'Active • Capturing payments in real-time'
                                  : 'Disabled • Tap below to grant access',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isNotificationListenerEnabled ? Colors.green[800] : NeoColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NeoButton(
                    isFullWidth: true,
                    color: _isNotificationListenerEnabled ? NeoColors.mintGreen : NeoColors.honeyYellow,
                    onPressed: () async {
                      await LiveNotificationService.openListenerSettings();
                      Future.delayed(const Duration(seconds: 2), () {
                        _checkNotificationPermission();
                      });
                    },
                    child: Text(
                      _isNotificationListenerEnabled ? '✓ NOTIFICATION ACCESS GRANTED' : 'ENABLE AUTO PAYMENT DETECTION ⚡',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.borderBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Honey AI Voice Speech Card
            NeoCard(
              backgroundColor: NeoColors.cardWhite,
              child: Row(
                children: [
                  const HoneyAiAvatarWidget(size: 40, showOnlineIndicator: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Honey AI Real Human Voice',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.borderBlack,
                          ),
                        ),
                        Text(
                          VoiceAssistantService.autoSpeakEnabled ? 'Voice is enabled' : 'Voice is muted',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: NeoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeoButton(
                    color: NeoColors.honeyYellow,
                    onPressed: () {
                      VoiceAssistantService.speak(
                        'Konnichiwa Surya! I am Honey AI, your personal companion. All your GPay and PhonePe payments are tracked safely on this device!',
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded, size: 16, color: NeoColors.borderBlack),
                        const SizedBox(width: 4),
                        Text(
                          'TEST',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Currency Switcher
            Text(
              'CURRENCY SYMBOL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['₹', '\$', '€', '£', '¥'].map((symbol) {
                final isSelected = provider.currencySymbol == symbol;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: NeoButton(
                      color: isSelected ? NeoColors.neonTeal : NeoColors.cardWhite,
                      onPressed: () => provider.setCurrencySymbol(symbol),
                      child: Text(
                        symbol,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Data Management
            Text(
              'DATA & SMS SYNC',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: NeoColors.borderBlack,
              ),
            ),
            const SizedBox(height: 10),

            NeoButton(
              isFullWidth: true,
              color: NeoColors.mintGreen,
              onPressed: provider.isSyncingSms
                  ? null
                  : () async {
                      final result = await provider.syncLastFourMonthsSms();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isSuccess
                                ? '🎉 ${result.newTransactionsAdded} new payments synced from last 4 months!'
                                : result.statusMessage,
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: result.isSuccess ? Colors.green[800] : NeoColors.spiderRed,
                        ),
                      );
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sync_rounded, color: NeoColors.borderBlack),
                  const SizedBox(width: 8),
                  Text(
                    provider.isSyncingSms ? 'SYNCING 4-MONTH INBOX...' : 'SYNC LAST 4 MONTHS SMS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            NeoButton(
              isFullWidth: true,
              color: NeoColors.honeyYellow,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PdfImportScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: NeoColors.borderBlack),
                  const SizedBox(width: 8),
                  Text(
                    'UPLOAD PDF STATEMENT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.borderBlack,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Backup & Restore JSON Buttons
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    color: NeoColors.cardWhite,
                    onPressed: () {
                      final jsonStr = provider.exportBackupJson();
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Backup JSON data copied to clipboard!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.backup_rounded, size: 16, color: NeoColors.borderBlack),
                        const SizedBox(width: 4),
                        Text(
                          'BACKUP JSON',
                          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeoButton(
                    color: NeoColors.cardWhite,
                    onPressed: () {
                      final controller = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: NeoColors.honeyYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: NeoColors.borderBlack, width: 3),
                          ),
                          title: Text(
                            'RESTORE FROM BACKUP',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          content: TextField(
                            controller: controller,
                            maxLines: 4,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            decoration: InputDecoration(
                              hintText: 'Paste backup JSON here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: NeoColors.borderBlack, width: 2),
                              ),
                            ),
                          ),
                          actions: [
                            NeoButton(
                              color: NeoColors.cardWhite,
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
                            ),
                            NeoButton(
                              color: NeoColors.borderBlack,
                              onPressed: () async {
                                final text = controller.text.trim();
                                if (text.isNotEmpty) {
                                  final success = await provider.restoreBackupJson(text);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? '🎉 Data restored successfully!' : 'Invalid backup JSON.'),
                                      backgroundColor: success ? Colors.green : NeoColors.spiderRed,
                                    ),
                                  );
                                }
                              },
                              child: Text('RESTORE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: NeoColors.cardWhite)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restore_page_rounded, size: 16, color: NeoColors.borderBlack),
                        const SizedBox(width: 4),
                        Text(
                          'RESTORE JSON',
                          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            NeoButton(
              isFullWidth: true,
              color: NeoColors.spiderRed,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: NeoColors.creamBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: NeoColors.borderBlack, width: 3),
                    ),
                    title: Text(
                      'CLEAR ALL DATA?',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
                    ),
                    content: Text(
                      'This will delete all stored transactions and reset the application.',
                      style: GoogleFonts.plusJakartaSans(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'CLEAR DATA',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900,
                            color: NeoColors.spiderRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await provider.clearAllData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data cleared successfully.'),
                      backgroundColor: NeoColors.spiderRed,
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'CLEAR ALL APPLICATION DATA',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
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
