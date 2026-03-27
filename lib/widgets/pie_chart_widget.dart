import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';

class PieChartWidget extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime selectedMonth;

  const PieChartWidget({
    super.key,
    required this.expenses,
    required this.selectedMonth,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int touchedIndex = -1;
  bool showExpense = true;

  final Map<String, Color> categoryColors = {
    "Food/Drink": Colors.orange,
    "Entertainment": Colors.blue,
    "Subscription": Colors.deepPurple,
    "Other": Colors.brown,
    "Business": Colors.blue,
    "Salary": Colors.green,
    "Investment": Colors.red,
    "Rent": Colors.orange,
    "Loan": Colors.yellow,
    "Groceries": Colors.purple,
    "Fuel": Colors.grey,
    "Car/Bike": Colors.green,
    "Taxi": Colors.greenAccent,
    "Clothes": Colors.pink,
    "Shopping": Colors.purpleAccent,
    "Healthcare": Colors.red,
    "Electricity": Colors.blue,
    "Maid Salary": Colors.red,
    "Gym": Colors.lightGreen,
    "Education": Colors.greenAccent,
    "Vacation": Colors.orange,
    "Gas": Colors.deepPurple,
    "Water": Colors.green,
    "Tax": Colors.blueAccent,
  };

  Map<String, IconData> categoryIcons = {
    "Food/Drink": Icons.fastfood,
    "Entertainment": Icons.tv,
    "Subscription": Icons.subscriptions,
    "Other": Icons.inventory_outlined,
    "Business": Icons.work,
    "Salary": Icons.attach_money,
    "Investment": Icons.trending_up,
    "Rent" :Icons.home,
    "Loan" :Icons.payment,
    "Groceries": Icons.local_grocery_store,
    "Fuel": Icons.local_gas_station,
    "Car/Bike": Icons.car_rental,
    "Taxi": Icons.local_taxi_rounded,
    "Clothes": Icons.man_outlined,
    "Shopping": Icons.shopping_bag_outlined,
    "Electricity": Icons.lightbulb_outline_sharp,
    "Maid Salary": Icons.money,
    "Gym": Icons.sports_gymnastics,
    "Education": Icons.menu_book_sharp,
    "Healthcare": Icons.monitor_heart,
    "Vacation": Icons.holiday_village,
    "Gas": Icons.propane_tank,
    "Water": Icons.water_drop_outlined,
    "Tax": Icons.receipt_long,
  };

  @override
  Widget build(BuildContext context) {

    final filtered = widget.expenses.where((e) {
      final date = DateTime.parse(e.date);
      return (e.type == (showExpense ? "expense" : "income")) &&
          date.month == widget.selectedMonth.month &&
          date.year == widget.selectedMonth.year;
    }).toList();


    final chartData = filtered.isEmpty
        ? widget.expenses.where((e) => e.type == "expense").toList()
        : filtered;


    Map<String, double> categoryMap = {};
    Map<String, int> categoryCount = {};
    for (var e in chartData) {

      categoryMap[e.category] =
          (categoryMap[e.category] ?? 0) + e.amount;

      categoryCount[e.category] =
          (categoryCount[e.category] ?? 0) + 1;
    }

    double total =
    categoryMap.values.fold(0, (a, b) => a + b);

    final entries = categoryMap.entries.toList();

    final sections = entries.asMap().entries.map((entry) {
      int index = entry.key;
      var data = entry.value;

      final isTouched = index == touchedIndex;

      return PieChartSectionData(
        value: data.value,
        color: categoryColors[data.key] ?? Colors.grey,
        radius: isTouched ? 80 : 70,
        title: '',
      );
    }).toList();

    String centerText;
    String subText;

    if (touchedIndex == -1) {
      centerText = total.toStringAsFixed(0);
      subText = "Total";
    } else {
      centerText =
          entries[touchedIndex].value.toStringAsFixed(0);
      subText = entries[touchedIndex].key;
    }

    return SingleChildScrollView(
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showExpense = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: showExpense ? Colors.red : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.credit_card_off_sharp,
                            color: showExpense ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Cash Out",
                            style: TextStyle(
                              color: showExpense ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showExpense = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !showExpense ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_card,
                            color: !showExpense ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Cash In",
                            style: TextStyle(
                              color: !showExpense ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Stack(
            alignment: Alignment.center,
            children: [

              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = response
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    centerText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: showExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Column(
            children: entries.asMap().entries.map((entry) {
              int index = entry.key;
              var e = entry.value;

              final isSelected = index == touchedIndex;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (categoryColors[e.key] ?? Colors.grey).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: categoryColors[e.key] ?? Colors.grey,
                    child: Icon(
                      categoryIcons[e.key] ?? Icons.category,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    e.key,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),

                  subtitle: Text(
                    "${categoryCount[e.key]} Transaction${categoryCount[e.key]! > 1 ? 's' : ''}",
                  ),

                  trailing: Text(
                    "-${e.value.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}