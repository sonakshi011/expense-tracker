import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CashInScreen extends StatefulWidget {
  final Expense? expense;

  const CashInScreen({super.key, this.expense});

  @override
  State<CashInScreen> createState() => _CashInScreenState();
}

class _CashInScreenState extends State<CashInScreen> {
  String selectedCategory = "Select Category";
  DateTime selectedDate = DateTime.now();
  String currency = "₹";

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrency();

    if (widget.expense != null) {
      selectedCategory = widget.expense!.category;
      amountController.text = widget.expense!.amount.toString();
      selectedDate = DateTime.parse(widget.expense!.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cash In")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.grid_view, color: Colors.green),
                  title: Text(selectedCategory),
                  onTap: openCategorySheet,
                ),
                const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Colors.grey),
              ],
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.green),
                hintText: "Enter Amount",
                suffixText: "$currency ",
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_calendar_outlined, color: Colors.green),
                  title: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                  onTap: pickDate,
                ),
                const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Colors.grey),
              ],
            ),
            TextField(
              controller: noteController,
              maxLength: 20,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.edit, color: Colors.green),
                hintText: "Write a note (Optional)",
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: saveData,
              child: const Text("Add Transaction"),
            ),
          ],
        ),
      ),
    );
  }

  void saveData() async {
    if (amountController.text.isEmpty) return;

    if (widget.expense == null) {

      await DbHelper.instance.insertExpense(
        Expense(
          title: selectedCategory,
          amount: double.parse(amountController.text),
          type: "income",
          category: selectedCategory,
          date: selectedDate.toIso8601String(),
        ),
      );
    } else {

      await DbHelper.instance.updateExpense(
        Expense(
          firestoreId: widget.expense!.firestoreId,
          title: selectedCategory,
          amount: double.parse(amountController.text),
          type: "income",
          category: selectedCategory,
          date: selectedDate.toIso8601String(),
        ),
      );
    }

    Navigator.pop(context, true);
  }

  void openCategorySheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(16),
          children: [
            buildCategory("Salary", Icons.attach_money, Colors.green),
            buildCategory("Business", Icons.work, Colors.blue),
            buildCategory("Investment", Icons.trending_up, Colors.red),
            buildCategory("Rent", Icons.home, Colors.orange),
            buildCategory("Loan", Icons.money, Colors.yellow),
            buildCategory("Other", Icons.category, Colors.purple),
          ],
        );
      },
    );
  }

  Widget buildCategory(String name, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedCategory = name);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(name),
        ],
      ),
    );
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currency = prefs.getString("currency") ?? "₹");
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}