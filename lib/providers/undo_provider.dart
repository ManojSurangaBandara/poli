import 'package:flutter/material.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import 'borrower_provider.dart';

enum ActionType {
  addBorrower,
  deleteBorrower,
  lendMoney,
  collectInterest,
  settleLoan,
}

class UndoableAction {
  final ActionType type;
  final dynamic data;
  final DateTime timestamp;

  UndoableAction({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class UndoProvider with ChangeNotifier {
  UndoableAction? _lastAction;

  UndoableAction? get lastAction => _lastAction;

  bool get canUndo => _lastAction != null;

  void recordAction(ActionType type, dynamic data) {
    _lastAction = UndoableAction(
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }

  void clearLastAction() {
    _lastAction = null;
    notifyListeners();
  }

  Future<void> undo(BorrowerProvider borrowerProvider) async {
    if (_lastAction == null) return;

    switch (_lastAction!.type) {
      case ActionType.addBorrower:
        final borrower = _lastAction!.data as Borrower;
        await borrowerProvider.deleteBorrower(borrower.id);
        break;
      case ActionType.deleteBorrower:
        final borrower = _lastAction!.data as Borrower;
        await borrowerProvider.addBorrower(borrower);
        break;
      case ActionType.lendMoney:
        final loan = _lastAction!.data as Loan;
        await borrowerProvider.deleteLoan(loan.id);
        break;
      case ActionType.collectInterest:
        final data = _lastAction!.data as Map<String, dynamic>;
        final loan = data['loan'] as Loan;
        final previousDate = data['previousInterestDate'] as DateTime;
        
        // Restore the loan's next interest due date to the previous date
        final restoredLoan = Loan(
          id: loan.id,
          borrowerId: loan.borrowerId,
          amount: loan.amount,
          date: loan.date,
          status: loan.status,
          interestPercentage: loan.interestPercentage,
          interest: loan.interest,
          nextInterestDueDate: previousDate,
          repaidDate: loan.repaidDate,
        );
        await borrowerProvider.updateLoan(restoredLoan);
        break;
      case ActionType.settleLoan:
        final loan = _lastAction!.data as Loan;
        // Restore the loan to active status
        final restoredLoan = Loan(
          id: loan.id,
          borrowerId: loan.borrowerId,
          amount: loan.amount,
          date: loan.date,
          status: 'active',
          interestPercentage: loan.interestPercentage,
          interest: loan.interest,
          nextInterestDueDate: loan.nextInterestDueDate,
          repaidDate: null,
        );
        await borrowerProvider.updateLoan(restoredLoan);
        break;
    }

    _lastAction = null;
    notifyListeners();
  }

  String getActionDescription() {
    if (_lastAction == null) return '';

    switch (_lastAction!.type) {
      case ActionType.addBorrower:
        final borrower = _lastAction!.data as Borrower;
        return 'Added borrower "${borrower.name}"';
      case ActionType.deleteBorrower:
        final borrower = _lastAction!.data as Borrower;
        return 'Deleted borrower "${borrower.name}"';
      case ActionType.lendMoney:
        final loan = _lastAction!.data as Loan;
        return 'Lent රු. ${loan.amount.toStringAsFixed(2)}';
      case ActionType.collectInterest:
        final data = _lastAction!.data as Map<String, dynamic>;
        return 'Collected රු. ${data['interest'].toStringAsFixed(2)} interest';
      case ActionType.settleLoan:
        final loan = _lastAction!.data as Loan;
        return 'Settled loan of රු. ${loan.amount.toStringAsFixed(2)}';
    }
  }
}