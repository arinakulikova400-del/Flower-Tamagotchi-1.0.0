class FlowerModel {
  final int id;
  final String name;
  final int health;
  final int waterLevel;
  final double height;
  final int age;
  final String stage;
  final int timesWatered;
  final String lastWatered;
  final Map<String, dynamic>? flowerType;
  final Map<String, dynamic>? pot;

  FlowerModel({
    required this.id,
    required this.name,
    required this.health,
    required this.waterLevel,
    required this.height,
    required this.age,
    required this.stage,
    required this.timesWatered,
    required this.lastWatered,
    this.flowerType,
    this.pot,
  });

  factory FlowerModel.fromJson(Map<String, dynamic> json) {
    return FlowerModel(
      id: json['id'],
      name: json['name'] ?? 'Без имени',
      health: json['health'] ?? 100,
      waterLevel: json['water_level'] ?? 50,
      height: (json['height'] ?? 5.0).toDouble(),
      age: json['age'] ?? 0,
      stage: json['stage'] ?? 'seed',
      timesWatered: json['times_watered'] ?? 0,
      lastWatered: json['last_watered'] ?? '',
      flowerType: json['flower_type'],
      pot: json['pot'],
    );
  }
}