import 'package:expense_tracker/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String bookName = "My Book";
  String currency = "₹";
  Color selectedColor = Colors.teal;
  String name = "";
  String email = "";
  String phone = "";
  bool isLoadingProfile = true;

  bool isLimitEnabled = false;
  double limitAmount = 0;
  String limitType = "daily";

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
    loadUserData();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          bookName = data['bookName'] ?? "My Book";
          currency = data['currency'] ?? "₹";
          selectedColor = Color(data['themeColor'] ?? Colors.teal.value);
          isLimitEnabled = data['isLimitEnabled'] ?? false;
          limitAmount = (data['limitAmount'] ?? 0).toDouble();
          limitType = data['limitType'] ?? "daily";
        });
      }
    } else {
      setState(() {
        bookName = prefs.getString("bookName") ?? "My Book";
        currency = prefs.getString("currency") ?? "₹";
        selectedColor = Color(prefs.getInt("themeColor") ?? Colors.teal.value);
      });
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    await prefs.setString("bookName", bookName);
    await prefs.setString("currency", currency);
    await prefs.setInt("themeColor", selectedColor.value);

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'bookName': bookName,
        'currency': currency,
        'themeColor': selectedColor.value,
        'isLimitEnabled': isLimitEnabled,
        'limitAmount': limitAmount,
        'limitType': limitType,
      });
    }
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          name = doc['name'] ?? "";
          email = doc['email'] ?? "";
          phone = doc['phone'] ?? "";
          isLoadingProfile = false;
        });
      } else {
        setState(() => isLoadingProfile = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().disconnect();
      if (mounted) Navigator.of(context).pop();
    }
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
              setState(() => bookName = controller.text);
              saveSettings();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void editLimitAmount() {
    final controller = TextEditingController(
      text: limitAmount > 0 ? limitAmount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Limit Amount"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: "$currency ",
            hintText: "Enter amount",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null && parsed > 0) {
                setState(() => limitAmount = parsed);
                saveSettings();
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final user = FirebaseAuth.instance.currentUser;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == true && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });

      setState(() {
        name = nameController.text.trim();
        phone = phoneController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void selectCurrency() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currencyData) {
        setState(() => currency = currencyData.symbol);
        saveSettings();
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: ListView(
        children: [

          Container(
            color: selectedColor,
            padding: const EdgeInsets.all(20),
            child: isLoadingProfile
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 24,
                      color: selectedColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _editProfile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(phone, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),


          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Book Name", style: TextStyle(color: Colors.grey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bookName, style: const TextStyle(fontSize: 18)),
                    IconButton(icon: const Icon(Icons.edit), onPressed: editBookName),
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
                const Text("Select Theme", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedColor = color);
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
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text("Select Currency", style: TextStyle(color: Colors.grey)),
              subtitle: Text(currency, style: const TextStyle(fontSize: 20)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: selectCurrency,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text(
                    "Enable Expense Limit",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    "Get notified when you reach your spending limit",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: isLimitEnabled,
                  activeColor: selectedColor,
                  onChanged: (val) {
                    setState(() => isLimitEnabled = val);
                    saveSettings();
                  },
                ),

                if (isLimitEnabled) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Limit Period",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ["daily", "weekly", "monthly"].map((type) {
                            final isSelected = limitType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => limitType = type);
                                  saveSettings();
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? selectedColor : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? selectedColor : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      type[0].toUpperCase() + type.substring(1),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  ListTile(
                    leading: Icon(Icons.account_balance_wallet_outlined, color: selectedColor),
                    title: const Text("Limit Amount"),
                    subtitle: Text(
                      limitAmount > 0
                          ? "$currency${limitAmount.toStringAsFixed(0)}"
                          : "Tap to set amount",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,

                        color: limitAmount > 0 ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    trailing: Icon(Icons.edit, color: selectedColor),
                    onTap: editLimitAmount,
                  ),


                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: selectedColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            limitAmount > 0
                                ? "You'll be notified when $limitType expenses reach $currency${limitAmount.toStringAsFixed(0)}. Spending more after that triggers 4 alerts."
                                : "Please set a limit amount to enable notifications.",
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}