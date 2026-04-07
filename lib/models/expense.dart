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
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? '',
      date: map['date'] ?? '',
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
      title: map['title'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      date: map['date'],
    );
  }
}