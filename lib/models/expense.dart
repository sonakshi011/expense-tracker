class Expense {
  final String? firestoreId;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String date;

  Expense({
    this.firestoreId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
    };
  }

  factory Expense.fromFirestore(String docId, Map<String, dynamic> map) {
    return Expense(
      firestoreId: docId,
      // Bug fix: title was missing fallback to category when empty
      title: (map['title'] as String? ?? '').isNotEmpty
          ? map['title'] as String
          : map['category'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? '',
      date: map['date'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      title: (map['title'] as String? ?? '').isNotEmpty
          ? map['title'] as String
          : map['category'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? '',
      date: map['date'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Expense copyWith({
    String? firestoreId,
    String? title,
    double? amount,
    String? type,
    String? category,
    String? date,
  }) {
    return Expense(
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}
