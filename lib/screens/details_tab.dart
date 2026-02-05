import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/borrower.dart';

class DetailsTab extends StatelessWidget {
  final Borrower borrower;

  const DetailsTab({super.key, required this.borrower});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
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
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
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
                  child: Text(
                    'Mobile: ${borrower.mobileNumber}',
                    style: const TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sms, color: Colors.green),
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
              IconButton(
                icon: const Icon(Icons.message, color: Colors.green), // WhatsApp-like icon
                onPressed: () async {
                  String cleanNumber = borrower.mobileNumber.replaceAll(RegExp(r'[^\+\d]'), '');
                  // Ensure number has country code for WhatsApp
                  String whatsappNumber;
                  if (cleanNumber.startsWith('+')) {
                    // Already has country code, remove + for WhatsApp URL
                    whatsappNumber = cleanNumber.substring(1);
                  } else {
                    // Add Sri Lanka country code (+94)
                    whatsappNumber = '94$cleanNumber';
                  }
                  final Uri whatsappUri = Uri.parse('https://wa.me/$whatsappNumber');
                  try {
                    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open WhatsApp: $e')),
                    );
                  }
                },
                tooltip: 'Send WhatsApp message',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Bank Name: ${borrower.bankName}', style: const TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: borrower.bankName));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bank name copied to clipboard')),
                  );
                },
                tooltip: 'Copy bank name',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Account Number: ${borrower.accountNumber}', style: const TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: borrower.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account number copied to clipboard')),
                  );
                },
                tooltip: 'Copy account number',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Account Holder Name: ${borrower.accountHolderName}', style: const TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: borrower.accountHolderName));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account holder name copied to clipboard')),
                  );
                },
                tooltip: 'Copy account holder name',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Branch Name: ${borrower.branchName}', style: const TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: borrower.branchName));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Branch name copied to clipboard')),
                  );
                },
                tooltip: 'Copy branch name',
              ),
            ],
          ),
        ],
      ),
    );
  }
}