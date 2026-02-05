import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../providers/borrower_provider.dart';

class DashboardTab extends StatefulWidget {
  final Borrower borrower;

  const DashboardTab({super.key, required this.borrower});

  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Loan? _activeLoan;

  @override
  void initState() {
    super.initState();
    _loadActiveLoan();
  }

  Future<void> _loadActiveLoan() async {
    final provider = Provider.of<BorrowerProvider>(context, listen: false);
    _activeLoan = await provider.getActiveLoanForBorrower(widget.borrower.id);
    if (_activeLoan != null && _activeLoan!.interest == 0.0 && _activeLoan!.interestPercentage > 0) {
      // Recalculate interest
      final updatedLoan = Loan(
        id: _activeLoan!.id,
        borrowerId: _activeLoan!.borrowerId,
        amount: _activeLoan!.amount,
        date: _activeLoan!.date,
        status: _activeLoan!.status,
        interestPercentage: _activeLoan!.interestPercentage,
        interest: _activeLoan!.amount * (_activeLoan!.interestPercentage / 100),
        nextInterestDueDate: _activeLoan!.nextInterestDueDate,
      );
      await provider.updateLoan(updatedLoan);
      _activeLoan = updatedLoan;
    }
    setState(() {});
  }

  void _showLendMoneyDialog() {
    final _amountController = TextEditingController();
    final _interestController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lend Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _interestController,
              decoration: const InputDecoration(labelText: 'Interest Rate (%)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              final interest = double.tryParse(_interestController.text) ?? 0.0;
              if (amount != null && amount > 0) {
                final installmentAmount = amount * (interest / 100);
                final nextInstallmentDate = DateTime.now().add(const Duration(days: 30));
                final loan = Loan(
                  id: const Uuid().v4(),
                  borrowerId: widget.borrower.id,
                  amount: amount,
                  date: DateTime.now(),
                  interestPercentage: interest,
                  interest: installmentAmount,
                  nextInterestDueDate: nextInstallmentDate,
                );
                final provider = Provider.of<BorrowerProvider>(context, listen: false);
                await provider.addLoan(loan);
                Navigator.pop(context);
                _loadActiveLoan();
              }
            },
            child: const Text('Lend'),
          ),
        ],
      ),
    );
  }

  Future<void> _payInterest() async {
    final provider = Provider.of<BorrowerProvider>(context, listen: false);
    final updatedLoan = Loan(
      id: _activeLoan!.id,
      borrowerId: _activeLoan!.borrowerId,
      amount: _activeLoan!.amount,
      date: _activeLoan!.date,
      status: _activeLoan!.status,
      interestPercentage: _activeLoan!.interestPercentage,
      interest: _activeLoan!.interest,
      nextInterestDueDate: _activeLoan!.nextInterestDueDate.add(const Duration(days: 30)),
      repaidDate: _activeLoan!.repaidDate,
    );
    await provider.updateLoan(updatedLoan);
    _loadActiveLoan();
    
    // Show success alert
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Interest Paid'),
          content: Text('Interest of ₹${_activeLoan!.interest.toStringAsFixed(2)} has been collected. Next due date updated to ${updatedLoan.nextInterestDueDate.toLocal().toString().split(' ')[0]}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _settleLoan() async {
    final provider = Provider.of<BorrowerProvider>(context, listen: false);
    final settledLoan = Loan(
      id: _activeLoan!.id,
      borrowerId: _activeLoan!.borrowerId,
      amount: _activeLoan!.amount,
      date: _activeLoan!.date,
      status: 'repaid',
      interestPercentage: _activeLoan!.interestPercentage,
      interest: _activeLoan!.interest,
      nextInterestDueDate: _activeLoan!.nextInterestDueDate,
      repaidDate: DateTime.now(),
    );
    await provider.updateLoan(settledLoan);
    _loadActiveLoan();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BorrowerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _activeLoan != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Loan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text('Amount: ₹${_activeLoan!.amount}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('Rate: ${_activeLoan!.interestPercentage}%', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    _buildInstallmentInfo(),
                    const SizedBox(height: 10),
                    Text('Loan Taken Date: ${_activeLoan!.date.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _payInterest,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('Pay Interest'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _settleLoan,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Settle Loan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No active loan', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showLendMoneyDialog,
                        child: const Text('Lend Money'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInstallmentInfo() {
    final now = DateTime.now();
    final isOverdue = _activeLoan!.nextInterestDueDate.isBefore(now);
    final daysBehind = isOverdue ? now.difference(_activeLoan!.nextInterestDueDate).inDays : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interest: ₹${_activeLoan!.interest.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            color: isOverdue ? Colors.red : Colors.black,
            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Text(
              'Next Interest Due: ',
              style: TextStyle(fontSize: 18),
            ),
            Chip(
              label: Text(
                _activeLoan!.nextInterestDueDate.toLocal().toString().split(' ')[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: isOverdue ? Colors.red : Colors.green,
            ),
            if (isOverdue) ...[
              const SizedBox(width: 10),
              Chip(
                label: Text(
                  '$daysBehind days behind',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.red.shade700,
              ),
            ],
          ],
        ),
        if (isOverdue) ...[
          const SizedBox(height: 5),
          Text(
            '$daysBehind days behind',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}