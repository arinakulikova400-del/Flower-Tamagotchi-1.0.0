import 'package:flutter/material.dart';

class PotSelector extends StatelessWidget {
  final String baseUrl;
  final List<dynamic> pots;
  final int? selectedPotId;
  final Function(int) onPotSelected;
  final VoidCallback onCancel;

  const PotSelector({
    super.key,
    required this.baseUrl,
    required this.pots,
    this.selectedPotId,
    required this.onPotSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              'Выберите горшок',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D3A1A)),
            ),
            const SizedBox(height: 20),
            
            // 👇 ГОРИЗОНТАЛЬНАЯ ПРОКРУТКА, ЧТОБЫ НЕ ПЕРЕНОСИЛИСЬ
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: pots.map((pot) {
                  final isSelected = selectedPotId == pot['id'];

                  String imagePath = '';
                  if (pot['image'] != null && pot['image'].toString().isNotEmpty) {
                    String img = pot['image'].toString();
                    if (img.startsWith('assets/')) {
                      imagePath = img;
                    } else if (img.startsWith('media/')) {
                      imagePath = 'assets/pots/${img.split('/').last}';
                    } else if (!img.startsWith('http') && !img.contains('/')) {
                      imagePath = 'assets/pots/$img';
                    } else if (img.startsWith('http')) {
                      imagePath = 'assets/pots/${img.split('/').last}';
                    }
                  }

                  return GestureDetector(
                    onTap: () => onPotSelected(pot['id']),
                    child: Container(
                      width: 80, // 👈 Сделали чуть уже
                      margin: const EdgeInsets.only(right: 12), // Отступ между горшками
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: imagePath.isNotEmpty
                                  ? Image.asset(
                                      imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.brown.withOpacity(0.3),
                                          child: const Icon(Icons.grass, size: 30, color: Colors.brown),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.brown.withOpacity(0.3),
                                      child: const Icon(Icons.grass, size: 30, color: Colors.brown),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 👇 НАЗВАНИЕ ЗАКОММЕНТИРОВАНО
                          /*
                          Text(
                            _getRussianColor(pot['color'] ?? 'Горшок'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.green : Colors.brown,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          */
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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
    );
  }

  String _getRussianColor(String color) {
    switch (color.toLowerCase()) {
      case 'brown': return 'Коричневый';
      case 'yellow': return 'Жёлтый';
      case 'pink': return 'Розовый';
      default: return color;
    }
  }
}