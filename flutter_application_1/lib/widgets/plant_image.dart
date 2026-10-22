import 'package:flutter/material.dart';

class PlantImage extends StatelessWidget {
  final String baseUrl;
  final Map<String, dynamic> flower;

  const PlantImage({
    super.key,
    required this.baseUrl,
    required this.flower,
  });

  @override
  Widget build(BuildContext context) {
    final flowerType = flower['flower_type'] is Map
        ? flower['flower_type']['type']
        : 'violet';
    final stage = flower['stage'] ?? 'seed';
    final pot = flower['pot'] is Map ? flower['pot'] : null;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (pot != null && pot['image'] != null)
            Positioned(
              bottom: 0,
              child: Image.network(
                '$baseUrl${pot['image']}',
                width: 120,
                height: 80,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Positioned(
            bottom: 40,
            child: Image.asset(
              'assets/plants/$flowerType/$stage.png',
              width: 100,
              height: 100,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_florist,
                size: 80,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}