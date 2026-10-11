import random
from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models.signals import post_save
from django.dispatch import receiver

User = get_user_model()


class FlowerType(models.Model):
    """Базовые типы цветов"""

    FLOWER_TYPES = [
        ('violet', 'Фиалка'),
        ('orchid', 'Орхидея'),
        ('monstera', 'Монстера'),
    ]

    SUNLIGHT_PREFERENCES = [
        ('low', 'Низкая'),
        ('medium', 'Средняя'),
        ('high', 'Высокая'),
    ]

    name = models.CharField(max_length=50, verbose_name="Название")
    type = models.CharField(max_length=20, choices=FLOWER_TYPES, verbose_name="Тип")
    base_water_needed = models.IntegerField(default=5, verbose_name="Потребность в воде")
    growth_rate = models.FloatField(default=1.0, verbose_name="Скорость роста (см/час)")
    sunlight_preference = models.CharField(
        max_length=10,
        choices=SUNLIGHT_PREFERENCES,
        default='medium',
        verbose_name="Свет"
    )
    max_height = models.IntegerField(default=100, verbose_name="Макс. высота (см)")
    description = models.TextField(blank=True, verbose_name="Описание")
    image = models.ImageField(upload_to='flowers/', null=True, blank=True, verbose_name="Изображение")
    is_available = models.BooleanField(default=True, verbose_name="Доступен")

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = "Тип цветка"
        verbose_name_plural = "Типы цветов"


class Pot(models.Model):
    """Горшки для цветов"""

    POT_SIZES = [
        ('medium', 'Средний'),
    ]

    POT_COLORS = [
        ('brown', 'Коричневый'),
        ('yellow', 'Жёлтый'),
        ('pink', 'Розовый'),
    ]

    size = models.CharField(max_length=10, choices=POT_SIZES, default='medium', verbose_name="Размер")
    color = models.CharField(max_length=20, choices=POT_COLORS, default='brown', verbose_name="Цвет")
    image = models.ImageField(upload_to='pots/', null=True, blank=True, verbose_name="Изображение")

    def __str__(self):
        return f"{self.get_size_display()} горшок ({self.get_color_display()})"

    class Meta:
        verbose_name = "Горшок"
        verbose_name_plural = "Горшки"


