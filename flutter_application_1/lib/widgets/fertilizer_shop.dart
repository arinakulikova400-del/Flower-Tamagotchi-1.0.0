import 'package:flutter/material.dart';
import '../models/fertilizer.dart';

class FertilizerShop extends StatelessWidget {
  final int userCoins;
  final Function(Fertilizer) onBuy;
  final VoidCallback onCancel;

  const FertilizerShop({
    super.key,
    required this.userCoins,
    required this.onBuy,
    required this.onCancel,
  });

  String _getFertImage(Fertilizer fert) {
    switch (fert.id) {
      case 'basic':
        return 'assets/images/fertilizers/flo.png';
      case 'advanced':
        return 'assets/images/fertilizers/flo2.png';
      case 'premium':
        return 'assets/images/fertilizers/flo3.png';
      default:
        return 'assets/images/fertilizers/flo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==================== ЗАГОЛОВОК (ИСПРАВЛЕН) ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Центрируем всё вместе
            children: [
              const Flexible(
                child: Text(
                  'Магазин удобрений',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D3A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // 👇 СКОШЕННАЯ ПЛАШКА С МОНЕТКАМИ (ТЕПЕРЬ РЯДОМ)
              ClipPath(
                clipper: _SkewedBadgeClipper(cut: 12),
                child: Container(
                  padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                  color: const Color(0xFFBDBDBD), // Серый, как в достижениях
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/coins.png',
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$userCoins',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ==================== ЛЕНТА УДОБРЕНИЙ ====================
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: allFertilizers.length,
              itemBuilder: (context, index) {
                final fert = allFertilizers[index];
                final canAfford = userCoins >= fert.price;

                return GestureDetector(
                  onTap: canAfford ? () => onBuy(fert) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: canAfford ? fert.color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: canAfford ? fert.color : Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ЦВЕТНОЙ ФОН ПОД КАРТИНКОЙ
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: fert.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              _getFertImage(fert),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  fert.icon,
                                  color: canAfford ? fert.color : Colors.grey,
                                  size: 40,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fert.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? Colors.black87 : Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fert.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: canAfford ? Colors.black87 : Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/coins.png',
                              width: 16,
                              height: 16,
                              color: canAfford ? null : Colors.grey,
                              errorBuilder: (_, __, ___) => Icon(Icons.monetization_on, size: 16, color: canAfford ? Colors.amber : Colors.grey),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${fert.price}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: canAfford ? Colors.black87 : Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Закрыть', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==================== КЛИПЕР ДЛЯ СКОШЕННОЙ ПЛАШКИ ====================
class _SkewedBadgeClipper extends CustomClipper<Path> {
  final double cut;
  _SkewedBadgeClipper({this.cut = 12});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final c = cut;
    return Path()
      ..moveTo(c, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}