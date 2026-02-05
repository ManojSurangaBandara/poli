import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/borrower.dart';
import '../services/local_storage_service.dart';
import '../providers/borrower_provider.dart';
import 'borrower_tabs_screen.dart';
import 'add_borrower_screen.dart';

class BorrowerListScreen extends StatelessWidget {
  const BorrowerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Consumer<BorrowerProvider>(
        builder: (context, provider, child) {
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
          if (provider.borrowers.isEmpty) {
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              itemCount: provider.borrowers.length,
              itemBuilder: (context, index) {
                Borrower borrower = provider.borrowers[index];
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