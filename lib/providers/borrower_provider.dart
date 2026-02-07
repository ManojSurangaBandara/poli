import 'package:flutter/material.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../services/local_storage_service.dart';

class BorrowerProvider with ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  List<Borrower> _borrowers = [];
  bool _isLoading = false;

  List<Borrower> get borrowers => _borrowers;
  bool get isLoading => _isLoading;

  Future<void> loadBorrowers() async {
    _isLoading = true;
    notifyListeners();
    _borrowers = await _localStorageService.getBorrowers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBorrower(Borrower borrower) async {
    await _localStorageService.addBorrower(borrower);
    _borrowers.add(borrower);
    notifyListeners();
  }

  Future<void> updateBorrower(Borrower borrower) async {
    await _localStorageService.updateBorrower(borrower);
    int index = _borrowers.indexWhere((b) => b.id == borrower.id);
    if (index != -1) {
      _borrowers[index] = borrower;
      notifyListeners();
    }
  }

  Future<void> deleteBorrower(String id) async {
    await _localStorageService.deleteBorrower(id);
    _borrowers.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<List<Loan>> getLoansForBorrower(String borrowerId) async {
    return await _localStorageService.getLoansForBorrower(borrowerId);
  }

  Future<Loan?> getActiveLoanForBorrower(String borrowerId) async {
    return await _localStorageService.getActiveLoanForBorrower(borrowerId);
  }

  Future<void> addLoan(Loan loan) async {
    await _localStorageService.addLoan(loan);
    notifyListeners();
  }

  Future<void> updateLoan(Loan loan) async {
    await _localStorageService.updateLoan(loan);
    notifyListeners();
  }

  Future<void> deleteLoan(String loanId) async {
    await _localStorageService.deleteLoan(loanId);
    notifyListeners();
  }
}