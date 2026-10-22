import 'package:flutter/material.dart';

class FlowerCard extends StatelessWidget {
  final String baseUrl;
  final Map<String, dynamic> flower;
  final VoidCallback onTap;

  const FlowerCard({
    super.key,
    required this.baseUrl,
    required this.flower,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flowerType = flower['flower_type'] as Map? ?? {};
    final stage = flower['stage'] ?? 'seed';
    final pot = flower['pot'] as Map?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (pot != null && pot['image'] != null)
              Positioned(
                bottom: 10,
                child: Image.network(
                  '$baseUrl${pot['image']}',
                  width: 60,
                  height: 40,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            Positioned(
              bottom: 30,
              child: Image.asset(
                'assets/plants/${flowerType['type'] ?? 'violet'}/$stage.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, size: 40, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}