class UserFlower(models.Model):
    """Цветы пользователя"""

    GROWTH_STAGES = [
        ('seed', 'Семечко'),
        ('sprout', 'Росток'),
        ('growing', 'Растет'),
        ('mature', 'Зрелый'),
        ('flowering', 'Цветет'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='flowers')
    flower_type = models.ForeignKey(FlowerType, on_delete=models.CASCADE)
    name = models.CharField(max_length=100, verbose_name="Имя цветка")

    # Состояние цветка
    health = models.IntegerField(default=100, verbose_name="Здоровье")
    water_level = models.IntegerField(default=50, verbose_name="Уровень воды")
    height = models.FloatField(default=5.0, verbose_name="Высота (см)")
    age = models.IntegerField(default=0, verbose_name="Возраст (дни)")
    stage = models.CharField(
        max_length=20,
        choices=GROWTH_STAGES,
        default='seed',
        verbose_name="Стадия"
    )

    # Горшок
    pot = models.ForeignKey(Pot, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Горшок")

    # Статистика
    times_watered = models.IntegerField(default=0, verbose_name="Поливов")

    # Временные метки
    last_watered = models.DateTimeField(auto_now_add=True)
    last_repot_at = models.DateTimeField(null=True, blank=True, verbose_name="Последняя пересадка")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_state_update = models.DateTimeField(auto_now_add=True, verbose_name="Последнее обновление состояния")

    # Состояние
    is_alive = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.user.username})"

    class Meta:
        verbose_name = "Цветок пользователя"
        verbose_name_plural = "Цветы пользователей"
        ordering = ['-created_at']

    def water(self, amount=20):
        """Полив цветка +1 монета"""
        old_water = self.water_level
        old_health = self.health

        self.water_level = min(100, self.water_level + amount)
        self.last_watered = timezone.now()
        self.times_watered += 1

        if self.water_level > 30:
            self.health = min(100, self.health + 5)

        self.save()

        # 👇 НАЧИСЛЕНИЕ МОНЕТ ЗА ПОЛИВ (+1)
        profile = self.user.profile
        profile.coins += 1
        profile.save()

        # Обновляем достижения после полива
        self.user.check_achievements()

        PlantAction.objects.create(
            plant=self,
            action_type='water',
            old_value=old_water,
            new_value=self.water_level,
            notes=f"Полив на {amount} ед. Здоровье: {old_health} → {self.health}. +1 монета"
        )

        return self

    def repot(self, new_pot):
        """Пересадка в новый горшок +3 монеты"""
        self.pot = new_pot
        self.health = min(100, self.health + 10)
        self.last_repot_at = timezone.now()   # 👈 нужно для кулдауна
        self.save()

        # 👇 НАЧИСЛЕНИЕ МОНЕТ ЗА ПЕРЕСАДКУ (+3)
        profile = self.user.profile
        profile.coins += 3
        profile.save()

        PlantAction.objects.create(
            plant=self,
            action_type='repot',
            notes=f"Пересадка в горшок {new_pot}. +3 монеты"
        )

        return self

    def check_and_update_level(self):
        """Проверка: если 2 полностью выросших цветка = +1 уровень"""
        grown_flowers = UserFlower.objects.filter(
            user=self.user,
            stage='flowering',
            is_alive=True
        ).count()

        new_level = 1 + (grown_flowers // 2)

        profile = self.user.profile
        if profile.level != new_level:
            profile.level = new_level
            profile.save()

    def update_state(self):
        """Обновление состояния цветка"""
        if not self.is_alive:
            return self

        if self.last_state_update:
            hours_passed = (timezone.now() - self.last_state_update).total_seconds() / 3600
        else:
            hours_passed = 1

        if hours_passed < 1:
            return self

        if hours_passed <= 0:
            return self

        # УМЕНЬШЕНИЕ ВОДЫ — ровно 50% за 24 часа
        water_decrease = hours_passed * 1.041
        self.water_level = max(0, self.water_level - water_decrease)

        # УХУДШЕНИЕ ЗДОРОВЬЯ
        if self.water_level < 20:
            health_decrease = hours_passed * random.uniform(1, 2)
            self.health = max(0, self.health - health_decrease)

        # РОСТ
        if self.water_level > 30 and self.health > 50:
            self.height += self.flower_type.growth_rate * hours_passed

            max_height = self.flower_type.max_height if self.flower_type else 100
            if self.height > max_height:
                self.height = max_height

            if hours_passed >= 24:
                self.age += 1

        # ОБНОВЛЕНИЕ СТАДИИ
        old_stage = self.stage
        max_h = self.flower_type.max_height if self.flower_type else 100

        if self.height < max_h * 0.1:
            self.stage = 'seed'
        elif self.height < max_h * 0.3:
            self.stage = 'sprout'
        elif self.height < max_h * 0.6:
            self.stage = 'growing'
        elif self.height < max_h * 0.9:
            self.stage = 'mature'
        else:
            self.stage = 'flowering'

        # ПРОВЕРКА ЖИВ ЛИ ЦВЕТОК
        if self.health <= 0 or self.water_level <= 0:
            self.is_alive = False

        self.last_state_update = timezone.now()
        self.save()

        if old_stage != 'flowering' and self.stage == 'flowering':
            self.check_and_update_level()

        # 👇 обновляем достижения после автообновления
        self.user.check_achievements()

        PlantAction.objects.create(
            plant=self,
            action_type='update',
            notes=f"Автообновление: вода={self.water_level:.0f}, здоровье={self.health:.0f}, высота={self.height:.1f}"
        )

        return self


class PlantAction(models.Model):
    """История действий над цветком"""

    ACTION_TYPES = [
        ('water', 'Полив'),
        ('repot', 'Пересадка'),
        ('grow', 'Рост'),
        ('update', 'Автообновление'),
    ]

    plant = models.ForeignKey(UserFlower, on_delete=models.CASCADE, related_name='actions')
    action_type = models.CharField(max_length=20, choices=ACTION_TYPES, verbose_name="Тип действия")
    old_value = models.IntegerField(null=True, blank=True, verbose_name="Было")
    new_value = models.IntegerField(null=True, blank=True, verbose_name="Стало")
    notes = models.CharField(max_length=255, blank=True, verbose_name="Примечание")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Время действия")

    def __str__(self):
        return f"{self.plant.name} - {self.get_action_type_display()} - {self.created_at}"

    class Meta:
        verbose_name = "Действие"
        verbose_name_plural = "История действий"
        ordering = ['-created_at']


class UserProfile(models.Model):
    """Профиль пользователя"""

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    level = models.IntegerField(default=1, verbose_name="Уровень")
    total_flowers = models.IntegerField(default=0, verbose_name="Всего цветов")
    coins = models.IntegerField(default=50, verbose_name="Монеты")

    login_streak = models.IntegerField(default=0, verbose_name="Дней подряд")
    last_login_date = models.DateField(null=True, blank=True, verbose_name="Последний вход")

    def __str__(self):
        return f"{self.user.username}'s profile"

    class Meta:
        verbose_name = "Профиль"
        verbose_name_plural = "Профили"


# ===== СИГНАЛЫ ДЛЯ АВТОМАТИЧЕСКОГО СОЗДАНИЯ ПРОФИЛЯ =====
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    if hasattr(instance, 'profile'):
        instance.profile.save()


# ===== РАСШИРЯЕМ USER МЕТОДОМ check_achievements =====
def user_check_achievements(self):
    """
    Пересчитывает все достижения пользователя по текущему состоянию цветов.
    Вызывается после полива / пересадки / обновления состояния.
    """
    from django.db.models import Max

    # Получаем или создаём все достижения
    achievements_data = {
        'first_flower': {'required': 1, 'reward': 5, 'type': 'flower'},
        'water_10': {'required': 10, 'reward': 5, 'type': 'water'},
        'water_50': {'required': 50, 'reward': 15, 'type': 'water'},
        'violet_grow': {'required': 1, 'reward': 50, 'type': 'collection'},
        'orchid_grow': {'required': 1, 'reward': 50, 'type': 'collection'},
        'monstera_grow': {'required': 1, 'reward': 50, 'type': 'collection'},
        'growth_10': {'required': 10, 'reward': 10, 'type': 'growth'},
        'flowering': {'required': 1, 'reward': 50, 'type': 'growth'},
    }

    # Берём лучший цветок пользователя
    best_flower = self.flowers.filter(is_alive=True).order_by('-height').first()
    total_flowers = self.flowers.count()

    for ach_id, data in achievements_data.items():
        ach, _ = UserAchievement.objects.get_or_create(
            user=self,
            achievement_id=ach_id,
            defaults={'current_value': 0, 'is_completed': False, 'is_claimed': False}
        )

        if ach.is_completed:
            continue

        completed = False
        current_value = 0

        if ach_id == 'first_flower':
            current_value = min(total_flowers, 1)
            completed = total_flowers >= 1

        elif ach_id == 'water_10':
            current_value = best_flower.times_watered if best_flower else 0
            completed = current_value >= 10

        elif ach_id == 'water_50':
            current_value = best_flower.times_watered if best_flower else 0
            completed = current_value >= 50

        elif ach_id in ('violet_grow', 'orchid_grow', 'monstera_grow'):
            type_map = {
                'violet_grow': 'violet',
                'orchid_grow': 'orchid',
                'monstera_grow': 'monstera',
            }
            target_type = type_map[ach_id]
            matching = self.flowers.filter(
                flower_type__type=target_type,
                stage='flowering',
                is_alive=True
            ).exists()
            current_value = 1 if matching else 0
            completed = matching

        elif ach_id == 'growth_10':
            current_value = int(best_flower.height) if best_flower else 0
            completed = current_value >= 10

        elif ach_id == 'flowering':
            has_flowering = self.flowers.filter(stage='flowering', is_alive=True).exists()
            current_value = 1 if has_flowering else 0
            completed = has_flowering

        ach.current_value = current_value
        if completed and not ach.is_completed:
            ach.is_completed = True
        ach.save()


# Привязываем метод к User
User.check_achievements = user_check_achievements


class UserAchievement(models.Model):
    """Достижения пользователя (хранятся на сервере)"""

    ACHIEVEMENT_IDS = [
        ('first_flower', 'Первый цветок'),
        ('water_10', 'Заботливый садовод'),
        ('water_50', 'Мастер полива'),
        ('violet_grow', 'Коллекционер фиалок'),
        ('orchid_grow', 'Коллекционер орхидей'),
        ('monstera_grow', 'Коллекционер монстер'),
        ('growth_10', 'Первые сантиметры'),
        ('flowering', 'Первое цветение'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='achievements')
    achievement_id = models.CharField(max_length=50, choices=ACHIEVEMENT_IDS)
    is_completed = models.BooleanField(default=False)
    is_claimed = models.BooleanField(default=False)
    current_value = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Достижение пользователя"
        verbose_name_plural = "Достижения пользователей"
        unique_together = ('user', 'achievement_id')

    def __str__(self):
        return f"{self.user.username} - {self.achievement_id}"