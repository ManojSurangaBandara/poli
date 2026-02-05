import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../providers/borrower_provider.dart';

class LoanHistoryTab extends StatefulWidget {
  final Borrower borrower;

  const LoanHistoryTab({super.key, required this.borrower});

  @override
  _LoanHistoryTabState createState() => _LoanHistoryTabState();
}

class _LoanHistoryTabState extends State<LoanHistoryTab> {
  List<Loan> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    final provider = Provider.of<BorrowerProvider>(context, listen: false);
    List<Loan> allLoans = await provider.getLoansForBorrower(widget.borrower.id);
    // Filter out active loans, only show completed/repaid loans
    _loans = allLoans.where((loan) => loan.status == 'repaid').toList();
    setState(() {});
  }

  int _calculateMonthsPaid(Loan loan) {
    final endDate = loan.repaidDate ?? DateTime.now();
    final difference = endDate.difference(loan.date);
    return (difference.inDays / 30).round(); // Approximate months
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BorrowerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loans.isEmpty
              ? const Center(
                  child: Text('No loan history', style: TextStyle(fontSize: 18)),
                )
              : ListView.builder(
                  itemCount: _loans.length,
                  itemBuilder: (context, index) {
                    final loan = _loans[index];
                    final isActive = loan.status == 'active';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text('Amount: ₹${loan.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${loan.date.toLocal().toString().split(' ')[0]}'),
                            Text('Interest Rate: ${loan.interestPercentage}%'),
                            Text('Monthly Interest: ₹${loan.interest.toStringAsFixed(2)}'),
                            Text('Status: ${loan.status}', style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                            if (!isActive && loan.repaidDate != null) Text('Repaid Date: ${loan.repaidDate!.toLocal().toString().split(' ')[0]}'),
                            if (!isActive) ...[
                              Text('Interest Paid Months: ${_calculateMonthsPaid(loan)}'),
                              Text('Total Interest Paid: ₹${(_calculateMonthsPaid(loan) * loan.interest).toStringAsFixed(2)}'),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}