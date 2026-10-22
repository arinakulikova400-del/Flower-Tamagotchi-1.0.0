import 'package:flutter/material.dart';
import 'info_chip.dart';
import '../utils/date_formatter.dart';

class BottomInfo extends StatelessWidget {
  final Map<String, dynamic> flower;

  const BottomInfo({
    super.key,
    required this.flower,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = flower['flower_type'] is Map
        ? (flower['flower_type']['max_height'] ?? 100)
        : 100;
    final currentHeight = (flower['height'] ?? 0).toDouble();
    final age = flower['age'] ?? 0;
    final timesWatered = flower['times_watered'] ?? 0;
    final lastWatered = flower['last_watered'] ?? '';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoChip(Icons.height, '${currentHeight.toInt()}/$maxHeight см'),
              InfoChip(Icons.cake, '$age дней'),
              InfoChip(Icons.water_drop, '$timesWatered раз'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Последний полив: ${formatDate(lastWatered)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}