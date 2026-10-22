String formatDate(String dateStr) {
  if (dateStr.isEmpty) return 'никогда';
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) return 'только что';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    return '${diff.inDays} д назад';
  } catch (e) {
    return dateStr;
  }
}