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
  //new
  String name = "";
  String email = "";
  String phone = "";
  bool isLoadingProfile = true;//new

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
    setState(() {
      bookName = prefs.getString("bookName") ?? "My Book";
      currency = prefs.getString("currency") ?? "₹";
      selectedColor = Color(prefs.getInt("themeColor") ?? Colors.teal.value);
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("bookName", bookName);
    await prefs.setString("currency", currency);
    await prefs.setInt("themeColor", selectedColor.value);
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

      Navigator.of(context).pop();
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => const LoginScreen()),
      //       (route) => false,
      // );
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
//new
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
      }
    }
  }//new
//new
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }//new


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
              if (value == 'logout') {
                _logout();
              }
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
          //new
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
                )
              ],
            ),
          ),//new

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
        ],
      ),
    );
  }
}