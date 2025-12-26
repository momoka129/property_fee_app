import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

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
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 12,
      opacity: isOverdue ? 0.85 : 0.6,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.shade100 : Theme.of(context).colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isOverdue ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
              size: 20,
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
                        fontWeight: FontWeight.w700,
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
                    const SizedBox(width: 6),
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
                  color: isOverdue ? Colors.red.shade700 : Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}
