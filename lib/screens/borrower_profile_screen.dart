import 'dart:io';
import 'package:flutter/material.dart';
import '../models/borrower.dart';

class BorrowerProfileScreen extends StatelessWidget {
  final Borrower borrower;

  const BorrowerProfileScreen({super.key, required this.borrower});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(borrower.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: borrower.profilePicturePath != null
                    ? FileImage(File(borrower.profilePicturePath!))
                    : null,
                child: borrower.profilePicturePath == null
                    ? Text(borrower.name[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text('Name: ${borrower.name}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Mobile: ${borrower.mobileNumber}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Bank Name: ${borrower.bankName}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Account Number: ${borrower.accountNumber}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Account Holder Name: ${borrower.accountHolderName}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Branch Name: ${borrower.branchName}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}