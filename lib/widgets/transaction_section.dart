import 'package:expense_tracker/db/db_helper.dart';
import 'package:expense_tracker/screens/cash_in_screen.dart';
import 'package:expense_tracker/screens/cash_out_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class TransactionSection extends StatefulWidget {
  final List<Expense> expenses;
  final VoidCallback onRefresh;
  final DateTime selectedMonth;

  const TransactionSection({
    super.key,
    required this.expenses,
    required this.onRefresh,
    required this.selectedMonth,
  });

  @override
  State<TransactionSection> createState() => _TransactionSectionState();
}

class _TransactionSectionState extends State<TransactionSection> {
  @override
  Widget build(BuildContext context) {
   //month filter(home)
    final filteredExpenses = widget.expenses.where((e) {
      final date = DateTime.parse(e.date);
      return date.month == widget.selectedMonth.month &&
          date.year == widget.selectedMonth.year;
    }).toList();

    final groupedExpenses = groupByDate(filteredExpenses);

    final sortedKeys = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      slivers: sortedKeys.map((dateKey) {
        final items = groupedExpenses[dateKey]!;
        final date = DateTime.parse(dateKey);

        return SliverStickyHeader(
          header: Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM, yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "₹${getDayTotal(items).toStringAsFixed(0)}",
                  style: TextStyle(
                    color: getDayTotal(items) >= 0
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),


          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final e = items[index];

                return Dismissible(
                  key: Key(e.id.toString()),

                  onDismissed: (_) async {
                    await DbHelper.instance
                        .deleteExpense(e.id!);

                    widget.onRefresh();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content: Text("Deleted")),
                    );
                  },

                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding:
                    const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),

                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      getCategoryColor(e.category),
                      child: Icon(
                        getCategoryIcon(e.category),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(e.title),
                    subtitle: Text(e.category),
                    trailing: Text(
                      e.type == "expense"
                          ? "-₹${e.amount}"
                          : "+₹${e.amount}",
                      style: TextStyle(
                        color: e.type == "expense"
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),


                    onTap: () async {
                      bool? result;

                      if (e.type == "income") {
                        result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CashInScreen(expense: e),
                          ),
                        );
                      } else {
                        result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CashOutScreen(expense: e),
                          ),
                        );
                      }

                      if (result == true) {
                        widget.onRefresh();
                      }
                    },
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        );
      }).toList(),
    );
  }


  Map<String, List<Expense>> groupByDate(
      List<Expense> expenses) {
    Map<String, List<Expense>> grouped = {};

    for (var e in expenses) {
      String dateKey = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(e.date));

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(e);
    }

    return grouped;
  }


  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case "salary":
        return Colors.green;
      case "business":
        return Colors.blue;
      case "investment":
        return Colors.purple;
      case "rent":
        return Colors.orange;
      case "loan":
        return Colors.red;
      case "groceries":
        return Colors.purple;
      case "food/drink":
        return Colors.orange;
      case "entertainment":
        return Colors.blueAccent;
      case "subscriptions":
        return Colors.deepPurple;
      case "other":
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }


  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "salary":
        return Icons.attach_money;
      case "business":
        return Icons.work;
      case "investment":
        return Icons.trending_up;
      case "rent":
        return Icons.home;
      case "loan":
        return Icons.account_balance;
      case "groceries":
        return Icons.local_grocery_store;
      case "food/drink":
        return Icons.fastfood;
      case "entertainment":
        return Icons.tv;
      case "subscriptions":
        return Icons.subscriptions;
      case "other":
        return Icons.inventory_outlined;
      default:
        return Icons.category;
    }
  }

  double getDayTotal(List<Expense> items) {
    double total = 0;

    for (var e in items) {
      if (e.type == "expense") {
        total += e.amount;
      } else {
        total -= e.amount;
      }
    }

    return total;
  }
}