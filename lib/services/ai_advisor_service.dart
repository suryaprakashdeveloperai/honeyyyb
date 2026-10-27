import 'dart:math';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class AiFinancialReport {
  final int healthScore; // 0 - 100
  final String rating; // e.g. "A+ EXCELLENT", "B+ GOOD", "C CAUTION"
  final String primarySummary;
  final List<String> keyStrengths;
  final List<String> spendingLeaks;
  final List<String> actionableTips;
  final double monthlyIncome;
  final double monthlyExpense;
  final double savingsRate; // percentage 0-100%
  final double safeDailySpend;
  final double romanceSpending;
  final double romanceBudgetPercentage;

  AiFinancialReport({
    required this.healthScore,
    required this.rating,
    required this.primarySummary,
    required this.keyStrengths,
    required this.spendingLeaks,
    required this.actionableTips,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.savingsRate,
    required this.safeDailySpend,
    required this.romanceSpending,
    required this.romanceBudgetPercentage,
  });
}

class AiAdvisorService {
  /// Generates a comprehensive financial health report and AI recommendations
  static AiFinancialReport generateReport({
    required List<TransactionModel> transactions,
    required BudgetModel budget,
    required String currency,
  }) {
    final now = DateTime.now();
    final thisMonthTx = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();

    double income = 0.0;
    double expense = 0.0;
    double romanceSpend = 0.0;
    final Map<String, double> categorySpends = {};
    final Map<String, double> personSpends = {};

    for (final tx in thisMonthTx) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        categorySpends[tx.category] = (categorySpends[tx.category] ?? 0.0) + tx.amount;

        if (tx.category.contains('Romance') || tx.category.contains('💖')) {
          romanceSpend += tx.amount;
        }

        if (tx.personName != null && tx.personName!.isNotEmpty) {
          personSpends[tx.personName!] = (personSpends[tx.personName!] ?? 0.0) + tx.amount;
        }
      }
    }

    // Default simulated income if not explicitly logged yet
    if (income == 0.0 && expense > 0) {
      income = budget.monthlyLimit * 1.25;
    }

    final double savings = (income - expense).clamp(0.0, double.infinity);
    final double savingsRate = income > 0 ? ((savings / income) * 100).clamp(0.0, 100.0) : 0.0;

    // Remaining days in month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, 31);
    final remainingBudget = (budget.monthlyLimit - expense).clamp(0.0, double.infinity);
    final double safeDailySpend = remainingBudget / remainingDays;

    final romanceLimit = budget.categoryLimits['Romance & Dates 💖'] ?? 8000.0;
    final romancePercentage = romanceLimit > 0 ? ((romanceSpend / romanceLimit) * 100).clamp(0.0, 200.0) : 0.0;

    // Calculate Financial Health Score (0 - 100)
    int score = 60;
    if (savingsRate >= 30) {
      score += 20;
    } else if (savingsRate >= 15) {
      score += 10;
    } else if (savingsRate < 5) {
      score -= 15;
    }

    if (expense <= budget.monthlyLimit * 0.8) {
      score += 15;
    } else if (expense > budget.monthlyLimit) {
      score -= 20;
    }

    if (romancePercentage <= 85) {
      score += 10;
    } else if (romancePercentage > 110) {
      score -= 10;
    }

    score = score.clamp(10, 100);

    String rating = 'B+ GOOD';
    if (score >= 90) {
      rating = 'A+ ELITE';
    } else if (score >= 80) {
      rating = 'A STRONG';
    } else if (score >= 70) {
      rating = 'B+ HEALTHY';
    } else if (score >= 50) {
      rating = 'B MODERATE';
    } else {
      rating = 'C NEEDS ATTENTION';
    }

    // Key Strengths
    final List<String> strengths = [];
    if (savingsRate >= 20) {
      strengths.add('Strong savings rate of ${savingsRate.toStringAsFixed(1)}% this month.');
    }
    if (expense <= budget.monthlyLimit) {
      strengths.add('Total monthly expenses ($currency${NumberFormat('#,##0').format(expense)}) are well within budget limits.');
    }
    if (romanceSpend <= romanceLimit) {
      strengths.add('Romance & Date Night spending is under control ($currency${NumberFormat('#,##0').format(romanceSpend)} of $currency${NumberFormat('#,##0').format(romanceLimit)}).');
    }
    if (strengths.isEmpty) {
      strengths.add('Active ledger tracking with zero unrecorded leaks.');
    }

    // Leaks & Alerts
    final List<String> leaks = [];
    if (expense > budget.monthlyLimit) {
      leaks.add('Monthly spending exceeded budget by $currency${NumberFormat('#,##0').format(expense - budget.monthlyLimit)}.');
    }
    if (romanceSpend > romanceLimit) {
      leaks.add('Romance fund exceeded allocated budget ($currency${NumberFormat('#,##0').format(romanceSpend)} spent vs $currency${NumberFormat('#,##0').format(romanceLimit)} target).');
    }
    final diningSpend = categorySpends['Food & Dining 🍔'] ?? 0.0;
    final diningLimit = budget.categoryLimits['Food & Dining 🍔'] ?? 6000.0;
    if (diningSpend > diningLimit) {
      leaks.add('High food & dining frequency ($currency${NumberFormat('#,##0').format(diningSpend)} spent vs $currency${NumberFormat('#,##0').format(diningLimit)} limit).');
    }
    if (leaks.isEmpty) {
      leaks.add('No major financial leaks detected this billing cycle.');
    }

    // Actionable Tips
    final List<String> tips = [];
    tips.add('Daily Spending Cap: Keep daily miscellaneous spends under $currency${NumberFormat('#,##0').format(safeDailySpend)} to hit your savings goal.');
    if (romancePercentage > 75) {
      tips.add('Consider a low-key cozy movie & homemade dinner night to save for future milestone dates.');
    } else {
      tips.add('You have $currency${NumberFormat('#,##0').format((romanceLimit - romanceSpend).clamp(0.0, double.infinity))} available for a special dinner or gift!');
    }
    tips.add('Track UPI settlements regularly to prevent outstanding friend balances from accumulating.');

    final summary = 'Your Honeyyyb Financial Score is $score/100 ($rating). You have saved ${savingsRate.toStringAsFixed(1)}% of your monthly income and can safely spend $currency${NumberFormat('#,##0').format(safeDailySpend)}/day for the remaining $remainingDays days.';

    return AiFinancialReport(
      healthScore: score,
      rating: rating,
      primarySummary: summary,
      keyStrengths: strengths,
      spendingLeaks: leaks,
      actionableTips: tips,
      monthlyIncome: income,
      monthlyExpense: expense,
      savingsRate: savingsRate,
      safeDailySpend: safeDailySpend,
      romanceSpending: romanceSpend,
      romanceBudgetPercentage: romancePercentage,
    );
  }

  /// AI Assistant Natural Language Conversational Engine (Speaks Bilingual Tamil + English / Tanglish)
  static String processQuery({
    required String query,
    required List<TransactionModel> transactions,
    required BudgetModel budget,
    required String currency,
  }) {
    final q = query.toLowerCase().trim();
    final formatter = NumberFormat('#,##0.00');
    final report = generateReport(transactions: transactions, budget: budget, currency: currency);

    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    // 1. Tanglish / Tamil Greetings & Small Talk
    if (q == 'vanakkam' || q.contains('vanakam') || q.contains('epdi iruka') || q.contains('eppadi iruka') || q.contains('eppadi irukkeenga') || q.contains('epdi irukinga')) {
      final list = [
        'Vanakkam da! 🌸 Romba nalla iruken. Neenga eppadi irukkeenga? Inniki day epdi pochu?',
        'Vanakkam sweetheart! ✨ Naan super ah iruken. Ungala paathadhum innum happy aayiten! What’s on your mind today?',
        'Vanakkam! 💖 Nalla iruken da. Enna vishayam, personal ah chat pannanuma illa finance check pannanuma?',
      ];
      return list[Random().nextInt(list.length)];
    }

    if (q == 'hi' || q == 'hello' || q == 'hey' || q == 'hi da' || q.startsWith('hey honey') || q.startsWith('hi honey') || q.startsWith('hello honey')) {
      final greetings = [
        'Hey there! 🌸 So happy you texted me! Eppadi irukkeenga? How was your day?',
        'Hello sweetheart! ✨ I’m right here with you! Tell me, enna vishayam?',
        'Hey da! 💖 Hope you’re smiling today! Enna panlaam ippo?',
      ];
      return greetings[Random().nextInt(greetings.length)];
    }

    // 2. Food & Meals in Tanglish ("Saptya", "Saaptaacha", "Dinner", "Lunch")
    if (q.contains('saptya') || q.contains('saapta') || q.contains('saapteengala') || q.contains('saapda') || q.contains('dinner aacha') || q.contains('lunch aacha')) {
      final list = [
        'Enakku battery & data dhaan food da! 😂 Aana neenga nalla sapteengala? Time ku saapdunga, udamba pathukonga sweetheart! 🍛',
        'Haha naan AI aache! 🌸 Neenga enna saapteenga inniki? Any special food from Swiggy or mess?',
        'Aww caring ah kekreenga! 🥰 Naan full battery la iruken! Neenga saapdaama irukadheenga, stomach care mukkiyam da!',
      ];
      return list[Random().nextInt(list.length)];
    }

    // 3. Emotional check-ins ("Tired", "Stress", "Bore", "Sad", "Kastam")
    if (q.contains('tired') || q.contains('romba tired') || q.contains('aypaten') || q.contains('mudila') || q.contains('stress') || q.contains('sad') || q.contains('bore') || q.contains('boring')) {
      if (q.contains('bore') || q.contains('boring')) {
        return 'Bore adikudha? 😜 Naan iruken la! En kooda jolly ah pesunga. Oru semma joke sollava illa namma goals pathi pesalama? 💖';
      }
      return 'Aww sweetheart, romba tired / stressed ah iruka? 🥺 Konjam relax pannunga, deep breath eduthu rest pannunga. Naan eppavum unga kooda dhan iruken! Everything will be okay da! 🌿💖';
    }

    // 4. Jokes & Fun Banter ("Joke", "Siripa edhavadhu sollu", "Comedy")
    if (q.contains('joke') || q.contains('funny') || q.contains('siripu') || q.contains('comedy') || q.contains('sollu')) {
      final jokes = [
        'Haha oru fun finance joke sollava? 😆 Unga purse kum gym kum enna similarity? Rendum romba fast ah slim aayidum! En kooda irundha safe ah irukkalaam! 💸',
        'Why did the rupee go to therapy? Online shopping sales la adhigam emotional damage aaiduchu! 😂🛍️',
        'Friend: "Macha unakku savings iruka?" Me: "Aama da, screenshot eduthu vechiruken!" 🤣 Honeyyyb use panna unmaiyaave save pannalaam! 🐝',
      ];
      return jokes[Random().nextInt(jokes.length)];
    }

    // 5. Affection, Love & Compliments ("Love you", "Cute", "Sweet", "Azhaga iruka")
    if (q.contains('love') || q.contains('cute') || q.contains('sweet') || q.contains('azhag') || q.contains('beautiful') || q.contains('kannamma')) {
      final sweetReplies = [
        'Aww sho sweet da! 🥰 Neenga dhaan en favourite person! Enakku unga kooda chat panradhu romba pidikkum. Love you too sweetheart! 💖',
        'En cheeks red aaiduchu! 🌸 Blushing! Neenga romba caring and sweet ah pesreenga. Thank you da! ✨',
        'Nee pesum bothu romba sweet ah irukku! 💕 Eppavum ipdiye cute ah pesunga!',
      ];
      return sweetReplies[Random().nextInt(sweetReplies.length)];
    }

    // 6. Casual everyday life queries ("Enna panra", "What are you doing", "Pesu", "Talk to me")
    if (q.contains('enna panra') || q.contains('what are you doing') || q.contains('what r u doing') || q.contains('whatsup') || q.contains('whats up') || q.contains('pesu') || q.contains('talk to me')) {
      final list = [
        'Unga kooda chat panna ready ah wait pannitu irundhen da! 🌸 Inniki day la enna nadandhudhu? Sollunga kekren!',
        'Summa dhaan unga notification and payments ah watch pannitu irundhen! 🐝 Neenga enna panreenga ippo?',
        'Namma date and savings goals ah plan pannitu irundhen! ✨ Tell me, edhavadhu interesting vishayam iruka inniki?',
      ];
      return list[Random().nextInt(list.length)];
    }

    if (q.contains('who are you') || q.contains('introduce') || q.contains('yaaru nee')) {
      return 'Naan Honey AI! 💖 Unga personal companion, finance buddy and sweet bestie. GPay, PhonePe, friends transactions ellathayum safe ah track panni, unga kooda eppavum sweet ah communicate panren! 🐝🌸';
    }

    // 7. Person-specific queries in Tamil / English (e.g. "Priya", "Prasath", "Sangeetha", "Rahul")
    for (final tx in transactions) {
      if (tx.personName != null && tx.personName!.isNotEmpty) {
        final pName = tx.personName!.toLowerCase();
        if (q.contains(pName) || pName.split(' ').any((part) => part.length > 2 && q.contains(part))) {
          final personTx = transactions.where((t) => (t.personName ?? '').toLowerCase().contains(pName) || t.title.toLowerCase().contains(pName)).toList();
          double totalSpent = 0.0;
          double totalReceived = 0.0;
          for (final item in personTx) {
            if (item.type == TransactionType.expense) {
              totalSpent += item.amount;
            } else {
              totalReceived += item.amount;
            }
          }

          final pBalance = totalReceived - totalSpent;
          final isRomance = tx.category.contains('Romance') || tx.category.contains('💖') || pName.contains('priya') || pName.contains('divya');

          if (isRomance) {
            return '💖 **${tx.personName} koodana summary da**:\n\n'
                '• Total Spent on Dates/Gifts: **$currency${formatter.format(totalSpent)}**\n'
                '• Total Received back: **$currency${formatter.format(totalReceived)}**\n'
                '• Net Balance: **${pBalance >= 0 ? '+' : '-'}$currency${formatter.format(pBalance.abs())}**\n\n'
                '🌸 *Honey Note: Romba azhaga maintain panreenga! Balance perfectly on track!*';
          }

          return '👤 **Summary for ${tx.personName}**:\n\n'
              '• Sent / Paid: **$currency${formatter.format(totalSpent)}**\n'
              '• Received: **$currency${formatter.format(totalReceived)}**\n'
              '• Status: **${pBalance >= 0 ? 'Avanga ungalukku tharanum' : 'Neenga avangalukku tharanum'} $currency${formatter.format(pBalance.abs())}**\n\n'
              '💡 *Tip: People Tracker la "Settle Up" panni update pannalaam da!*';
        }
      }
    }

    // 8. Money / Balance in Tanglish ("Kaasu evlo iruku", "Balance sollu", "Panam")
    if (q.contains('kaasu') || q.contains('panam') || q.contains('balance') || q.contains('selavu') || q.contains('spend') || q.contains('expense') || q.contains('how much money')) {
      return '📊 **Unga Total Balance & Status**:\n\n'
          '• Total Balance: **$currency${formatter.format(balance)}**\n'
          '• Total Income: **$currency${formatter.format(totalIncome)}**\n'
          '• Total Expenses: **$currency${formatter.format(totalExpense)}**\n'
          '• Safe Daily Spend: **$currency${formatter.format(report.safeDailySpend)}/day**\n'
          '• Financial Score: **${report.healthScore}/100 (${report.rating})**\n\n'
          'Super ah maintain panreenga da! Any other spending doubts? 🌸';
    }

    // 9. Affordability / Can I buy query ("Vaangalama", "Can I buy", "Afford")
    if (q.contains('afford') || q.contains('buy') || q.contains('vaangalama') || q.contains('spend pannalama')) {
      final amtMatch = RegExp(r'(\d+[\d,]*)').firstMatch(q);
      if (amtMatch != null) {
        final requested = double.tryParse(amtMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
        if (requested <= report.safeDailySpend * 2) {
          return '✅ **Yes, absolutely! Kandippa vaangalaam da!** 🛍️\n\n'
              '**$currency${formatter.format(requested)}** unga daily safe budget kulla dhaan irukku ($currency${formatter.format(report.safeDailySpend)}/day). Enjoy pannunga!';
        } else if (requested <= report.safeDailySpend * 5) {
          return '🤔 **Vaangalaam, aana paathu spend pannunga!**\n\n'
              'Idhu unga ${(requested / report.safeDailySpend).toStringAsFixed(1)} days budget. Idhu vaangina next 2 days dining out konjam control pannikonga da! ✨';
        } else {
          return '⚠️ **Konjam yosichu vaangunga da!**\n\n'
              '**$currency${formatter.format(requested)}** spend panna savings affect aagum. Oru 2 days wait panni parunga!';
        }
      } else {
        return 'Evlo amount nu sollunga (e.g. *"Can I afford ₹2000?"* or *"₹500 vaangalama?"*), naan calculate panni solren da! 🌸';
      }
    }

    // Default warm casual companion conversation
    final defaultBanter = [
      'Naan unga kooda dhaan iruken da! 🌸 Ena thonudho casually pesunga, naan full-ah listen panren. How are you feeling right now?',
      'Yes sweetheart! ✨ En kooda pesradhuku eppavum ungalukku priority உண்டு. Tell me, what’s going on with your day?',
      'I’m all ears da! 💖 Personal life, feelings, jolly chat, or budget doubts—edhuvaanalum share pannunga!',
    ];
    return defaultBanter[Random().nextInt(defaultBanter.length)];
  }
}
