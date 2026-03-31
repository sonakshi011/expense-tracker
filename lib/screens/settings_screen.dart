import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:currency_picker/currency_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String bookName = "My Book";
  String currency = "₹";
  Color selectedColor = Colors.teal;

  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.teal,
    Colors.purple,
    Colors.orange,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      bookName = prefs.getString("bookName") ?? "My Book";
      currency = prefs.getString("currency") ?? "₹";
      selectedColor = Color(
        prefs.getInt("themeColor") ?? Colors.teal.value,
      );
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("bookName", bookName);
    await prefs.setString("currency", currency);
    await prefs.setInt("themeColor", selectedColor.value);
  }

  void editBookName() {
    final controller = TextEditingController(text: bookName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Book Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                bookName = controller.text;
              });
              saveSettings();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void selectCurrency() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currencyData) {
        setState(() {
          currency = currencyData.symbol;
        });
        saveSettings();
      },
    );
  }

  Widget buildCurrency(String symbol, String name) {
    return ListTile(
      title: Text(name),
      onTap: () {
        setState(() {
          currency = symbol;
        });
        saveSettings();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: selectedColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: const [
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 10),
        ],
      ),

      body: ListView(
        children: [

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Book Name",
                  style: TextStyle(color: Colors.grey),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bookName,
                      style: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: editBookName,
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Theme",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.map((color) {
                    final isSelected = selectedColor.value == color.value;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                        saveSettings();
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: color,
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text(
                "Select Currency",
                style: TextStyle(color: Colors.grey),
              ),
              subtitle: Text(
                currency,
                style: const TextStyle(fontSize: 20),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: selectCurrency,
            ),
          ),
        ],
      ),
    );
  }
}