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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Loan History'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DashboardTab(borrower: widget.borrower),
          LoanHistoryTab(borrower: widget.borrower),
          DetailsTab(borrower: widget.borrower),
        ],
      ),
    );
  }
}