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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Picture Section
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: borrower.profilePicturePath != null
                    ? FileImage(File(borrower.profilePicturePath!))
                    : null,
                child: borrower.profilePicturePath == null
                    ? Text(
                        borrower.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Personal Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'Full Name',
                    value: borrower.name,
                    showCopyButton: true,
                  ),

                  const SizedBox(height: 16),

                  // Mobile Number with Communication Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mobile Number',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                borrower.mobileNumber,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.call),
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
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.sms),
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
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.chat),
                                  onPressed: () async {
                                    String cleanNumber = borrower.mobileNumber.replaceAll(RegExp(r'[^\+\d]'), '');
                                    String whatsappNumber;
                                    if (cleanNumber.startsWith('+')) {
                                      whatsappNumber = cleanNumber.substring(1);
                                    } else {
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
                                  tooltip: 'WhatsApp',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366).withOpacity(0.1),
                                    foregroundColor: const Color(0xFF25D366),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bank Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Bank Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildInfoRow(
                    icon: Icons.business,
                    label: 'Bank Name',
                    value: borrower.bankName,
                    showCopyButton: true,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.account_box,
                    label: 'Account Number',
                    value: borrower.accountNumber,
                    showCopyButton: true,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Account Holder',
                    value: borrower.accountHolderName,
                    showCopyButton: true,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Branch Name',
                    value: borrower.branchName,
                    showCopyButton: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool showCopyButton = false,
  }) {
    return Builder(
      builder: (context) => Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showCopyButton)
            IconButton(
              icon: Icon(
                Icons.copy,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              tooltip: 'Copy $label',
            ),
        ],
      ),
    );
  }
}