import 'dart:async';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'services/local_storage.dart';
import 'widgets/daily_login_dialog.dart';
import 'widgets/flower_selector.dart';
import 'widgets/pot_selector.dart';
import 'models/fertilizer.dart';
import 'widgets/fertilizer_shop.dart';
import 'widgets/shop_button.dart';
import 'widgets/coin_counter.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Цветочный Тамагочи',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF1A2A1A),
      ),
      home: const GardenScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int _coins = 1000;
  String _playerName = 'Садовод';

  bool _showLottie = false;
  bool _showJoyLottie = false;
  bool _showImage = false;
  bool _showFertilizerShop = false;

  Map<String, dynamic>? _flower;
  Map<String, dynamic>? _flowerType;
  Map<String, dynamic>? _flowerPot;
  int _needWaterCount = 0;
  bool _isLoading = true;
  bool _showFlowerSelector = false;
  bool _showProfileDialog = false;

  String? _fertilizerNotification;
  String? _fertilizerImagePath;
  bool _showFertilizerNotification = false;

  int _dailyStreak = 0;
  int _dailyReward = 0;
  bool _showDailyLoginDialog = false;

  List<dynamic> _flowerTypes = [];
  List<dynamic> _pots = [];

  List<Achievement> _achievements = [];
  int _completedAchievements = 0;
  int _unclaimedAchievements = 0;

  Achievement? _notificationAchievement;
  bool _showAchievementNotification = false;

  Timer? _bgTimer;
  Timer? _updateTimer;
  bool _isUpdatingFlower = false;

  String _pluralRaz(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'раз';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'раза';
    return 'раз';
  }

  final GlobalKey _coinCounterKey = GlobalKey();

  // ==================== ТАПЫ ====================
  void _onSingleTap() {
    setState(() {
      _showLottie = true;
      _showJoyLottie = true;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showLottie = false;
          _showJoyLottie = false;
        });
      }
    });
  }

  void _onDoubleTap() {
    setState(() {
      _showLottie = true;
      _showImage = true;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showLottie = false;
          _showImage = false;
        });
      }
    });
  }

  // ==================== АНИМАЦИЯ МОНЕТКИ ====================
  void _animateCoinFromFlower() {
    final overlay = Overlay.of(context);
    final counterBox =
        _coinCounterKey.currentContext?.findRenderObject() as RenderBox?;
    if (counterBox == null) return;

    final counterPos = counterBox.localToGlobal(Offset.zero);
    final counterCenter = counterPos +
        Offset(counterBox.size.width / 2, counterBox.size.height / 2);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final startPos = Offset(screenWidth * 0.5, screenHeight * 0.55);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingCoin(
        start: startPos,
        end: counterCenter,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  // ==================== ПОКУПКА УДОБРЕНИЯ ====================
  Future<void> _buyFertilizer(Fertilizer fert) async {
    if (_coins < fert.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Недостаточно монет!'),
            backgroundColor: Color.fromARGB(255, 184, 69, 60)),
      );
      return;
    }

    setState(() {
      _coins -= fert.price;
      _showFertilizerShop = false;
      _fertilizerNotification = '${fert.name} использовано';

      // 👇 ДОБАВЛЯЕМ ПРОЦЕНТЫ К РОСТУ
      if (_flower != null) {
        final maxH = _flowerType?['max_height'] ?? 100;
        double bonusPercent = 0.0;

        if (fert.id == 'basic') bonusPercent = 5.0;
        if (fert.id == 'advanced') bonusPercent = 10.0;
        if (fert.id == 'premium') bonusPercent = 15.0;

        final double bonusHeight = maxH * (bonusPercent / 100.0);
        double newHeight = (_flower!['height'] ?? 0) + bonusHeight;
        
        if (newHeight > maxH) newHeight = maxH.toDouble();
        _flower!['height'] = newHeight;
        
        if (newHeight < maxH * 0.1) {
          _flower!['stage'] = 'seed';
        } else if (newHeight < maxH * 0.3) {
          _flower!['stage'] = 'sprout';
        } else if (newHeight < maxH * 0.6) {
          _flower!['stage'] = 'growing';
        } else if (newHeight < maxH * 0.9) {
          _flower!['stage'] = 'mature';
        } else {
          _flower!['stage'] = 'flowering';
        }

        LocalStorage.saveFlower(_flower!);
      }

      switch (fert.id) {
        case 'basic':
          _fertilizerImagePath = 'assets/images/fertilizers/flo_1.png';
          break;
        case 'advanced':
          _fertilizerImagePath = 'assets/images/fertilizers/flo2_2.png';
          break;
        case 'premium':
          _fertilizerImagePath = 'assets/images/fertilizers/flo3_3.png';
          break;
        default:
          _fertilizerImagePath = 'assets/images/fertilizers/flo_1.png';
      }

      _showFertilizerNotification = true;
    });

    await LocalStorage.saveCoins(_coins);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showFertilizerNotification = false;
        });
      }
    });
  }

  // ==================== ДОСТИЖЕНИЯ ====================
  void _initAchievements() {
    final catalog = Achievement.CATALOG;
    _achievements = catalog.entries.map((entry) {
      return Achievement(
        id: entry.key,
        title: entry.value['title'],
        description: entry.value['description'],
        imagePath: entry.value['imagePath'],
        requiredValue: entry.value['requiredValue'],
        reward: entry.value['reward'] ?? 0,
        currentValue: 0,
        type: entry.value['type'],
      );
    }).toList();
  }

  Future<void> _loadAchievements() async {
    final saved = await LocalStorage.loadAchievements();

    for (var a in _achievements) {
      final savedA = saved[a.id];
      if (savedA != null) {
        a.isCompleted = savedA['isCompleted'] ?? false;
        a.isClaimed = savedA['isClaimed'] ?? false;
        a.currentValue = savedA['currentValue'] ?? 0;
      }
    }
    _updateCompletedCount();
    if (mounted) setState(() {});
  }

  Future<void> _saveAchievements() async {
    final Map<String, dynamic> data = {};
    for (var a in _achievements) {
      data[a.id] = {
        'isCompleted': a.isCompleted,
        'isClaimed': a.isClaimed,
        'currentValue': a.currentValue,
      };
    }
    await LocalStorage.saveAchievements(data);
  }

  void _updateCompletedCount() {
    int completed = 0;
    int unclaimed = 0;
    for (var a in _achievements) {
      if (a.isCompleted) completed++;
      if (a.isCompleted && !a.isClaimed) unclaimed++;
    }
    _completedAchievements = completed;
    _unclaimedAchievements = unclaimed;
  }

  Future<void> _checkAchievements() async {
    bool needUpdate = false;
    Achievement? newlyCompleted;

    for (var achievement in _achievements) {
      if (achievement.isCompleted) continue;
      bool completed = false;

      switch (achievement.type) {
        case AchievementType.flower:
          if (_flower != null) {
            achievement.currentValue = 1;
            completed = true;
          }
          break;
        case AchievementType.water:
          int watered = _flower?['times_watered'] ?? 0;
          achievement.currentValue = watered;
          if (watered >= achievement.requiredValue) completed = true;
          break;
        case AchievementType.collection:
          String type = _flowerType?['type'] ?? '';
          final bool isFlowering = _flower?['stage'] == 'flowering';
          final bool isAlive = _flower?['is_alive'] ?? true;
          final bool matchesType =
              (achievement.id == 'violet_grow' && type == 'violet') ||
                  (achievement.id == 'orchid_grow' && type == 'orchid') ||
                  (achievement.id == 'monstera_grow' && type == 'monstera');
          if (matchesType && isFlowering && isAlive) {
            achievement.currentValue = 1;
            completed = true;
          }
          break;
        case AchievementType.growth:
          if (achievement.id == 'growth_10') {
            int height = (_flower?['height'] ?? 0).toInt();
            achievement.currentValue = height;
            if (height >= achievement.requiredValue) completed = true;
          } else if (achievement.id == 'flowering') {
            if (_flower?['stage'] == 'flowering') {
              achievement.currentValue = 1;
              completed = true;
            }
          }
          break;
      }

      if (completed && !achievement.isCompleted) {
        achievement.isCompleted = true;
        needUpdate = true;
        newlyCompleted = achievement;
      }
    }

    if (needUpdate) {
      _updateCompletedCount();
      await _saveAchievements();
      if (mounted) {
        setState(() {});
        if (newlyCompleted != null) {
          _showAchievementToast(newlyCompleted);
        }
      }
    }
  }

  void _showAchievementToast(Achievement achievement) {
    if (!mounted) return;
    setState(() {
      _notificationAchievement = achievement;
      _showAchievementNotification = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showAchievementNotification = false);
    });
  }

  Future<void> _claimAchievement(Achievement achievement) async {
    if (!achievement.isCompleted || achievement.isClaimed) return;

    setState(() {
      achievement.isClaimed = true;
      _coins += achievement.reward;
    });
    _updateCompletedCount();
    await _saveAchievements();
    await _saveCoins();
  }

  Future<void> _saveCoins() async {
    await LocalStorage.saveCoins(_coins);
  }

  Widget _buildCoinBadge(Achievement achievement) {
    final bool claimed = achievement.isClaimed;
    return ClipPath(
      clipper: _SkewedBadgeClipper(cut: 12),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: claimed
              ? const Color.fromARGB(255, 247, 151, 61)
              : const Color(0xFFBDBDBD),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/achievements/coins.png',
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.monetization_on,
                size: 16,
                color: Colors.amber,
              ),
            ), 
            const SizedBox(width: 4),
            Text(
              '${achievement.reward}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: claimed ? Colors.white : const Color(0xFF616161),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementsDialog() {
    _checkAchievements();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 193, 141, 43),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/icons8.png',
                              width: 28,
                              height: 28,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.emoji_events, color: Colors.white, size: 28);
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_completedAchievements/${_achievements.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Достижения',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = _achievements[index];
                      final bool isClaimed =
                          achievement.isCompleted && achievement.isClaimed;

                      return GestureDetector(
                        onTap: () async {
                          if (achievement.isCompleted && !achievement.isClaimed) {
                            await _claimAchievement(achievement);
                            setModalState(() {});
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12, top: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isClaimed ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isClaimed ? Colors.green : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Image.asset(
                                      achievement.imagePath,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.emoji_events,
                                          size: 28,
                                          color: isClaimed ? Color.fromARGB(169, 237, 178, 69) : Colors.grey,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          achievement.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isClaimed ? Colors.green[800] : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          achievement.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        LeafProgressBar(
                                          current: achievement.currentValue,
                                          total: achievement.requiredValue,
                                          leafCount: 7,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${achievement.currentValue}/${achievement.requiredValue}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Плашка с монеткой (в правом верхнем углу)
                            Positioned(
                              top: -8, // 👈 Наезжает наверх
                              right: 8,
                              child: _buildCoinBadge(achievement),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initAchievements();
    _initData();

    _bgTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted && _flower != null) {
        _updateFlowerState();
      }
    });

    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && _flower != null) {
        _updateFlowerState();
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  String _getBackgroundImage() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 4 && hour < 17) return 'assets/backgrounds/room.jpeg';
    if (hour >= 17 && hour < 19) return 'assets/backgrounds/room2.jpeg';
    return 'assets/backgrounds/room3.jpeg';
  }

  Future<void> _loadFlowerTypes() async {
    setState(() {
      _flowerTypes = [
        {
          'id': 1,
          'name': 'Деликатесная',
          'type': 'monstera',
          'base_water_needed': 14,
          'growth_rate': 0.6,
          'max_height': 200,
          'description': 'Крупное тропическое растение. Любит яркий рассеянный свет и заботу.',
          'price': 12, // 👈 Монстера 12
        },
        {
          'id': 2,
          'name': 'Фаленопсис',
          'type': 'orchid',
          'base_water_needed': 20,
          'growth_rate': 0.33,
          'max_height': 80,
          'description': 'Тропическая орхидея с нежными цветами. Требует регулярного полива.',
          'price': 7, // 👈 Орхидея 7
        },
        {
          'id': 3,
          'name': 'Сенполия',
          'type': 'violet',
          'base_water_needed': 10,
          'growth_rate': 0.5,
          'max_height': 25,
          'description': 'Комнатная фиалка с бархатистыми листьями и нежными цветами.',
          'price': 3, // 👈 Фиалка 3
        },
      ];
    });
  }

  Future<void> _loadPots() async {
    setState(() {
      _pots = [
        {
          'id': 10,
          'color': 'yellow',
          'size': 'medium',
          'image': 'assets/pots/goryellow.png',
        },
        {
          'id': 11,
          'color': 'brown',
          'size': 'medium',
          'image': 'assets/pots/gorcorp.png',
        },
        {
          'id': 12,
          'color': 'pink',
          'size': 'medium',
          'image': 'assets/pots/gorpink.png',
        },
      ];
    });
  }

  Future<void> _initData() async {
    await _loadFlowerTypes();
    await _loadPots();

    _coins = await LocalStorage.loadCoins();
    _playerName = await LocalStorage.loadUsername();

    await _loadAchievements();
    await _loadData();
    await _checkDailyLogin();

    setState(() => _isLoading = false);
  }

  Future<void> _checkDailyLogin() async {
    final today = LocalStorage.todayString();
    final yesterday = LocalStorage.yesterdayString();
    final lastDate = await LocalStorage.loadLastLoginDate();
    final streak = await LocalStorage.loadDailyStreak();

    int newStreak;
    int reward;

    if (lastDate == today) {
      newStreak = streak;
      reward = _calculateDailyReward(streak);
    } else if (lastDate == yesterday) {
      newStreak = streak + 1;
      reward = _calculateDailyReward(newStreak);
      _coins += reward;
      await LocalStorage.saveCoins(_coins);
      await LocalStorage.saveDailyStreak(newStreak);
      await LocalStorage.saveLastLoginDate(today);
    } else {
      newStreak = 1;
      reward = _calculateDailyReward(1);
      _coins += reward;
      await LocalStorage.saveCoins(_coins);
      await LocalStorage.saveDailyStreak(newStreak);
      await LocalStorage.saveLastLoginDate(today);
    }

    setState(() {
      _dailyStreak = newStreak;
      _dailyReward = reward;
      _showDailyLoginDialog = true;
    });
  }

  int _calculateDailyReward(int streak) {
    if (streak >= 200) return 10;
    if (streak >= 120) return 9;
    if (streak >= 100) return 8;
    if (streak >= 70) return 7;
    if (streak >= 40) return 6;
    if (streak >= 19) return 5;
    if (streak >= 12) return 4;
    if (streak >= 7) return 3;
    if (streak >= 3) return 2;
    return 1;
  }

  Future<void> _loadData() async {
    final savedFlower = await LocalStorage.loadFlower();

    if (savedFlower != null) {
      final flowerTypeId = savedFlower['flower_type'];
      Map<String, dynamic>? foundType;
      for (var type in _flowerTypes) {
        if (type['id'] == flowerTypeId) {
          foundType = type;
          break;
        }
      }

      final potId = savedFlower['pot'];
      Map<String, dynamic>? foundPot;
      for (var pot in _pots) {
        if (pot['id'] == potId) {
          foundPot = pot;
          break;
        }
      }

      setState(() {
        _flower = savedFlower;
        _flowerType = foundType;
        _flowerPot = foundPot;
      });

      _calculateNeedWater();
      await _checkAchievements();
    } else {
      setState(() {
        _flower = null;
        _flowerType = null;
        _flowerPot = null;
        _needWaterCount = 0;
      });
    }
  }

  void _calculateNeedWater() {
    if (_flower == null) {
      _needWaterCount = 0;
      return;
    }
    final waterLevel = _flower!['water_level'] ?? 0;
    if (waterLevel > 90) {
      _needWaterCount = 0;
    } else if (waterLevel > 70) {
      _needWaterCount = 1;
    } else if (waterLevel > 50) {
      _needWaterCount = 2;
    } else if (waterLevel > 30) {
      _needWaterCount = 3;
    } else if (waterLevel > 10) {
      _needWaterCount = 4;
    } else {
      _needWaterCount = 5;
    }
  }

  Duration? _getRepotCooldown() {
    if (_flower == null) return null;
    final lastRepot = _flower!['last_repot_at'];
    if (lastRepot == null) return null;

    final last = DateTime.tryParse(lastRepot.toString());
    if (last == null) return null;

    final next = last.add(const Duration(days: 2));
    final now = DateTime.now();
    if (now.isAfter(next)) return null;
    return next.difference(now);
  }

  String _formatCooldown(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return 'Через $days д $hours ч';
    if (hours > 0) return 'Через $hours ч $minutes мин';
    return 'Через $minutes мин';
  }

  Future<void> _waterFlower() async {
    if (_flower == null) return;
    final currentWaterLevel = _flower!['water_level'] ?? 0;
    if (currentWaterLevel >= 100) return;

    final newWater = (currentWaterLevel + 20).clamp(0, 100);
    final newHealth = newWater > 30 ? (_flower!['health'] + 5).clamp(0, 100) : _flower!['health'];
    final newTimes = (_flower!['times_watered'] ?? 0) + 1;

    setState(() {
      _flower!['water_level'] = newWater;
      _flower!['health'] = newHealth;
      _flower!['times_watered'] = newTimes;
      _coins += 1;
    });

    await LocalStorage.saveFlower(_flower!);
    await LocalStorage.saveCoins(_coins);

    _animateCoinFromFlower();
    _calculateNeedWater();
    await _checkAchievements();
  }

  Future<void> _repotFlower(int newPotId) async {
    if (_flower == null) return;

    final cooldown = _getRepotCooldown();
    if (cooldown != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Пересадка ${_formatCooldown(cooldown).toLowerCase()}'),
            backgroundColor: const Color.fromARGB(255, 184, 69, 60),
          ),
        );
      }
      return;
    }

    Map<String, dynamic>? newPot;
    for (var pot in _pots) {
      if (pot['id'] == newPotId) {
        newPot = pot;
        break;
      }
    }
    if (newPot == null) return;

    setState(() {
      _flower!['pot'] = newPotId;
      _flower!['health'] = ((_flower!['health'] ?? 100) + 10).clamp(0, 100);
      _flower!['last_repot_at'] = DateTime.now().toIso8601String();
      _coins += 3;
      _flowerPot = newPot;
    });

    await LocalStorage.saveFlower(_flower!);
    await LocalStorage.saveCoins(_coins);

    _animateCoinFromFlower();
    await _checkAchievements();
  }

  Future<void> _deleteFlower() async {
    if (_flower == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить цветок?', style: TextStyle(color: Colors.black)),
        content: const Text('Вы уверены, что хотите удалить этот цветок?', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalStorage.deleteFlower();
      setState(() {
        _flower = null;
        _flowerType = null;
        _flowerPot = null;
        _needWaterCount = 0;
      });
    }
  }

  void _showCreateFlower(int flowerTypeId) async {
    Map<String, dynamic>? selectedType;
    for (var type in _flowerTypes) {
      if (type['id'] == flowerTypeId) {
        selectedType = type;
        break;
      }
    }
    
    if (selectedType == null) return;
    final int price = selectedType['price'] ?? 0;

    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Недостаточно монет для покупки!'),
            backgroundColor: Color.fromARGB(255, 184, 69, 60)),
      );
      return;
    }

    setState(() => _showFlowerSelector = false);

    final potId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PotSelector(
        baseUrl: '',
        pots: _pots,
        selectedPotId: null,
        onPotSelected: (id) => Navigator.pop(context, id),
        onCancel: () => Navigator.pop(context, null),
      ),
    );

    if (potId != null) {
      final newFlower = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': 'Мой цветок',
        'flower_type': flowerTypeId,
        'pot': potId,
        'health': 100,
        'water_level': 50,
        'height': 1.0,
        'age': 0,
        'stage': 'seed',
        'times_watered': 0,
        'is_alive': true,
        'last_repot_at': null,
        'created_at': DateTime.now().toIso8601String(),
        'last_state_update': DateTime.now().toIso8601String(),
      };

      await LocalStorage.saveFlower(newFlower);
      await LocalStorage.incrementFlowerCount();

      Map<String, dynamic>? foundPot;
      for (var pot in _pots) {
        if (pot['id'] == potId) {
          foundPot = pot;
          break;
        }
      }

      setState(() {
        _flower = newFlower;
        _flowerType = selectedType;
        _flowerPot = foundPot;
        _coins -= price; // 👈 СПИСЫВАЕМ МОНЕТЫ
      });
      
      await LocalStorage.saveCoins(_coins);

      _calculateNeedWater();
      await _checkAchievements();
    }
  }

  void _showPotSelectorForRepot() async {
    if (_flower == null) return;

    final newPotId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RepotSheet(
        baseUrl: '',
        pots: _pots,
        currentPotId: _flowerPot?['id'],
        getCooldown: _getRepotCooldown,
        formatCooldown: _formatCooldown,
      ),
    );

    if (newPotId != null) {
      await _repotFlower(newPotId);
    }
  }

  Future<void> _updateFlowerState() async {
    if (_flower == null || _isUpdatingFlower) return;
    _isUpdatingFlower = true;

    try {
      final lastUpdate = DateTime.tryParse(_flower!['last_state_update'] ?? '') ?? DateTime.now();
      final hoursPassed = DateTime.now().difference(lastUpdate).inMinutes / 60.0;

      if (hoursPassed < 0.1) {
        _isUpdatingFlower = false;
        return;
      }

      double waterDecrease = hoursPassed * 1.042;
      double newWater = ((_flower!['water_level'] ?? 0) - waterDecrease).clamp(0, 100);

      double newHealth = (_flower!['health'] ?? 100).toDouble();
      if (newWater < 20) {
        newHealth = (newHealth - hoursPassed * 1.5).clamp(0, 100);
      }

      double newHeight = (_flower!['height'] ?? 5).toDouble();
      if (newWater > 30 && newHealth > 50) {
        final growthRate = _flowerType?['growth_rate'] ?? 0.5;
        newHeight += growthRate * hoursPassed;
        final maxH = _flowerType?['max_height'] ?? 100;
        if (newHeight > maxH) newHeight = maxH.toDouble();
      }

      final maxH = _flowerType?['max_height'] ?? 100;
      String newStage;
      if (newHeight < maxH * 0.1) {
        newStage = 'seed';
      } else if (newHeight < maxH * 0.3) {
        newStage = 'sprout';
      } else if (newHeight < maxH * 0.6) {
        newStage = 'growing';
      } else if (newHeight < maxH * 0.9) {
        newStage = 'mature';
      } else {
        newStage = 'flowering';
      }

      bool newAlive = !(newHealth <= 0 || newWater <= 0);

      setState(() {
        _flower!['water_level'] = newWater;
        _flower!['health'] = newHealth;
        _flower!['height'] = newHeight;
        _flower!['stage'] = newStage;
        _flower!['is_alive'] = newAlive;
        _flower!['last_state_update'] = DateTime.now().toIso8601String();
      });

      await LocalStorage.saveFlower(_flower!);
      _calculateNeedWater();
      await _checkAchievements();
    } catch (e) {
      debugPrint('Ошибка обновления: $e');
    } finally {
      _isUpdatingFlower = false;
    }
  }
  
  String _getStageFileName(String stage, String flowerType) {
    final isAlive = _flower?['is_alive'] ?? true;
    if (!isAlive) {
      if (flowerType == 'monstera') return 'wilted_mon6.png';
      if (flowerType == 'orchid') return 'wilted_or6.png';
      return 'wilted_wi6.png';
    }

    final double progress = _getGrowthProgress(); 

    if (progress < 0.2) {
      return '1.png';
    } else if (progress < 0.4) {
      if (flowerType == 'monstera') return 'mon2.png';
      if (flowerType == 'orchid') return 'or2.png';
      return 'wi2.png';
    } else if (progress < 0.6) {
      if (flowerType == 'monstera') return 'mon3.png';
      if (flowerType == 'orchid') return 'or3.png';
      return 'wi3.png';
    } else if (progress < 0.8) {
      if (flowerType == 'monstera') return 'mon4.png';
      if (flowerType == 'orchid') return 'or4.png';
      return 'wi4.png';
    } else {
      if (flowerType == 'monstera') return 'mon5.png';
      if (flowerType == 'orchid') return 'or5.png';
      return 'wi5.png';
    }
  }

  String _getDisplayFlowerName() {
    if (_flowerType == null) return 'Цветок';
    final type = _flowerType!['type'] ?? 'violet';
    switch (type) {
      case 'violet':
        return 'Фиалка';
      case 'orchid':
        return 'Орхидея';
      case 'monstera':
        return 'Монстера';
      default:
        return 'Цветок';
    }
  }

  String _getDisplayFlowerType() {
    if (_flowerType == null) return '';
    final type = _flowerType!['type'] ?? 'violet';
    switch (type) {
      case 'violet':
        return 'Сенполия';
      case 'orchid':
        return 'Фаленопсис';
      case 'monstera':
        return 'Деликатесная';
      default:
        return '';
    }
  }

  String _getFlowerDisplayName(String? type) {
    switch (type) {
      case 'violet':
        return 'Фиалка';
      case 'orchid':
        return 'Орхидея';
      case 'monstera':
        return 'Монстера';
      default:
        return 'Цветок';
    }
  }

  double _getHealthProgress() {
    return ((_flower?['health'] ?? 0) as num).toDouble() / 100;
  }

  double _getWaterProgress() {
    return ((_flower?['water_level'] ?? 0) as num).toDouble() / 100;
  }

  double _getGrowthProgress() {
    if (_flower == null || _flowerType == null) return 0;
    final maxHeight = _flowerType!['max_height'] ?? 100;
    final currentHeight = ((_flower!['height'] ?? 0) as num).toDouble();
    if (maxHeight <= 0) return 0;
    double progress = currentHeight / maxHeight;
    return progress.clamp(0.0, 1.0);
  }

  double _getBottomOffset(String stage, String flowerType) {
    final isAlive = _isFlowerAlive;

    if (!isAlive) {
      if (flowerType == 'monstera') return 110;
      if (flowerType == 'orchid') return 30;
      return 50;
    }

    if (flowerType == 'monstera') {
      switch (stage) {
        case 'seed':
          return -15;
        case 'sprout':
          return 20;
        case 'growing':
          return 25;
        case 'mature':
          return 30;
        case 'flowering':
          return 80;
        default:
          return 50;
      }
    } else if (flowerType == 'orchid') {
      switch (stage) {
        case 'seed':
          return 0;
        case 'sprout':
          return 10;
        case 'growing':
          return 25;
        case 'mature':
          return 30;
        case 'flowering':
          return 30;
        default:
          return 30;
      }
    } else {
      switch (stage) {
        case 'seed':
          return 10;
        case 'sprout':
          return 0;
        case 'growing':
          return 20;
        case 'mature':
          return 28;
        case 'flowering':
          return 28;
        default:
          return 28;
      }
    }
  }

  bool get _isFlowerAlive => _flower?['is_alive'] ?? true;

  Widget _buildPlantImage() {
    if (_flower == null) return const SizedBox();

    final flowerType = _flowerType?['type'] ?? 'violet';
    final stage = _flower!['stage'] ?? 'seed';
    final pot = _flowerPot;
    final isAlive = _isFlowerAlive;

    final bool hasPot = pot != null && pot['image'] != null;

    String potImagePath = '';
    if (hasPot) {
      potImagePath = pot!['image'];
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isPhone = screenWidth < 600;
    final containerSize = screenWidth * 0.8;
    final potWidth = screenWidth * 0.65;
    final potHeight = potWidth * 0.7;
    final plantSize = screenWidth * 0.45;
    final scaleFactor = screenHeight / 800;

    return GestureDetector(
      onTap: _onSingleTap,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        children: [
          SizedBox(
            width: containerSize,
            height: containerSize,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (hasPot)
                  Positioned(
                    bottom: -20, // 👈 Или -30, -50 (подбери на глаз)
                    child: Image.asset(
                      potImagePath,
                      width: potWidth,
                      height: potHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: potWidth,
                        height: potHeight,
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.grass, color: Colors.brown, size: 40),
                      ),
                    ),
                  )
                else
                  Positioned(
                    bottom: screenHeight * 0.02,
                    child: Container(
                      width: potWidth,
                      height: potHeight,
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grass, color: Colors.brown, size: 40),
                    ),
                  ),
                Positioned(
                  bottom: isAlive ? _getBottomOffset(stage, flowerType) * scaleFactor : screenHeight * 0.03,
                  child: Image.asset(
                    'assets/plants/$flowerType/${_getStageFileName(stage, flowerType)}',
                    width: plantSize,
                    height: plantSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_florist,
                      size: plantSize * 0.8,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // if (_showLottie)
          // Positioned(
          //   top: screenHeight * 0.20,
          //    left: screenWidth * 0.335,
          //    child: Lottie.asset(
          //      'assets/animations/eyes.json',
          //      width: 75,
          //      height: 75,
          //      repeat: false,
          //    ),
          //  ),
          //if (_showJoyLottie)
            //Positioned(
              //top: isPhone ? screenHeight * 0.25 : screenHeight * 0.27,
              // left: isPhone ? screenWidth * 0.22 : screenWidth * 0.25,
              //child: Lottie.asset(
              //  'assets/animations/confetti.json',
              //  width: isPhone ? screenWidth * 0.1 : screenWidth * 0.08,
              //  height: isPhone ? screenWidth * 0.1 : screenWidth * 0.08,
              //  repeat: false,
             // ),
            //),
          //if (_showImage)
          //  Positioned(
           //   top: isPhone ? screenHeight * 0.25 : screenHeight * 0.27,
            //  left: isPhone ? screenWidth * 0.22 : screenWidth * 0.25,
            //  child: Image.asset(
            //    'assets/images/anger.png',
            //    width: isPhone ? screenWidth * 0.16 : screenWidth * 0.12,
            //    height: isPhone ? screenWidth * 0.16 : screenWidth * 0.12,
            //    fit: BoxFit.contain,
            //  ),
          //  ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double value, Color color, String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15, // 👈 Увеличили и сделали черным
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16, // 👈 Увеличили
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // Чуть больше отступ
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          color: color,
          minHeight: isSmallScreen ? 8 : 10, // 👈 Сделали полоску толще
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildSelectorOverlay() {
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.7),
          child: GestureDetector(
            onTap: () => setState(() => _showFlowerSelector = false),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Выберите цветок',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _flowerTypes.length,
                    itemBuilder: (context, index) {
                      final type = _flowerTypes[index];
                      final String flowerType = type['type'];
                      final String flowerName = _getFlowerDisplayName(flowerType);
                      final String description = (type['description'] ?? '').toString();

                      String imagePath;
                      switch (flowerType) {
                        case 'violet':
                          imagePath = 'assets/plants/violet/wi5.png';
                          break;
                        case 'orchid':
                          imagePath = 'assets/plants/orchid/or5.png';
                          break;
                        case 'monstera':
                          imagePath = 'assets/plants/monstera/mon5.png';
                          break;
                        default:
                          imagePath = 'assets/plants/violet/wi5.png';
                      }

                      return GestureDetector(
                        onTap: () => _showCreateFlower(type['id']),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12, top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        imagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.local_florist,
                                            size: 40,
                                            color: Colors.green,
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
                                          flowerName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(255, 2, 1, 1),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (description.isNotEmpty)
                                          Text(
                                            description,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color.fromARGB(255, 44, 44, 44),
                                              height: 1.3,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Плашка с ценой
                                                        // Плашка с ценой
                            Positioned(
                              top: -8,
                              right: 8,
                              child: ClipPath(
                                clipper: _SkewedBadgeClipper(cut: 12),
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                                  // 👇 МЕНЯЕМ ЦВЕТ В ЗАВИСИМОСТИ ОТ МОНЕТ
                                  color: _coins >= (type['price'] ?? 0)
                                      ? const Color.fromARGB(255, 247, 151, 61) // Оранжевый
                                      : const Color(0xFFBDBDBD),                // Серый
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/achievements/coins.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${type['price']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          // 👇 ТЕКСТ БЕЛЫЙ, ЕСЛИ ХВАТАЕТ, И СЕРЫЙ, ЕСЛИ НЕТ
                                          color: _coins >= (type['price'] ?? 0)
                                              ? Colors.white
                                              : const Color(0xFF616161),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _showFlowerSelector = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlive = _isFlowerAlive;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundImage()),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // ==================== ВЕРХНЯЯ ПАНЕЛЬ ====================
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 1. Полив (компактный)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: Text(
                                'Полив: $_needWaterCount ${_pluralRaz(_needWaterCount)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            
                            // 2. Блок с монетками и достижениями
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CoinCounter(
                                  key: _coinCounterKey,
                                  coins: _coins,
                                  onTap: () => setState(() => _showFertilizerShop = true),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _showAchievementsDialog,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(169, 237, 178, 69),
                                      borderRadius: BorderRadius.circular(19),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Image.asset(
                                            'assets/images/icons8.png',
                                            width: 24,
                                            height: 24,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.emoji_events, color: Colors.white, size: 24);
                                            },
                                          ),
                                        ),
                                        if (_unclaimedAchievements > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                              child: Text(
                                                '$_unclaimedAchievements',
                                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _flower == null
                            ? Center(
                                child: GestureDetector(
                                  onTap: () => setState(() => _showFlowerSelector = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5E6D3),
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: const Text(
                                      '🌱 У вас пока нет цветов 🌱\n\nНажмите, чтобы посадить первый цветок!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5D3A1A),
                                        height: 1, // Уменьшили межстрочный интервал
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    top: screenHeight * 0.05,
                                    left: screenWidth * 0.1,
                                    child: _buildPlantImage(),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        width: screenWidth * 0.95,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Center(
                                              child: Text(
                                                _getDisplayFlowerName(),
                                                style: const TextStyle(
                                                    fontSize: 26, // 👈 Увеличили
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Center(
                                              child: Text(
                                                _getDisplayFlowerType(),
                                                style: const TextStyle(
                                                    fontSize: 18, // 👈 Увеличили
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87),
                                              ),
                                            ),
                                            if (!isAlive)
                                              Container(
                                                margin: const EdgeInsets.only(top: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(204, 170, 65, 57).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Цветок погиб',
                                                  style: TextStyle(
                                                      color: Color.fromARGB(255, 0, 0, 0),
                                                      fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            const SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildProgressBar(
                                                    _getHealthProgress(),
                                                    const Color.fromARGB(255, 201, 63, 53),
                                                    'Уровень здоровья',
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: _buildProgressBar(
                                                    _getWaterProgress(),
                                                    const Color.fromARGB(255, 46, 140, 218),
                                                    'Уровень воды',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Center(
                                              child: _buildProgressBar(
                                                _getGrowthProgress(),
                                                const Color.fromARGB(255, 70, 155, 73),
                                                'Уровень роста',
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: (!isAlive || (_flower?['water_level'] ?? 0) >= 100)
                                                    ? null
                                                    : _waterFlower,
                                                icon: const Icon(Icons.water_drop, color: Colors.blue),
                                                label: Text(
                                                  'Полить',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: (!isAlive || (_flower?['water_level'] ?? 0) >= 100)
                                                        ? Colors.grey
                                                        : Colors.black,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.black,
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                    side: BorderSide(
                                                      color: (!isAlive || (_flower?['water_level'] ?? 0) >= 100)
                                                          ? Colors.grey
                                                          : Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
          ),
          if (_showFlowerSelector && _flowerTypes.isNotEmpty)
            _buildSelectorOverlay(),
          if (_showProfileDialog)
            Stack(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: GestureDetector(
                    onTap: () => setState(() => _showProfileDialog = false),
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(30),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 60, color: Color.fromARGB(255, 49, 105, 51)),
                        const SizedBox(height: 16),
                        Text(
                          _playerName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() => _showProfileDialog = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 56, 103, 58),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Закрыть',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          if (_showFertilizerShop)
            Stack(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: GestureDetector(
                    onTap: () => setState(() => _showFertilizerShop = false),
                  ),
                ),
                Center(
                  child: FertilizerShop(
                    userCoins: _coins,
                    onBuy: _buyFertilizer,
                    onCancel: () => setState(() => _showFertilizerShop = false),
                  ),
                ),
              ],
            ),

          if (_showDailyLoginDialog)
            DailyLoginDialog(
              streak: _dailyStreak,
              reward: _dailyReward,
              onClaim: () {
                setState(() {
                  _showDailyLoginDialog = false;
                });
              },
            ),

          if (_showFertilizerNotification && _fertilizerNotification != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 90,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showFertilizerNotification ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipPath(
                      clipper: _ChamferedClipper(cut: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        color: const Color.fromARGB(180, 96, 110, 97),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_fertilizerImagePath != null)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.asset(
                                  _fertilizerImagePath!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.eco, color: Colors.white, size: 26);
                                  },
                                ),
                              )
                            else
                              const Icon(Icons.eco, color: Colors.white, size: 26),
                            const SizedBox(width: 10),
                            Text(
                              _fertilizerNotification!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_showAchievementNotification && _notificationAchievement != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 90,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showAchievementNotification ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipPath(
                      clipper: _ChamferedClipper(cut: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: const Color.fromARGB(180, 96, 110, 97),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Image.asset(
                                _notificationAchievement!.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.emoji_events,
                                    color: Color.fromARGB(255, 255, 200, 100),
                                    size: 30,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _notificationAchievement!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _flower != null && !_showFertilizerShop && !_showDailyLoginDialog
          ? Padding(
              padding: const EdgeInsets.only(left: 30, right: 10, bottom: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShopButton(
                    onTap: () => setState(() => _showFertilizerShop = true),
                    size: 55,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: FloatingActionButton(
                          onPressed: _showPotSelectorForRepot,
                          backgroundColor: Colors.brown,
                          heroTag: 'repot',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.grass, size: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: FloatingActionButton(
                          onPressed: _deleteFlower,
                          backgroundColor: const Color(0xFF5D3A1A),
                          heroTag: 'delete',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// ==================== КЛАСС ДОСТИЖЕНИЯ ====================
enum AchievementType { flower, water, collection, growth }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final int requiredValue;
  final int reward;
  int currentValue;
  bool isCompleted;
  bool isClaimed;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.requiredValue,
    required this.reward,
    required this.currentValue,
    required this.type,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  static const Map<String, Map<String, dynamic>> CATALOG = {
    'first_flower': {
      'title': 'Первый цветок',
      'description': 'Посадите первый цветок',
      'imagePath': 'assets/images/achievements/blossom.png',
      'requiredValue': 1,
      'reward': 5,
      'type': AchievementType.flower,
    },
    'water_10': {
      'title': 'Заботливый садовод',
      'description': 'Полейте цветок 10 раз',
      'imagePath': 'assets/images/achievements/watering1.png',
      'requiredValue': 10,
      'reward': 5,
      'type': AchievementType.water,
    },
    'water_50': {
      'title': 'Мастер полива',
      'description': 'Полейте цветок 50 раз',
      'imagePath': 'assets/images/achievements/watering2.png',
      'requiredValue': 25,
      'reward': 15,
      'type': AchievementType.water,
    },
    'violet_grow': {
      'title': 'Коллекционер фиалок',
      'description': 'Вырастите фиалку',
      'imagePath': 'assets/images/achievements/violet.png',
      'requiredValue': 1,
      'reward': 25,
      'type': AchievementType.collection,
    },
    'orchid_grow': {
      'title': 'Коллекционер орхидей',
      'description': 'Вырастите орхидею',
      'imagePath': 'assets/images/achievements/orchid.png',
      'requiredValue': 1,
      'reward': 25,
      'type': AchievementType.collection,
    },
    'monstera_grow': {
      'title': 'Коллекционер монстер',
      'description': 'Вырастите монстеру',
      'imagePath': 'assets/images/achievements/monster.png',
      'requiredValue': 1,
      'reward': 25,
      'type': AchievementType.collection,
    },
    'growth_10': {
      'title': 'Первые сантиметры',
      'description': 'Вырастите цветок до 10 см',
      'imagePath': 'assets/images/achievements/ruler.png',
      'requiredValue': 10,
      'reward': 10,
      'type': AchievementType.growth,
    },
    'flowering': {
      'title': 'Первое цветение',
      'description': 'Дождитесь цветения',
      'imagePath': 'assets/images/achievements/blossom.png',
      'requiredValue': 1,
      'reward': 25,
      'type': AchievementType.growth,
    },
  };
}

// ==================== КЛИПЕР ====================
class _ChamferedClipper extends CustomClipper<Path> {
  final double cut;
  _ChamferedClipper({this.cut = 14});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final c = cut;
    return Path()
      ..moveTo(c, 0)
      ..lineTo(w - c, 0)
      ..lineTo(w, c)
      ..lineTo(w, h - c)
      ..lineTo(w - c, h)
      ..lineTo(c, h)
      ..lineTo(0, h - c)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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

// ==================== ЛИАНА ====================
class LeafProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final int leafCount;

  const LeafProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.leafCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return SizedBox(
      height: 34,
      child: CustomPaint(
        painter: _LeafPainter(
          progress: progress,
          leafCount: leafCount,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final double progress;
  final int leafCount;

  _LeafPainter({
    required this.progress,
    required this.leafCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double centerY = h / 2;

    final bgLinePaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, centerY), Offset(w, centerY), bgLinePaint);

    final progressPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(w * progress, centerY),
      progressPaint,
    );

    final vinePaint = Paint()
      ..color = const Color(0xFF2E4A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final vinePath = Path();
    final double amplitude = 6;
    final double step = leafCount > 1 ? w / (leafCount - 1) : w;
    final double halfWave = step;

    vinePath.moveTo(0, centerY - amplitude);
    double x = 0;
    bool up = false;
    while (x < w) {
      x += halfWave;
      if (x > w) x = w;
      final midX = x - halfWave / 2;
      if (midX > 0) {
        vinePath.quadraticBezierTo(
          midX,
          up ? centerY + amplitude * 2 : centerY - amplitude * 2,
          x,
          up ? centerY + amplitude : centerY - amplitude,
        );
      } else {
        vinePath.lineTo(x, up ? centerY + amplitude : centerY - amplitude);
      }
      up = !up;
    }

    canvas.drawPath(vinePath, vinePaint);

    for (int i = 0; i < leafCount; i++) {
      final double leafX = i * step;
      final double leafY = centerY + (i % 2 == 0 ? -amplitude : amplitude);

      final bool filled = (leafCount > 1)
          ? (i / (leafCount - 1)) <= progress + 0.0001
          : progress >= 1.0;

      final leafPaint = Paint()
        ..color = filled ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(leafX, leafY);
      canvas.rotate(i % 2 == 0 ? -0.6 : 0.6);

      final leafRect = Rect.fromCenter(
        center: Offset.zero,
        width: 12,
        height: 6,
      );
      canvas.drawOval(leafRect, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.leafCount != leafCount;
  }
}

// ==================== ПЛАШКА ПЕРЕСАДКИ ====================
class _RepotSheet extends StatefulWidget {
  final String baseUrl;
  final List<dynamic> pots;
  final dynamic currentPotId;
  final Duration? Function() getCooldown;
  final String Function(Duration) formatCooldown;

  const _RepotSheet({
    required this.baseUrl,
    required this.pots,
    required this.currentPotId,
    required this.getCooldown,
    required this.formatCooldown,
  });

  @override
  State<_RepotSheet> createState() => _RepotSheetState();
}

class _RepotSheetState extends State<_RepotSheet> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getRussianColor(String color) {
    switch (color.toLowerCase()) {
      case 'brown':
        return 'Коричневый';
      case 'yellow':
        return 'Жёлтый';
      case 'pink':
        return 'Розовый';
      default:
        return color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cooldown = widget.getCooldown();
    final canRepot = cooldown == null;

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
            
            // 👇 УБИРАЕМ СЕТКУ, ДЕЛАЕМ В РЯД
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: widget.pots.map((pot) {
                  final isSelected = widget.currentPotId == pot['id'];

                  String imagePath = '';
                  if (pot['image'] != null) {
                    imagePath = pot['image'].toString();
                  }

                  return GestureDetector(
                    onTap: canRepot ? () => Navigator.pop(context, pot['id']) : null,
                    child: Opacity(
                      opacity: canRepot ? 1.0 : 0.4,
                      child: Container(
                        width: 80, // Уже
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60, // Меньше
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
                            // 👇 НАЗВАНИЕ ГОРШКА УБРАНО
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (!canRepot && cooldown != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8453C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Color(0xFFB8453C), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Пересадка ${widget.formatCooldown(cooldown).toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 113, 71, 34),
                      ),
                    )
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Можно пересадить (+3 монеты)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, null),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== АНИМАЦИЯ ЛЕТЯЩЕЙ МОНЕТКИ ====================
class _FlyingCoin extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onDone;

  const _FlyingCoin({
    required this.start,
    required this.end,
    required this.onDone,
  });

  @override
  State<_FlyingCoin> createState() => _FlyingCoinState();
}

class _FlyingCoinState extends State<_FlyingCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // 👈 Увеличили время полета (1.8 сек)
    );
    _t = CurvedAnimation(
      parent: _controller, 
      curve: Curves.fastOutSlowIn, // 👈 Плавная кривая (начинает быстро, к концу замедляется)
    );
    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final pos = Offset.lerp(widget.start, widget.end, _t.value)!;
        // 👇 Увеличили амплитуду дуги со -60 до -100
        final arc = -100 * (1 - (2 * _t.value - 1).abs()); 
        return Positioned(
          left: pos.dx - 16,
          top: pos.dy - 16 + arc,
          child: Opacity(
            opacity: (1 - _t.value).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (1 - _t.value * 0.5).clamp(0.0, 1.0),
              child: Image.asset(
                'assets/images/achievements/coins.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}