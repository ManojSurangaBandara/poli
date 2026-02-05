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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _activeLoan != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Loan Header
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Active Loan',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Loan Details Card
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount
                            Row(
                              children: [
                                Icon(
                                  Icons.currency_rupee,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${_activeLoan!.amount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Interest Rate
                            Row(
                              children: [
                                Icon(
                                  Icons.percent,
                                  color: Theme.of(context).colorScheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Interest Rate: ${_activeLoan!.interestPercentage}%',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Loan Date
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.outline,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loan Date: ${_activeLoan!.date.toLocal().toString().split(' ')[0]}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Installment Info
                            _buildInstallmentInfo(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _payInterest,
                            icon: const Icon(Icons.payment),
                            label: const Text('Collect Interest'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _settleLoan,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Settle Loan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Active Loan',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by lending money to this borrower',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _showLendMoneyDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Lend Money'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Theme.of(context).colorScheme.error.withOpacity(0.5)
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interest Amount
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Interest Due: ₹${_activeLoan!.interest.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Due Date
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).colorScheme.outline,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Due Date:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _activeLoan!.nextInterestDueDate.toLocal().toString().split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          // Overdue Status
          if (isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$daysBehind days overdue',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}