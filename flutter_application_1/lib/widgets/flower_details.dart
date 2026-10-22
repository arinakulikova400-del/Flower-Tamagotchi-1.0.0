import 'package:flutter/material.dart';

class FlowerDetailsSheet extends StatelessWidget {
  final String baseUrl;
  final Map<String, dynamic> flower;
  final Map<String, dynamic>? flowerType;
  final VoidCallback onWater;
  final VoidCallback onRepot;

  const FlowerDetailsSheet({
    super.key,
    required this.baseUrl,
    required this.flower,
    this.flowerType,
    required this.onWater,
    required this.onRepot,
  });

  String _getStageFileName(String stage, String flowerType) {
    switch (stage) {
      case 'seed': return '1.png';
      case 'sprout':
        if (flowerType == 'monstera') return 'mon2.png';
        if (flowerType == 'orchid') return 'or2.png';
        return 'wi2.png';
      case 'growing':
        if (flowerType == 'monstera') return 'mon3.png';
        if (flowerType == 'orchid') return 'or3.png';
        return 'wi3.png';
      case 'mature':
        if (flowerType == 'monstera') return 'mon4.png';
        if (flowerType == 'orchid') return 'or4.png';
        return 'wi4.png';
      case 'flowering':
        if (flowerType == 'monstera') return 'mon5.png';
        if (flowerType == 'orchid') return 'or5.png';
        return 'wi5.png';
      default: return '1.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = flowerType?['type'] ?? 'violet';
    final stage = flower['stage'] ?? 'seed';
    final pot = flower['pot'] as Map?;
    final baseWaterNeeded = flowerType?['base_water_needed'] ?? 50;
    final growthRate = flowerType?['growth_rate'] ?? 1.0;
    final maxHeight = flowerType?['max_height'] ?? 100;
    final description = flowerType?['description'] ?? '';

    final bool hasPot = pot != null && pot['image'] != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (hasPot)
                    Positioned(
                      bottom: 20,
                      child: Image.network(
                        '$baseUrl${pot!['image']}',
                        width: 150,
                        height: 100,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 150,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grass, color: Colors.brown),
                      ),
                    ),
                  Positioned(
                    bottom: 60,
                    child: Image.asset(
                      'assets/plants/$type/${_getStageFileName(stage, type)}',
                      width: 120,
                      height: 120,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_florist,
                        size: 100,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    flowerType?['name'] ?? 'Цветок',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Center(
                  child: Text(
                    _getDisplayName(type),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💧 Потребность в воде', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('$baseWaterNeeded ед/день', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📈 Скорость роста', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('${growthRate.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📏 Макс. высота', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('$maxHeight см', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('📝 Описание', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('❤️ Здоровье', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (flower['health'] ?? 0) / 100,
                            backgroundColor: Colors.grey,
                            color: Colors.red,
                          ),
                          Text('${(flower['health'] ?? 0).toInt()}%', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('💧 Вода', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (flower['water_level'] ?? 0) / 100,
                            backgroundColor: Colors.grey,
                            color: Colors.blue,
                          ),
                          Text('${(flower['water_level'] ?? 0).toInt()}%', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onWater();
                      },
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Полить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onRepot();
                      },
                      icon: const Icon(Icons.grass),
                      label: const Text('Пересадить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String type) {
    switch (type) {
      case 'violet': return 'Сенполия';
      case 'orchid': return 'Фаленопсис';
      case 'monstera': return 'Деликатесная';
      default: return '';
    }
  }
}