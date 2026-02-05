import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/local_storage_service.dart';
import '../providers/borrower_provider.dart';
import 'borrower_profile_screen.dart';
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
                      builder: (context) => BorrowerProfileScreen(borrower: borrower),
                    ),
                  );
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