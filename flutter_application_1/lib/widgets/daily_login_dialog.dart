import 'package:flutter/material.dart';

class DailyLoginDialog extends StatelessWidget {
  final int streak;
  final int reward;
  final VoidCallback onClaim;

  const DailyLoginDialog({
    super.key,
    required this.streak,
    required this.reward,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            // 👇 ОБЩАЯ ПЛАШКА — прозрачнее
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================== ЗАГОЛОВОК ====================
              const Text(
                'Ежедневный вход',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'День $streak подряд',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 14),

              // ==================== ТРИ МОНЕТКИ ====================
              SizedBox(
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 55,
                      top: 22,
                      child: Image.asset(
                        'assets/images/achievements/coins.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on,
                          size: 32,
                          color: Color(0xFFD4A54A),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 25,
                      top: 22,
                      child: Image.asset(
                        'assets/images/coins.png',
                        width: 52,
                        height: 52,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on,
                          size: 32,
                          color: Color(0xFFD4A54A),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: Image.asset(
                        'assets/images/coins.png',
                        width: 76,
                        height: 76,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on,
                          size: 56,
                          color: Color(0xFFE6B84C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ==================== СКОЛЬКО ПОЛУЧАЕШЬ ====================
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  // прозрачнее
                  color: Color.fromARGB(255, 133, 113, 94),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/coins.png',
                      width: 30,
                      height: 30,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.monetization_on,
                        size: 30,
                        color: Color(0xFFD4A54A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+$reward',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==================== КНОПКА ПОЛУЧИТЬ ====================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 56, 103, 58),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                    shadowColor: const Color.fromARGB(255, 56, 103, 58)
                        .withOpacity(0.5),
                  ),
                  child: const Text(
                    'Получить',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}