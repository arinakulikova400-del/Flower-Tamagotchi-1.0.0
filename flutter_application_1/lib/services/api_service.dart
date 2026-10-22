import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  String _token;

  ApiService(this.baseUrl, this._token);

  void setToken(String token) {
    _token = token;
    print('🔑 Токен обновлен: $_token');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token.isNotEmpty) 'Authorization': 'Token $_token',
    };
  }

  // ==================== АВТОРИЗАЦИЯ ====================

  Future<bool> loginUser(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/login/');
      print('🌐 Логин URL: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Ошибка входа: $e');
      return false;
    }
  }

  Future<bool> registerUser(String username, String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/register/');
      print('🌐 Регистрация URL: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Ошибка регистрации: $e');
      return false;
    }
  }

  // ==================== ТИПЫ ЦВЕТОВ (публичные, без токена) ====================

  Future<List<dynamic>> loadFlowerTypes() async {
    try {
      final url = Uri.parse('$baseUrl/api/flower-types/');
      print('🌐 Запрос типов цветов: $url');
      
      final response = await http.get(url);
      
      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки типов цветов: $e');
      return [];
    }
  }

  // ==================== ГОРШКИ (публичные, без токена) ====================

  Future<List<dynamic>> loadPots() async {
    try {
      final url = Uri.parse('$baseUrl/api/pots/');
      print('🌐 Запрос горшков: $url');
      
      final response = await http.get(url);
      
      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки горшков: $e');
      return [];
    }
  }

  // ==================== СТАТИСТИКА ====================

  Future<Map<String, dynamic>?> loadStats() async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/stats/');
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Ошибка загрузки статистики: $e');
      return null;
    }
  }

  // ==================== ЦВЕТЫ ПОЛЬЗОВАТЕЛЯ ====================

  Future<List<dynamic>> loadFlowers() async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/');
      print('📡 Загрузка цветов: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );
      
      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки цветов: $e');
      return [];
    }
  }

  Future<bool> createFlower(int flowerTypeId, int potId, String name) async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/');
      
      int userId = 7;
      
      try {
        final profileUrl = Uri.parse('$baseUrl/api/profile/');
        final profileRes = await http.get(
          profileUrl,
          headers: _getHeaders(),
        );
        
        if (profileRes.statusCode == 200) {
          final data = jsonDecode(profileRes.body);
          if (data is List && data.isNotEmpty) {
            userId = data[0]['user'] ?? 7;
            print('✅ Найден ID пользователя (user): $userId');
          }
        }
      } catch (e) {
        print('⚠️ Ошибка получения ID: $e');
      }
      
      final body = jsonEncode({
        'flower_type': flowerTypeId,
        'pot': potId,
        'name': name,
        'user': userId,
      });
      
      print('📡 Создание цветка: $url');
      print('📦 Тело запроса: $body');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: body,
      );
      
      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Ошибка создания цветка: $e');
      return false;
    }
  }

  Future<bool> waterFlower(int flowerId) async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/$flowerId/water/');
      print('💧 Полив: $url');
      
      final response = await http.post(url, headers: _getHeaders());
      print('📡 Статус: ${response.statusCode}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка полива: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> repotFlower(int flowerId, int newPotId) async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/$flowerId/repot/');
      print('🪴 URL пересадки: $url');
      print('🪴 ID горшка: $newPotId');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'pot_id': newPotId}),
      );

      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'coins': data['coins'] ?? 0,
          'reward': data['reward'] ?? 0,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'status': data['status'] ?? 'error',
          'message': data['message'] ?? 'Ошибка пересадки',
          'seconds_left': data['seconds_left'] ?? 0,
        };
      }
    } catch (e) {
      print('❌ Ошибка пересадки: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> deleteFlower(int flowerId) async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/$flowerId/');
      final response = await http.delete(url, headers: _getHeaders());
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Ошибка удаления: $e');
      return false;
    }
  }

  Future<bool> updateFlowerState(int flowerId) async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/$flowerId/update_state/');
      final response = await http.post(url, headers: _getHeaders());
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка обновления состояния: $e');
      return false;
    }
  }

  // ==================== ПОКУПКА УДОБРЕНИЯ ====================
  Future<Map<String, dynamic>> buyFertilizer(String fertilizerId, int price) async {
    try {
      final url = Uri.parse('$baseUrl/api/flowers/buy_fertilizer/');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'fertilizer_id': fertilizerId,
          'price': price,
        }),
      );
      
      print('📡 Покупка удобрения: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'coins': data['coins'] ?? 0,
        };
      }
      
      return {
        'success': false,
        'error': 'Ошибка покупки: ${response.statusCode}',
      };
    } catch (e) {
      print('❌ Ошибка покупки удобрения: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== ДОСТИЖЕНИЯ ====================

  /// Получить список достижений с сервера + пересчитать прогресс
  Future<List<dynamic>> getAchievements() async {
    try {
      final url = Uri.parse('$baseUrl/api/achievements/');
      print('🏆 Запрос достижений: $url');

      final response = await http.get(url, headers: _getHeaders());

      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки достижений: $e');
      return [];
    }
  }

  /// Забрать награду за достижение
  Future<Map<String, dynamic>> claimAchievement(String achievementId) async {
    try {
      final url = Uri.parse('$baseUrl/api/achievements/claim/');
      print('🏆 Забрать достижение: $achievementId');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'achievement_id': achievementId}),
      );

      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reward': data['reward'] ?? 0,
          'coins': data['coins'] ?? 0,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Ошибка',
        };
      }
    } catch (e) {
      print('❌ Ошибка получения награды: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String?> getToken() async {
    print('🔑 getToken() возвращает: $_token');
    return _token.isNotEmpty ? _token : null;
  }
}