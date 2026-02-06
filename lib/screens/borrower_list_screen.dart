import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/borrower.dart';
import '../services/local_storage_service.dart';
import '../providers/borrower_provider.dart';
import '../providers/theme_provider.dart';
import 'borrower_tabs_screen.dart';
import 'add_borrower_screen.dart';

class BorrowerListScreen extends StatefulWidget {
  const BorrowerListScreen({super.key});

  @override
  _BorrowerListScreenState createState() => _BorrowerListScreenState();
}

class _BorrowerListScreenState extends State<BorrowerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Borrower> _filteredBorrowers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = Provider.of<BorrowerProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBorrowers = provider.borrowers;
      } else {
        _filteredBorrowers = provider.borrowers.where((borrower) {
          return borrower.name.toLowerCase().contains(query) ||
                 borrower.mobileNumber.toLowerCase().contains(query) ||
                 borrower.bankName.toLowerCase().contains(query) ||
                 borrower.accountHolderName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredBorrowers = Provider.of<BorrowerProvider>(context, listen: false).borrowers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search borrowers...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(179, 17, 14, 14),
                    fontSize: 18,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Color.fromARGB(255, 92, 67, 67),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: const Color.fromARGB(255, 97, 86, 86),
              )
            : const Text('Borrowers'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _stopSearch,
              tooltip: 'Stop search',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
              tooltip: 'Search borrowers',
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                  tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                );
              },
            ),
          ],
        ],
      ),
      body: Consumer<BorrowerProvider>(
        builder: (context, provider, child) {
          // Initialize filtered borrowers if not searching
          if (!_isSearching) {
            _filteredBorrowers = provider.borrowers;
          }

          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading borrowers...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          if (_filteredBorrowers.isEmpty && !_isSearching) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No borrowers yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first borrower to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddBorrowerScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Borrower'),
                  ),
                ],
              ),
            );
          }
          if (_filteredBorrowers.isEmpty && _isSearching) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No borrowers found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _stopSearch,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Search'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              itemCount: _filteredBorrowers.length,
              itemBuilder: (context, index) {
                Borrower borrower = _filteredBorrowers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Hero(
                      tag: 'borrower-avatar-${borrower.id}',
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: borrower.profilePicturePath != null
                            ? FileImage(File(borrower.profilePicturePath!))
                            : null,
                        child: borrower.profilePicturePath == null
                            ? Text(
                                borrower.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    title: Text(
                      borrower.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              borrower.mobileNumber,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.account_balance, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                borrower.bankName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                          onPressed: () async {
                            String cleanNumber = borrower.mobileNumber.replaceAll(RegExp(r'[^\+\d]'), '');
                            final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
                            try {
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not launch phone dialer: $e')),
                              );
                            }
                          },
                          tooltip: 'Call',
                        ),
                        IconButton(
                          icon: Icon(Icons.message, color: Theme.of(context).colorScheme.primary),
                          onPressed: () async {
                            String cleanNumber = borrower.mobileNumber.replaceAll(RegExp(r'[^\+\d]'), '');
                            final Uri smsUri = Uri(scheme: 'sms', path: cleanNumber);
                            try {
                              if (await canLaunchUrl(smsUri)) {
                                await launchUrl(smsUri);
                              } else {
                                await launchUrl(smsUri, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not launch SMS app: $e')),
                              );
                            }
                          },
                          tooltip: 'Send SMS',
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BorrowerTabsScreen(borrower: borrower),
                        ),
                      );
                    },
                    onLongPress: () async {
                      String cleanNumber = borrower.mobileNumber.replaceAll(RegExp(r'[^\+\d]'), '');
                      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
                      try {
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch phone dialer: $e')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBorrowerScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Borrower'),
        elevation: 4,
      ),
    );
  }
}