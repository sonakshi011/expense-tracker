import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CashOutScreen extends StatefulWidget {
  final Expense? expense;
  const CashOutScreen({super.key, this.expense});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
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
      appBar: AppBar(title: const Text("Cash Out")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.grid_view, color: Colors.red),
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
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.red),
                hintText: "Enter Amount",
                suffixText: "$currency ",
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_calendar_outlined, color: Colors.red),
                  title: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                  onTap: pickDate,
                ),
                const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Colors.grey),
              ],
            ),
            TextField(
              controller: noteController,
              maxLength: 20,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.edit, color: Colors.red),
                hintText: "Write a note (Optional)",
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
          type: "expense",
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
          type: "expense",
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
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 400,
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(16),
            children: [
              buildCategory("Groceries", Icons.local_grocery_store, Colors.purple),
              buildCategory("Fuel", Icons.local_gas_station, Colors.black12),
              buildCategory("Food/Drink", Icons.fastfood, Colors.orange),
              buildCategory("Car/Bike", Icons.car_rental, Colors.green),
              buildCategory("Taxi", Icons.local_taxi_rounded, Colors.greenAccent),
              buildCategory("Clothes", Icons.man_outlined, Colors.pinkAccent),
              buildCategory("Shopping", Icons.shopping_bag_outlined, Colors.purpleAccent),
              buildCategory("Entertainment", Icons.tv, Colors.blue),
              buildCategory("Electricity", Icons.lightbulb_outline_sharp, Colors.blueAccent),
              buildCategory("Rent", Icons.key, Colors.orange),
              buildCategory("Maid Salary", Icons.money, Colors.red),
              buildCategory("Gym", Icons.sports_gymnastics, Colors.lightGreen),
              buildCategory("Subscriptions", Icons.subscriptions, Colors.deepPurple),
              buildCategory("Education", Icons.menu_book_sharp, Colors.lightGreenAccent),
              buildCategory("Healthcare", Icons.monitor_heart, Colors.red),
              buildCategory("Vacation", Icons.holiday_village, Colors.deepOrange),
              buildCategory("Loan", Icons.payment, Colors.yellow),
              buildCategory("Gas", Icons.propane_tank, Colors.purple),
              buildCategory("Water", Icons.water_drop_outlined, Colors.green),
              buildCategory("Tax", Icons.receipt_long, Colors.blue),
              buildCategory("Other", Icons.inventory_outlined, Colors.blueGrey),
            ],
          ),
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