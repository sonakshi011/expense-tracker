import 'package:expense_tracker/db/db_helper.dart';
import 'package:expense_tracker/screens/cash_in_screen.dart';
import 'package:expense_tracker/screens/cash_out_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String currency = '₹';

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  void loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currency = prefs.getString('currency') ?? '₹');
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = widget.expenses.where((e) {
      final date = DateTime.parse(e.date);
      return date.month == widget.selectedMonth.month &&
          date.year == widget.selectedMonth.year;
    }).toList();

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No transactions this month',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM, yyyy').format(date),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '$currency${getDayTotal(items).abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    color: getDayTotal(items) >= 0 ? Colors.red : Colors.green,
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

                // Bug fix: guard against null firestoreId before delete
                if (e.firestoreId == null) {
                  return _buildTransactionTile(e, context);
                }

                return Dismissible(
                  key: Key(e.firestoreId!),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Transaction'),
                        content: Text(
                            'Delete "${e.title.isNotEmpty ? e.title : e.category}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    await DbHelper.instance.deleteExpense(e.firestoreId!);
                    widget.onRefresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: _buildTransactionTile(e, context),
                );
              },
              childCount: items.length,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionTile(Expense e, BuildContext context) {
    // Show note as title if different from category, otherwise show category
    final displayTitle =
        (e.title.isNotEmpty && e.title != e.category) ? e.title : e.category;
    final displaySubtitle =
        (e.title.isNotEmpty && e.title != e.category) ? e.category : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: getCategoryColor(e.category),
        child: Icon(getCategoryIcon(e.category), color: Colors.white),
      ),
      title: Text(displayTitle),
      subtitle: displaySubtitle != null
          ? Text(displaySubtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: Text(
        e.type == 'expense'
            ? '-$currency${e.amount.toStringAsFixed(0)}'
            : '+$currency${e.amount.toStringAsFixed(0)}',
        style: TextStyle(
          color: e.type == 'expense' ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () async {
        bool? result;
        if (e.type == 'income') {
          result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => CashInScreen(expense: e)));
        } else {
          result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => CashOutScreen(expense: e)));
        }
        if (result == true) widget.onRefresh();
      },
    );
  }

  Map<String, List<Expense>> groupByDate(List<Expense> expenses) {
    Map<String, List<Expense>> grouped = {};
    for (var e in expenses) {
      String dateKey =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(e.date));
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(e);
    }
    return grouped;
  }

  double getDayTotal(List<Expense> items) {
    double total = 0;
    for (var e in items) {
      total += e.type == 'expense' ? e.amount : -e.amount;
    }
    return total;
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary': return Colors.green;
      case 'business': return Colors.blue;
      case 'investment': return Colors.purple;
      case 'rent': return Colors.orange;
      case 'loan': return Colors.red;
      case 'groceries': return Colors.purple;
      case 'fuel': return Colors.grey;
      case 'food/drink': return Colors.orange;
      case 'car/bike': return Colors.green;
      case 'taxi': return Colors.greenAccent;
      case 'clothes': return Colors.pink;
      case 'shopping': return Colors.purpleAccent;
      case 'entertainment': return Colors.blueAccent;
      case 'electricity': return Colors.blue;
      case 'maid salary': return Colors.red;
      case 'gym': return Colors.greenAccent;
      case 'subscriptions': return Colors.deepPurple;
      case 'education': return Colors.lightGreen;
      case 'healthcare': return Colors.redAccent;
      case 'vacation': return Colors.orange;
      case 'gas': return Colors.deepPurple;
      case 'water': return Colors.lightBlue;
      case 'tax': return Colors.teal;
      case 'other': return Colors.blueGrey;
      default: return Colors.blueGrey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary': return Icons.attach_money;
      case 'business': return Icons.work;
      case 'investment': return Icons.trending_up;
      case 'rent': return Icons.home;
      case 'loan': return Icons.account_balance;
      case 'groceries': return Icons.local_grocery_store;
      case 'fuel': return Icons.local_gas_station;
      case 'food/drink': return Icons.fastfood;
      case 'car/bike': return Icons.car_rental;
      case 'taxi': return Icons.local_taxi_rounded;
      case 'clothes': return Icons.man_outlined;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'entertainment': return Icons.tv;
      case 'electricity': return Icons.lightbulb_outline_sharp;
      case 'maid salary': return Icons.money;
      case 'gym': return Icons.sports_gymnastics;
      case 'subscriptions': return Icons.subscriptions;
      case 'education': return Icons.menu_book_sharp;
      case 'healthcare': return Icons.monitor_heart_rounded;
      case 'vacation': return Icons.holiday_village;
      case 'gas': return Icons.propane_tank;
      case 'water': return Icons.water_drop;
      case 'tax': return Icons.receipt_long;
      case 'other': return Icons.inventory_outlined;
      default: return Icons.category;
    }
  }
}
