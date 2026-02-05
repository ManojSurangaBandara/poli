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
        return _loans.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Loan History',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed loans will appear here',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _loans.length,
                itemBuilder: (context, index) {
                  final loan = _loans[index];
                  final monthsPaid = _calculateMonthsPaid(loan);
                  final totalInterestPaid = monthsPaid * loan.interest;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with amount and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.currency_rupee,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${loan.amount.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Repaid',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Loan Details Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.calendar_today,
                                  label: 'Loan Date',
                                  value: loan.date.toLocal().toString().split(' ')[0],
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.percent,
                                  label: 'Interest Rate',
                                  value: '${loan.interestPercentage}%',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.payments,
                                  label: 'Monthly Interest',
                                  value: '₹${loan.interest.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.event_available,
                                  label: 'Repaid Date',
                                  value: loan.repaidDate?.toLocal().toString().split(' ')[0] ?? 'N/A',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Summary Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Months Paid:',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '$monthsPaid',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Interest Paid:',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '₹${totalInterestPaid.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}