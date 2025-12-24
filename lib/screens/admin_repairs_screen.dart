import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/repair_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AdminRepairsScreen extends StatefulWidget {
  const AdminRepairsScreen({super.key});

  @override
  State<AdminRepairsScreen> createState() => _AdminRepairsScreenState();
}

class _AdminRepairsScreenState extends State<AdminRepairsScreen> {

  Future<void> _updateRepairStatus(String repairId, String newStatus) async {
    try {
      DateTime? completedAt;
      if (newStatus == 'completed') {
        completedAt = DateTime.now();
      }
      await FirestoreService.updateRepairStatus(repairId, newStatus, completedAt: completedAt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repairs (Admin)'),
      ),
      body: StreamBuilder<List<RepairModel>>(
        stream: FirestoreService.getAllRepairsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final repairs = snapshot.data ?? [];
          if (repairs.isEmpty) {
            return const Center(child: Text('No repairs'));
          }

          return FutureBuilder<List<UserModel>>(
            future: FirestoreService.getUsers(),
            builder: (context, usersSnapshot) {
              final users = usersSnapshot.data ?? [];
              final Map<String, UserModel> userById = {
                for (var u in users) u.id: u
              };

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: repairs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final repair = repairs[index];
                  final linkedUser = userById[repair.userId];
                  final displayName = linkedUser?.name ?? 'Unknown User';
                  final displayAddress = linkedUser?.propertySimpleAddress ?? 'Unknown Unit';

                  Color statusColor;
                  switch (repair.status) {
                    case 'completed':
                      statusColor = Colors.green;
                      break;
                    case 'in_progress':
                      statusColor = Colors.blue;
                      break;
                    default:
                      statusColor = Colors.orange;
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      repair.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submitted by: $displayName ($displayAddress)',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Location: ${repair.location}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Priority: ${repair.priorityDisplay}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Created: ${DateFormat('MMM dd, yyyy').format(repair.createdAt)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (repair.completedAt != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Completed: ${DateFormat('MMM dd, yyyy').format(repair.completedAt!)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  repair.statusDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (repair.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              repair.description,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: repair.status,
                                  items: const [
                                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null && value != repair.status) {
                                      _updateRepairStatus(repair.id, value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
