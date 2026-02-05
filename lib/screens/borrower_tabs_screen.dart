import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../providers/borrower_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.borrower.name),
        elevation: 0,
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