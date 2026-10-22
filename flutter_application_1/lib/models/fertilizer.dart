import 'package:flutter/material.dart';

class Fertilizer {
  final String id;
  final String name;
  final String description;
  final int price;
  final double growthBonus;
  final IconData icon;
  final Color color;

  Fertilizer({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.growthBonus,
    required this.icon,
    required this.color,
  });
}

// Список всех удобрений
final List<Fertilizer> allFertilizers = [
  Fertilizer(
    id: 'basic',
    name: 'Мочевина',
    description: '+5% к росту', // 👈 Убрали "на 1 час"
    price: 4,
    growthBonus: 1.05,
    icon: Icons.eco,
    color: const Color.fromARGB(255, 72, 129, 74),
  ),
  Fertilizer(
    id: 'advanced',
    name: 'Аммиачная селитра',
    description: '+10% к росту', // 👈 Убрали "на 1 час"
    price: 9,
    growthBonus: 1.10,
    icon: Icons.grass,
    color: const Color.fromARGB(255, 36, 106, 99),
  ),
  Fertilizer(
    id: 'premium',
    name: 'Двойной суперфосфат',
    description: '+15% к росту', // 👈 Убрали "на 1 час"
    price: 14,
    growthBonus: 1.15,
    icon: Icons.spa,
    color: const Color.fromARGB(255, 107, 44, 118),
  ),
];