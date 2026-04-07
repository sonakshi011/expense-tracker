import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

class DbHelper {

  static final DbHelper instance = DbHelper._init();
  DbHelper._init();

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _expensesRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_userId)
      .collection('expenses');

  Future<void> insertExpense(Expense expense) async {
    await _expensesRef.add(expense.toFirestore());
  }

  Future<List<Expense>> getExpenses() async {
    final snapshot = await _expensesRef
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return Expense.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> deleteExpense(String firestoreId) async {
    await _expensesRef.doc(firestoreId).delete();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expensesRef.doc(expense.firestoreId).update(expense.toFirestore());
  }

  Future<void> clearAllData() async {
    final snapshot = await _expensesRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}