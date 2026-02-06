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

class _DashboardTabState extends State<DashboardTab> with TickerProviderStateMixin {
  Loan? _activeLoan;
  bool _isCollectingInterest = false;

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
    setState(() {
      _isCollectingInterest = true;
    });

    // Show the animated collection dialog
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _InterestCollectionAnimation(
          interestAmount: _activeLoan!.interest,
          onComplete: () async {
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
            return updatedLoan.nextInterestDueDate;
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
    );

    _loadActiveLoan();
    setState(() {
      _isCollectingInterest = false;
    });
  }

  Future<void> _settleLoan() async {
    // Show confirmation dialog
    final shouldSettle = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Loan Settlement'),
          content: Text(
            'Are you sure you want to settle this loan of රු. ${_activeLoan!.amount.toStringAsFixed(2)}? '
            'This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Settle Loan'),
            ),
          ],
        );
      },
    );

    if (shouldSettle != true) return;

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

    // Show success alert
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Loan Settled'),
          content: const Text('The loan has been successfully settled.'),
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
                                  Icons.currency_exchange,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'රු. ${_activeLoan!.amount.toStringAsFixed(2)}',
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
                'Interest Due: රු. ${_activeLoan!.interest.toStringAsFixed(2)}',
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

// Animated Interest Collection Dialog
class _InterestCollectionAnimation extends StatefulWidget {
  final double interestAmount;
  final Future<DateTime> Function() onComplete;

  const _InterestCollectionAnimation({
    required this.interestAmount,
    required this.onComplete,
  });

  @override
  State<_InterestCollectionAnimation> createState() => _InterestCollectionAnimationState();
}

class _InterestCollectionAnimationState extends State<_InterestCollectionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _coinController;
  late AnimationController _checkController;
  late AnimationController _countController;
  late Animation<double> _coinAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _countAnimation;
  
  bool _showCheck = false;
  bool _completed = false;
  DateTime? _nextDueDate;

  @override
  void initState() {
    super.initState();
    
    // Coin falling animation
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _coinAnimation = CurvedAnimation(
      parent: _coinController,
      curve: Curves.bounceOut,
    );
    
    // Check mark animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    
    // Count up animation
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOut,
    );
    
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Start coin animation
    _coinController.forward();
    _countController.forward();
    
    // Wait for coin to land
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Process the payment
    _nextDueDate = await widget.onComplete();
    
    // Show check mark
    setState(() {
      _showCheck = true;
    });
    _checkController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    setState(() {
      _completed = true;
    });
  }

  @override
  void dispose() {
    _coinController.dispose();
    _checkController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated coin/money icon
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.secondaryContainer,
                          ],
                        ),
                      ),
                    ),
                    // Animated coin
                    AnimatedBuilder(
                      animation: _coinAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -50 * (1 - _coinAnimation.value)),
                          child: Transform.rotate(
                            angle: _coinAnimation.value * 2 * 3.14159,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'රු.',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Check mark overlay
                    if (_showCheck)
                      ScaleTransition(
                        scale: _checkAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.9),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Animated amount counter
              AnimatedBuilder(
                animation: _countAnimation,
                builder: (context, child) {
                  final value = widget.interestAmount * _countAnimation.value;
                  return Text(
                    'රු. ${value.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _completed
                    ? Column(
                        children: [
                          Text(
                            'Interest Collected!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Next due: ${_nextDueDate?.toLocal().toString().split(' ')[0] ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Collecting interest...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Close button (only after completion)
              AnimatedOpacity(
                opacity: _completed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FilledButton.icon(
                  onPressed: _completed ? () => Navigator.of(context).pop(true) : null,
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}