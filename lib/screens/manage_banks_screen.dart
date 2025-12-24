import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bank_model.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../data/mock_data.dart';

class ManageBanksScreen extends StatefulWidget {
  const ManageBanksScreen({super.key});

  @override
  State<ManageBanksScreen> createState() => _ManageBanksScreenState();
}

class _ManageBanksScreenState extends State<ManageBanksScreen> {
  final List<String> _banks = [
    'Maybank',
    'CIMB Bank',
    'Public Bank',
    'RHB Bank',
    'Hong Leong Bank',
  ];

  void _showBankForm({BankModel? bank}) {
    final isEdit = bank != null;
    final _formKey = GlobalKey<FormState>();
    String selectedBank = bank?.bankName ?? _banks.first;
    final accountNameController = TextEditingController(text: bank?.accountName ?? '');
    final accountNumberController = TextEditingController(text: bank?.accountNumber ?? '');
    final userAccountNumberController = TextEditingController(text: bank?.userAccountNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEdit ? 'Edit Bank' : 'Add Bank', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) => selectedBank = v ?? _banks.first,
                    decoration: const InputDecoration(labelText: 'Bank', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountNameController,
                    decoration: const InputDecoration(labelText: 'Account Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter account name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter account number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: userAccountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Your Account Number', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your account number' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final appProvider = context.read<AppProvider>();
                            final user = appProvider.currentUser ?? MockData.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not available')));
                              return;
                            }

                            try {
                              if (isEdit) {
                                await FirestoreService.updateBank(bank.id, {
                                  'bankName': selectedBank,
                                  'accountName': accountNameController.text.trim(),
                                  'accountNumber': accountNumberController.text.trim(),
                                  'userAccountNumber': userAccountNumberController.text.trim(),
                                });
                              } else {
                                await FirestoreService.createBank({
                                  'userId': user.id,
                                  'bankName': selectedBank,
                                  'accountName': accountNameController.text.trim(),
                                  'accountNumber': accountNumberController.text.trim(),
                                  'userAccountNumber': userAccountNumberController.text.trim(),
                                  'createdAt': DateTime.now(),
                                });
                              }
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          },
                          child: Text(isEdit ? 'Save' : 'Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String bankId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Bank'),
        content: const Text('Are you sure you want to remove this bank account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService.deleteBank(bankId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.currentUser ?? MockData.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payment Methods'),
      ),
      body: StreamBuilder<List<BankModel>>(
        stream: FirestoreService.getUserBanksStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final banks = snapshot.data ?? [];
          if (banks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No bank accounts added yet.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _showBankForm(),
                    child: const Text('Add Bank Account'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: banks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = banks[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  title: Text(b.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Name: ${b.accountName}'),
                      const SizedBox(height: 4),
                      Text('Account No: ${b.accountNumber}'),
                      const SizedBox(height: 4),
                      Text('Your Account No: ${b.userAccountNumber}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showBankForm(bank: b),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(b.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


