import 'package:flutter/material.dart';

class BillCard extends StatelessWidget {
  final String title;
  final String amount;
  final String due;
  final IconData icon;
  final bool isOverdue;

  const BillCard({
    super.key,
    required this.title,
    required this.amount,
    required this.due,
    this.icon = Icons.receipt_long,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isOverdue ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isOverdue 
                  ? Colors.red.shade100 
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                icon,
                color: isOverdue 
                    ? Colors.red.shade700 
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.error_outline : Icons.schedule,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        due,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOverdue ? Colors.red : Colors.grey.shade700,
                              fontWeight: isOverdue ? FontWeight.w600 : null,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red.shade700 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
