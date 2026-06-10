import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db/db_helper.dart';
import '../models/expense.dart';
import '../services/receipt_scanner_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class CashOutScreen extends StatefulWidget {
  final Expense? expense;
  const CashOutScreen({super.key, this.expense});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  String selectedCategory = 'Select Category';
  DateTime selectedDate = DateTime.now();
  String currency = '₹';

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _activeField = '';
  static const MethodChannel _speechChannel =
  MethodChannel('spendwise.voice');

  // Receipt scanning
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    loadCurrency();
    _initSpeech();

    if (widget.expense != null) {
      selectedCategory = widget.expense!.category;
      amountController.text = widget.expense!.amount.toString();
      noteController.text = widget.expense!.title;
      selectedDate = DateTime.parse(widget.expense!.date);
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) => setState(() => _isListening = false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _startListening(String field) async {
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required'),
          ),
        );
      }
      return;
    }

    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _activeField = field;
    });

    await _speech.listen(
      localeId: "en_IN",
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      onResult: (result) {
        final words = result.recognizedWords;

        if (field == 'amount') {
          final numeric = _extractNumberFromSpeech(words);
          if (numeric != null) {
            amountController.text = numeric;
          }
        } else {
          noteController.text = words;
        }

        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  String? _extractNumberFromSpeech(String words) {
    final cleaned = words
        .toLowerCase()
        .replaceAll('rupees', '')
        .replaceAll('rupee', '')
        .replaceAll('rs', '')
        .replaceAll('dollars', '')
        .replaceAll('dollar', '')
        .replaceAll(',', '')
        .trim();
    final match = RegExp(r'[\d.]+').firstMatch(cleaned);
    return match?.group(0);
  }

  Future<void> _scanReceipt() async {
    final source = await ReceiptScannerService.showSourcePicker(context);
    if (source == null) return;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to scan receipts.')),
          );
        }
        return;
      }
    }

    setState(() => _isScanning = true);

    ReceiptScanResult? result;
    try {
      result = await ReceiptScannerService.scanReceipt(
        context: context,
        source: source,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }

    if (result != null && mounted) {
      setState(() {
        if (result!.amount != null) {
          amountController.text = result.amount!.toStringAsFixed(0);
        }
        if (result.category != null && result.category != 'Other') {
          selectedCategory = result.category!;
        } else if (selectedCategory == 'Select Category') {
          selectedCategory = 'Other';
        }
        if (result.title != null && result.title!.isNotEmpty) {
          noteController.text = result.title!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.amount != null
                ? '✅ Receipt scanned! Amount: $currency${result.amount!.toStringAsFixed(0)}'
                : '⚠️ Receipt scanned but no amount detected. Please fill manually.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Out'),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : null,
            ),
            tooltip: 'Voice Entry',
            onPressed: () {
              print("VOICE BUTTON CLICKED");
              _startVoiceTransaction();
            },
          ),

          IconButton(
            icon: _isScanning
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.document_scanner_outlined),
            tooltip: 'Scan Receipt / Bill',
            onPressed: _isScanning ? null : _scanReceipt,
          ),
        ],
      ),
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

            _buildFieldWithMic(
              controller: amountController,
              hint: 'Enter Amount',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.red,
              keyboardType: TextInputType.number,
              maxLength: 10,
              suffix: '$currency ',
              fieldKey: 'amount',
            ),

            const SizedBox(height: 8),

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

            _buildFieldWithMic(
              controller: noteController,
              hint: 'Write a note (Optional)',
              icon: Icons.edit,
              iconColor: Colors.red,
              maxLength: 40,
              fieldKey: 'note',
            ),

            if (_isListening)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _activeField == 'amount'
                          ? 'Listening for amount... say a number'
                          : 'Listening for note...',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _stopListening,
                      child: const Icon(Icons.stop_circle, color: Colors.red, size: 20),
                    ),
                  ],
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
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWithMic({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required String fieldKey,
    TextInputType keyboardType = TextInputType.text,
    int maxLength = 40,
    String? suffix,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: iconColor),
              hintText: hint,
              suffixText: suffix,
            ),
          ),
        ),
        if (_speechAvailable)
          GestureDetector(
            onTap: () {
              if (_isListening && _activeField == fieldKey) {
                _stopListening();
              } else {
                _startListening(fieldKey);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isListening && _activeField == fieldKey)
                      ? Colors.red.shade100
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (_isListening && _activeField == fieldKey)
                      ? Icons.mic
                      : Icons.mic_none,
                  color: (_isListening && _activeField == fieldKey)
                      ? Colors.red
                      : Colors.grey.shade600,
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void saveData() async {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount.')),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);

    if (selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Future transactions are not allowed.'),
        ),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final title = noteController.text.trim().isNotEmpty
        ? noteController.text.trim()
        : selectedCategory;

    if (widget.expense == null) {
      await DbHelper.instance.insertExpense(
        Expense(
          title: title,
          amount: amount,
          type: 'expense',
          category: selectedCategory,
          date: selectedDate.toIso8601String(),
        ),
      );
    } else {
      await DbHelper.instance.updateExpense(
        Expense(
          firestoreId: widget.expense!.firestoreId,
          title: title,
          amount: amount,
          type: 'expense',
          category: selectedCategory,
          date: selectedDate.toIso8601String(),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
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
              buildCategory('Groceries', Icons.local_grocery_store, Colors.purple),
              buildCategory('Fuel', Icons.local_gas_station, Colors.grey),
              buildCategory('Food/Drink', Icons.fastfood, Colors.orange),
              buildCategory('Car/Bike', Icons.car_rental, Colors.green),
              buildCategory('Taxi', Icons.local_taxi_rounded, Colors.greenAccent),
              buildCategory('Clothes', Icons.man_outlined, Colors.pinkAccent),
              buildCategory('Shopping', Icons.shopping_bag_outlined, Colors.purpleAccent),
              buildCategory('Entertainment', Icons.tv, Colors.blue),
              buildCategory('Electricity', Icons.lightbulb_outline_sharp, Colors.blueAccent),
              buildCategory('Rent', Icons.key, Colors.orange),
              buildCategory('Maid Salary', Icons.money, Colors.red),
              buildCategory('Gym', Icons.sports_gymnastics, Colors.lightGreen),
              buildCategory('Subscriptions', Icons.subscriptions, Colors.deepPurple),
              buildCategory('Education', Icons.menu_book_sharp, Colors.lightGreen),
              buildCategory('Healthcare', Icons.monitor_heart, Colors.red),
              buildCategory('Vacation', Icons.holiday_village, Colors.deepOrange),
              buildCategory('Loan', Icons.payment, Colors.amber),
              buildCategory('Gas', Icons.propane_tank, Colors.purple),
              buildCategory('Water', Icons.water_drop_outlined, Colors.green),
              buildCategory('Tax', Icons.receipt_long, Colors.blue),
              buildCategory('Other', Icons.inventory_outlined, Colors.blueGrey),
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
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _startVoiceTransaction() async {
    try {
      final result =
      await _speechChannel.invokeMethod<String>('startSpeech');

      if (result != null && result.trim().isNotEmpty) {
        _fillTransactionFromVoice(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice recognition not available.',
            ),
          ),
        );
      }
    }
  }
  void _fillTransactionFromVoice(String text) {

    noteController.text = text;

    final amountMatch =
    RegExp(r'\d+').firstMatch(text);

    if (amountMatch != null) {
      amountController.text =
      amountMatch.group(0)!;
    }

    final lower = text.toLowerCase();

    if (lower.contains('grocer')) {
      selectedCategory = 'Groceries';
    } else if (lower.contains('food')) {
      selectedCategory = 'Food';
    } else if (lower.contains('fuel')) {
      selectedCategory = 'Fuel';
    } else if (lower.contains('rent')) {
      selectedCategory = 'Rent';
    } else if (lower.contains('shopping')) {
      selectedCategory = 'Shopping';
    } else if (lower.contains('salary')) {
      selectedCategory = 'Salary';
    } else {
      selectedCategory = 'Other';
    }

    setState(() {});
  }
  void loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currency = prefs.getString('currency') ?? '₹');
  }



  @override
  void dispose() {
    _speech.stop();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}