import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result from scanning a receipt/bill
class ReceiptScanResult {
  final double? amount;
  final String? category;
  final String? title;
  final String? type; // 'expense' or 'income'
  final String rawText;

  ReceiptScanResult({
    this.amount,
    this.category,
    this.title,
    this.type,
    required this.rawText,
  });
}

class ReceiptScannerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera or gallery and scan it
  static Future<ReceiptScanResult?> scanReceipt({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (image == null) return null;

      return await _processImage(File(image.path));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to scan receipt: $e')),
        );
      }
      return null;
    }
  }

  static Future<ReceiptScanResult> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      // Parse the extracted text
      final result = _parseReceiptText(rawText);
      return result;
    } finally {
      textRecognizer.close();
    }
  }

  static ReceiptScanResult _parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? amount = _extractAmount(text);
    String? category = _detectCategory(text);
    String? title = _extractTitle(lines);
    String type = _detectType(text);

    return ReceiptScanResult(
      amount: amount,
      category: category,
      title: title,
      type: type,
      rawText: text,
    );
  }

  // ─── Amount Extraction ────────────────────────────────────────────────────

  static double? _extractAmount(String text) {
    // Priority patterns: Total, Grand Total, Net Amount, Amount Due, Balance Due
    final priorityPatterns = [
      // Grand total / Total patterns with currency
      RegExp(
          r'(?:grand\s*total|total\s*amount|net\s*amount|amount\s*due|balance\s*due|total\s*payable|payable\s*amount)[^\d]*(\d[\d,]*\.?\d{0,2})',
          caseSensitive: false),
      // Total with Rs / ₹ / $ prefix
      RegExp(
          r'total[^\d]*(?:rs\.?|₹|\$|inr|usd)?\s*(\d[\d,]*\.?\d{0,2})',
          caseSensitive: false),
      // Rs / ₹ followed by number on a "total" line
      RegExp(
          r'(?:rs\.?|₹|\$)\s*(\d[\d,]*\.?\d{0,2})',
          caseSensitive: false),
    ];

    for (final pattern in priorityPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amtStr = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(amtStr);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Fallback: largest number on a line containing "total" keyword
    final totalLinePattern = RegExp(r'total', caseSensitive: false);
    for (final line in text.split('\n')) {
      if (totalLinePattern.hasMatch(line)) {
        final nums = RegExp(r'(\d[\d,]*\.?\d{0,2})').allMatches(line);
        double? biggest;
        for (final m in nums) {
          final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
          if (v != null && (biggest == null || v > biggest)) biggest = v;
        }
        if (biggest != null && biggest > 0) return biggest;
      }
    }

    // Last resort: biggest number in whole text
    final allNums = RegExp(r'(\d[\d,]*\.?\d{0,2})').allMatches(text);
    double? biggest;
    for (final m in allNums) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (v != null && v > 0 && v < 9999999 && (biggest == null || v > biggest)) {
        biggest = v;
      }
    }
    return biggest;
  }

  // ─── Category Detection ───────────────────────────────────────────────────

  static const Map<String, List<String>> _categoryKeywords = {
    'Groceries': ['grocery', 'groceries', 'supermarket', 'mart', 'dmart', 'bigbasket',
        'reliance fresh', 'nature basket', 'vegetables', 'fruits', 'bakery'],
    'Food/Drink': ['restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'food',
        'swiggy', 'zomato', 'hotel', 'dhaba', 'biryani', 'fast food',
        'mcdonalds', 'kfc', 'dominos', 'subway', 'canteen'],
    'Fuel': ['petrol', 'diesel', 'fuel', 'gas station', 'hp', 'indian oil',
        'bharat petroleum', 'iocl', 'hpcl', 'bpcl', 'pump'],
    'Shopping': ['amazon', 'flipkart', 'myntra', 'mall', 'shop', 'store',
        'fashion', 'clothing', 'apparel', 'boutique'],
    'Clothes': ['clothes', 'shirt', 'pant', 'dress', 'garment', 'textile',
        'readymade', 'zara', 'h&m'],
    'Healthcare': ['pharmacy', 'medical', 'hospital', 'clinic', 'doctor',
        'medicine', 'drugs', 'apollo', 'medplus', 'diagnostic', 'lab',
        'pathology', 'health'],
    'Entertainment': ['cinema', 'movie', 'pvr', 'inox', 'multiplex',
        'entertainment', 'games', 'sport', 'bowling'],
    'Education': ['school', 'college', 'university', 'tuition', 'course',
        'books', 'stationery', 'institute', 'academy'],
    'Electricity': ['electricity', 'power', 'bescom', 'mseb', 'tpddl',
        'wapda', 'electric bill', 'energy bill'],
    'Water': ['water', 'bwssb', 'jal', 'municipal water'],
    'Rent': ['rent', 'lease', 'rental', 'tenant', 'landlord'],
    'Taxi': ['uber', 'ola', 'taxi', 'cab', 'auto', 'rapido', 'ride'],
    'Subscriptions': ['netflix', 'amazon prime', 'hotstar', 'spotify',
        'subscription', 'renewal', 'recharge', 'plan'],
    'Gas': ['lpg', 'gas', 'cylinder', 'indane', 'hp gas', 'bharat gas'],
    'Salary': ['salary', 'payroll', 'wages', 'stipend', 'remuneration'],
    'Investment': ['mutual fund', 'sip', 'stocks', 'shares', 'investment',
        'zerodha', 'groww', 'upstox'],
    'Business': ['invoice', 'business', 'vendor', 'supplier', 'purchase order'],
  };

  static String? _detectCategory(String text) {
    final lower = text.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }

  // ─── Title Extraction ─────────────────────────────────────────────────────

  static String? _extractTitle(List<String> lines) {
    if (lines.isEmpty) return null;

    // Skip very short lines and lines that look like dates/numbers only
    for (final line in lines.take(5)) {
      if (line.length >= 3 &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          !RegExp(r'^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}').hasMatch(line)) {
        return line.length > 40 ? '${line.substring(0, 37)}...' : line;
      }
    }
    return lines.first.length > 40
        ? '${lines.first.substring(0, 37)}...'
        : lines.first;
  }

  // ─── Income vs Expense Detection ─────────────────────────────────────────

  static String _detectType(String text) {
    final lower = text.toLowerCase();
    final incomeKeywords = [
      'salary', 'income', 'credit', 'received', 'payment received',
      'refund', 'cashback', 'reward', 'dividend', 'interest credited',
      'transfer received', 'payroll',
    ];
    for (final kw in incomeKeywords) {
      if (lower.contains(kw)) return 'income';
    }
    return 'expense';
  }

  /// Show bottom sheet to choose camera or gallery
  static Future<ImageSource?> showSourcePicker(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Scan Receipt / Bill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
