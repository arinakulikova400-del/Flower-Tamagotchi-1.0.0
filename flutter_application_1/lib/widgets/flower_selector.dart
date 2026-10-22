import 'package:flutter/material.dart';

class FlowerSelector extends StatelessWidget {
  final List<dynamic> flowerTypes;
  final Function(int) onFlowerSelected;
  final VoidCallback onCancel;

  const FlowerSelector({
    super.key,
    required this.flowerTypes,
    required this.onFlowerSelected,
    required this.onCancel,
  });

  String _getFlowerDisplayName(String? type) {
    switch (type) {
      case 'violet': return 'Фиалка Сенполия';
      case 'orchid': return 'Орхидея Фаленопсис';
      case 'monstera': return 'Монстера Деликатесная';
      default: return 'Цветок';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.7),
          child: GestureDetector(
            onTap: onCancel,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Выберите цветок',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: flowerTypes.map((type) {
                    return GestureDetector(
                      onTap: () => onFlowerSelected(type['id']),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.local_florist, size: 50, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getFlowerDisplayName(type['type']),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 1, 1, 0)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}