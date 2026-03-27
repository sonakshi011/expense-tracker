import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../widgets/transaction_section.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/cash_in_screen.dart';
import '../screens/cash_out_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];
  int selectedIndex = 0;
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final data = await DbHelper.instance.getExpenses();
    setState(() {
      expenses = data;
    });
  }

  double getTotalIncome() {
    return expenses
        .where((e) => e.type == "income")
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getTotalExpense() {
    return expenses
        .where((e) => e.type == "expense")
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getBalance() => getTotalIncome() - getTotalExpense();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5F6D), Color(0xFFFF2D55)],
              ),
            ),
            child: Column(
              children: [

                const Text(
                  "My Book",
                  style: TextStyle(
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
                      selectedMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month - 1,
                      );
                    });
                  },
                ),


                GestureDetector(
                  onTap: () {
                    openMonthYearPicker();
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "${getMonthName(selectedMonth.month)} ${selectedMonth.year}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),


                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),


          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text("No Transactions Yet"))
                : TransactionSection(
              expenses: expenses,
              onRefresh: loadExpenses,
                selectedMonth: selectedMonth,
            ),
          ),
        ],
      ),


     /// floatingActionButton: FloatingActionButton(
        ///onPressed: () async {
          ///final result = await Navigator.push(
            ///context,
            ///MaterialPageRoute(
              ///builder: (_) => const CashOutScreen(),
            ///),
          ///);

          ///if (result == true) loadExpenses();
        ///},
        ///child: const Icon(Icons.add),
      ///),


      bottomNavigationBar: BottomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) async {

          if (index == 1) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CashInScreen(),
              ),
            );

            if (result == true) loadExpenses();

          } else if (index == 2) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CashOutScreen(),
              ),
            );

            if (result == true) loadExpenses();

          } else {
            setState(() {
              selectedIndex = index;
            });
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
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        Text(title,
            style: const TextStyle(color: Colors.white70)),
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
                        onPressed: () {
                          setModalState(() {
                            tempYear--;
                          });
                        },
                      ),

                      GestureDetector(
                        onTap: () async {
                          final pickedYear = await showDialog<int>(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
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
                                        onTap: () {
                                          Navigator.pop(context, year);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );

                          if (pickedYear != null) {
                            setModalState(() {
                              tempYear = pickedYear;
                            });
                          }
                        },
                        child: Text(
                          tempYear.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          setModalState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),


                  Expanded(
                    child: GridView.builder(
                      itemCount: 12,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                      ),
                      itemBuilder: (context, index) {
                        final monthName = getMonthName(index + 1);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMonth = DateTime(tempYear, index + 1);
                            });

                            Navigator.pop(context);
                          },
                          child: Center(
                            child: Text(
                              monthName,
                              style: const TextStyle(fontSize: 16),
                            ),
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

const whiteSymbol = TextStyle(
  color: Colors.white,
  fontSize: 20,
  fontWeight: FontWeight.bold,
);