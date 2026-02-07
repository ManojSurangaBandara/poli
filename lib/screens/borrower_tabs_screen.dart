import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../providers/borrower_provider.dart';
import '../providers/undo_provider.dart';
import 'dashboard_tab.dart';
import 'loan_history_tab.dart';
import 'details_tab.dart';

class BorrowerTabsScreen extends StatefulWidget {
  final Borrower borrower;

  const BorrowerTabsScreen({super.key, required this.borrower});

  @override
  _BorrowerTabsScreenState createState() => _BorrowerTabsScreenState();
}

class _BorrowerTabsScreenState extends State<BorrowerTabsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUndoDialog(BuildContext context, UndoProvider undoProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.undo,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Undo Action'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to undo the following action?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  undoProvider.getActionDescription(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => _performUndo(context, undoProvider),
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
          ],
        );
      },
    );
  }

  void _performUndo(BuildContext context, UndoProvider undoProvider) async {
    if (undoProvider.lastAction == null) return;

    final borrowerProvider = Provider.of<BorrowerProvider>(context, listen: false);

    try {
      await undoProvider.undo(borrowerProvider);
      Navigator.of(context).pop(); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Action undone successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to undo action: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.borrower.name),
        elevation: 0,
        actions: [
          Consumer<UndoProvider>(
            builder: (context, undoProvider, child) {
              return IconButton(
                icon: const Icon(Icons.undo),
                onPressed: undoProvider.canUndo ? () => _showUndoDialog(context, undoProvider) : null,
                tooltip: undoProvider.canUndo ? 'Undo ${undoProvider.getActionDescription()}' : 'No action to undo',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard),
                  text: 'Dashboard',
                ),
                Tab(
                  icon: Icon(Icons.history),
                  text: 'History',
                ),
                Tab(
                  icon: Icon(Icons.person),
                  text: 'Details',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: TabBarView(
          controller: _tabController,
          children: [
            DashboardTab(borrower: widget.borrower),
            LoanHistoryTab(borrower: widget.borrower),
            DetailsTab(borrower: widget.borrower),
          ],
        ),
      ),
    );
  }
}