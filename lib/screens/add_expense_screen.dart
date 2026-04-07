import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';


class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  String type = "expense";
  String category = "Food";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "title"),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            DropdownButton<String>(
              value: category,
              items: ["Food", "Entertainment", "Subscription"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => category = value!),
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Expense"),
                  selected: type == "expense",
                  onSelected: (_) => setState(() => type = "expense"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Income"),
                  selected: type == "income",
                  onSelected: (_) => setState(() => type = "income"),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await DbHelper.instance.insertExpense(
                  Expense(
                    title: titleController.text,
                    amount: double.parse(amountController.text),
                    type: type,
                    category: category,
                    date: DateTime.now().toIso8601String(),
                  ),
                );
                Navigator.pop(context, true);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}