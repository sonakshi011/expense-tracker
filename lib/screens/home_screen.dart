import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/db_helper.dart';
import '../models/expense.dart';
import '../services/notification_service.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/transaction_section.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/cash_in_screen.dart';
import '../screens/cash_out_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];
  int selectedIndex = 0;
  DateTime selectedMonth = DateTime.now();
  bool isChartView = true;
  String bookName = "My Book";
  String currency = "₹";
  Color themeColor = Colors.red;

  bool isLimitEnabled = false;
  double limitAmount = 0;
  String limitType = "daily";


  bool _wasAlreadyOverLimit = false;

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadSettings();
    loadCurrency();
    loadLimitSettings();
  }

  Future<void> loadLimitSettings() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          isLimitEnabled = doc['isLimitEnabled'] ?? false;
          limitAmount = (doc['limitAmount'] ?? 0).toDouble();
          limitType = doc['limitType'] ?? "daily";
        });
      }
    }
  }

  double calculatePeriodTotal() {
    final now = DateTime.now();

    return expenses
        .where((e) {
      if (e.type != "expense") return false;
      final date = DateTime.parse(e.date);

      if (limitType == "daily") {
        return date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
      }
      if (limitType == "weekly") {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return !date.isBefore(weekStartDay);
      }
      if (limitType == "monthly") {
        return date.month == now.month && date.year == now.year;
      }
      return false;
    })
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  void snapshotLimitStatus() {
    if (!isLimitEnabled || limitAmount <= 0) return;
    _wasAlreadyOverLimit = calculatePeriodTotal() >= limitAmount;
  }


  Future<void> checkLimitAfterCashOut() async {
    if (!isLimitEnabled || limitAmount <= 0) return;

    final total = calculatePeriodTotal();

    if (total >= limitAmount) {
      if (!_wasAlreadyOverLimit) {

        await NotificationService.showLimitReachedNotification(
          limitType: limitType,
          limitAmount: limitAmount,
          currency: currency,
        );
      } else {

        await NotificationService.showOverLimitCashOutNotifications(
          limitType: limitType,
          limitAmount: limitAmount,
          totalSpent: total,
          currency: currency,
        );
      }
    }
  }

  void loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currency = prefs.getString("currency") ?? "₹");
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bookName = prefs.getString("bookName") ?? "My Book";
      currency = prefs.getString("currency") ?? "₹";
      themeColor = Color(prefs.getInt("themeColor") ?? Colors.red.value);
    });
  }

  Future<void> loadExpenses() async {
    final data = await DbHelper.instance.getExpenses();
    setState(() => expenses = data);
  }

  double getTotalIncome() =>
      expenses.where((e) => e.type == "income").fold(0, (sum, e) => sum + e.amount);

  double getTotalExpense() =>
      expenses.where((e) => e.type == "expense").fold(0, (sum, e) => sum + e.amount);

  double getBalance() => getTotalIncome() - getTotalExpense();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.7)],
              ),
            ),
            child: Column(
              children: [
                Text(
                  bookName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildItem(getTotalIncome(), "Cash In"),
                    const Text("-", style: whiteSymbol),
                    buildItem(getTotalExpense(), "Cash Out"),
                    const Text("=", style: whiteSymbol),
                    buildItem(getBalance(), "Balance"),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                    });
                  },
                ),
                GestureDetector(
                  onTap: openMonthYearPicker,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "${getMonthName(selectedMonth.month)} ${selectedMonth.year}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: isChartView
                ? PieChartWidget(expenses: expenses, selectedMonth: selectedMonth)
                : TransactionSection(
              expenses: expenses,
              onRefresh: loadExpenses,
              selectedMonth: selectedMonth,
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: selectedIndex,
        isChartView: isChartView,
        onTap: (index) async {
          if (index == 0) {
            setState(() {
              isChartView = !isChartView;
              selectedIndex = 0;
            });
          } else if (index == 1) {
            final result = await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CashInScreen()));
            if (result == true) {
              await loadExpenses();
            }
          } else if (index == 2) {

            snapshotLimitStatus();
            final result = await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CashOutScreen()));
            if (result == true) {
              await loadExpenses();
              await loadLimitSettings();
              await checkLimitAfterCashOut();
            }
          } else if (index == 3) {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            await loadLimitSettings();
            loadCurrency();
            loadSettings();
          }
        },
      ),
    );
  }

  Widget buildItem(double value, String title) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  String getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Future<void> openMonthYearPicker() async {
    int tempYear = selectedMonth.year;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 300,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setModalState(() => tempYear--),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final pickedYear = await showDialog<int>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Select Year"),
                              content: SizedBox(
                                height: 200,
                                width: 200,
                                child: ListView.builder(
                                  itemCount: 50,
                                  itemBuilder: (context, index) {
                                    int year = 2000 + index;
                                    return ListTile(
                                      title: Text(year.toString()),
                                      onTap: () => Navigator.pop(context, year),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (pickedYear != null) {
                            setModalState(() => tempYear = pickedYear);
                          }
                        },
                        child: Text(tempYear.toString(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => setModalState(() => tempYear++),
                      ),
                    ],
                  ),
                  Expanded(
                    child: GridView.builder(
                      itemCount: 12,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedMonth = DateTime(tempYear, index + 1));
                            Navigator.pop(context);
                          },
                          child: Center(
                            child: Text(getMonthName(index + 1),
                                style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

const whiteSymbol = TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold);