/// Formats a concise message about unpaid and overdue bills
String formatConciseBillsMessage({
  required int unpaid,
  required int overdue,
  required int totalToPay,
}) {
  if (totalToPay == 0) {
    return 'All bills are paid up!';
  }

  final List<String> parts = [];

  if (overdue > 0) {
    parts.add('$overdue overdue');
  }

  if (unpaid > 0) {
    parts.add('$unpaid unpaid');
  }

  if (parts.isEmpty) {
    return 'All bills are paid up!';
  }

  return 'You have ${parts.join(' and ')} bill${totalToPay == 1 ? '' : 's'}.';
}