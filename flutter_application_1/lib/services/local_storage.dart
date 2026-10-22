import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранилище игры (без сервера).
/// Всё сохраняется в SharedPreferences телефона.
class LocalStorage {
  // ==================== КЛЮЧИ ====================
  static const String _keyCoins = 'coins';
  static const String _keyUsername = 'username';
  static const String _keyFlower = 'flower';
  static const String _keyAchievements = 'achievements_v2';
  static const String _keyDailyStreak = 'daily_streak';
  static const String _keyLastLoginDate = 'last_login_date';
  static const String _keyFlowerCount = 'flower_count_total';

  static const int startingCoins = 1000;
  static const String defaultUsername = 'Садовод';

  // ==================== ПРОФИЛЬ ====================

  /// Загрузить монеты (при первом запуске — 100)
  static Future<int> loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyCoins)) {
      await prefs.setInt(_keyCoins, startingCoins);
      return startingCoins;
    }
    return prefs.getInt(_keyCoins) ?? startingCoins;
  }

  /// Сохранить монеты
  static Future<void> saveCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, coins);
  }

  /// Имя игрока — всегда "Садовод", но сохраняем на будущее
  static Future<String> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? defaultUsername;
  }

  static Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, name);
  }

  // ==================== ЦВЕТОК ====================

  /// Загрузить цветок (Map) или null, если его нет
  static Future<Map<String, dynamic>?> loadFlower() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFlower);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Сохранить цветок
  static Future<void> saveFlower(Map<String, dynamic> flower) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFlower, jsonEncode(flower));
  }

  /// Удалить цветок
  static Future<void> deleteFlower() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFlower);
  }

  /// Счётчик посаженных цветов (для достижения «Первый цветок»)
  static Future<int> loadFlowerCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFlowerCount) ?? 0;
  }

  static Future<void> incrementFlowerCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyFlowerCount) ?? 0;
    await prefs.setInt(_keyFlowerCount, current + 1);
  }

  // ==================== ДОСТИЖЕНИЯ ====================
  // Формат: { "first_flower": { "isCompleted": bool, "isClaimed": bool, "currentValue": int }, ... }

  static Future<Map<String, dynamic>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAchievements);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveAchievements(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAchievements, jsonEncode(data));
  }

  // ==================== ЕЖЕДНЕВНЫЙ ВХОД ====================

  static Future<int> loadDailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyStreak) ?? 0;
  }

  static Future<void> saveDailyStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyStreak, streak);
  }

  static Future<String?> loadLastLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLoginDate);
  }

  static Future<void> saveLastLoginDate(String isoDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLoginDate, isoDate);
  }

  // ==================== УТИЛИТЫ ====================

  /// Сегодняшняя дата в формате "YYYY-MM-DD"
  static String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Вчерашняя дата в формате "YYYY-MM-DD"
  static String yesterdayString() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  /// Полный сброс (для отладки)
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}