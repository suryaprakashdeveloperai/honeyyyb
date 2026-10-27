import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/people_tracker_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transactions_screen.dart';
import 'services/live_notification_service.dart';
import 'services/voice_assistant_service.dart';
import 'theme/neo_brutalism_theme.dart';
import 'widgets/floating_honey_ai_bubble.dart';
import 'widgets/honeybee_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HoneyyybApp());
}

class HoneyyybApp extends StatelessWidget {
  const HoneyyybApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider(),
      child: MaterialApp(
        title: 'Honeyyyb',
        debugShowCheckedModeBanner: false,
        theme: NeoTheme.themeData,
        home: const MainNavigationScaffold(),
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  final List<String> _pageNames = const [
    'Dashboard',
    'People Tracker',
    'Analytics',
    'History',
    'Settings',
  ];

  final List<Widget> _pages = const [
    DashboardScreen(),
    PeopleTrackerScreen(),
    AnalyticsScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start real-time GPay / PhonePe notification detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveNotificationDetector();
    });
  }

  void _initLiveNotificationDetector() {
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    LiveNotificationService.startRealtimeListener(
      onTransactionAutoDetected: (tx) {
        financeProvider.addTransaction(tx);
        // Sweet voice feedback from Honey AI
        if (VoiceAssistantService.autoSpeakEnabled) {
          final voiceText = tx.type.toString().contains('expense')
              ? 'Recorded payment of ₹${tx.amount.toStringAsFixed(0)} to ${tx.personName ?? "merchant"}.'
              : 'Yay! Received ₹${tx.amount.toStringAsFixed(0)} from ${tx.personName ?? "account"}.';
          VoiceAssistantService.speak(voiceText);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: NeoColors.cardWhite,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: NeoColors.borderBlack, width: 2.5),
              ),
              content: Row(
                children: [
                  const Text('⚡ ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      'Auto-detected: ₹${tx.amount.toStringAsFixed(0)} (${tx.title})',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        color: NeoColors.borderBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    LiveNotificationService.stopListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _pageNames[_currentIndex];

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_tx_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
            backgroundColor: NeoColors.honeyYellow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: NeoColors.borderBlack, width: 3),
            ),
            child: const Icon(Icons.add_rounded, size: 32, color: NeoColors.borderBlack),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: NeoColors.cardWhite,
              border: Border(
                top: BorderSide(color: NeoColors.borderBlack, width: 3),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
              type: BottomNavigationBarType.fixed,
              backgroundColor: NeoColors.cardWhite,
              selectedItemColor: NeoColors.borderBlack,
              unselectedItemColor: Colors.black45,
              selectedLabelStyle: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
              unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const SizedBox(
                    width: 22,
                    height: 22,
                    child: HoneyBeeLogo(size: 22, showBadgeContainer: false),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: NeoColors.honeyYellow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: NeoColors.borderBlack, width: 1.5),
                    ),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: HoneyBeeLogo(size: 22, showBadgeContainer: false),
                    ),
                  ),
                  label: 'HOME',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.people_alt_outlined),
                  activeIcon: const Icon(Icons.people_alt_rounded, color: NeoColors.electricPurple),
                  label: 'PEOPLE',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bar_chart_rounded),
                  activeIcon: const Icon(Icons.bar_chart_rounded, color: NeoColors.neonTeal),
                  label: 'ANALYTICS',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  activeIcon: const Icon(Icons.receipt_long_rounded, color: NeoColors.spiderRed),
                  label: 'HISTORY',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings_rounded, color: NeoColors.honeyYellow),
                  label: 'SETTINGS',
                ),
              ],
            ),
          ),
        ),

        // Screen-Wide Free-Floating Draggable Honey AI Bubble
        FloatingHoneyAiBubble(
          currentScreenName: currentScreen,
        ),
      ],
    );
  }
}
