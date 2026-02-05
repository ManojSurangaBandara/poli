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
      ),
      body: Consumer<BorrowerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.borrowers.isEmpty) {
            return const Center(child: Text('No borrowers yet. Add one!'));
          }
          return ListView.builder(
            itemCount: provider.borrowers.length,
            itemBuilder: (context, index) {
              Borrower borrower = provider.borrowers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: borrower.profilePicturePath != null
                      ? FileImage(File(borrower.profilePicturePath!))
                      : null,
                  child: borrower.profilePicturePath == null
                      ? Text(borrower.name[0].toUpperCase())
                      : null,
                ),
                title: Text(borrower.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BorrowerTabsScreen(borrower: borrower),
                    ),
                  );
                },
                onLongPress: () async {
                  // Clean the phone number by removing spaces, dashes, etc., but keep the + sign
                  String cleanNumber = borrower.mobileNumber.replaceAll(RegExp(r'[^\+\d]'), '');
                  final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
                  try {
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      // Try without canLaunchUrl check as a fallback
                      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    // Handle error - could show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch phone dialer: $e')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBorrowerScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}