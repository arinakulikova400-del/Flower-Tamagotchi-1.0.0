from rest_framework import viewsets, status, generics
from rest_framework.decorators import action
from rest_framework.response import Response
from datetime import date, timedelta
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django.contrib.auth.models import User
from django.utils import timezone
from .models import FlowerType, Pot, UserFlower, UserProfile, UserAchievement
from .serializers import (
    FlowerTypeSerializer, PotSerializer, UserFlowerSerializer,
    UserFlowerDetailSerializer, UserProfileSerializer, UserSerializer
)


class FlowerTypeViewSet(viewsets.ModelViewSet):
    """API для типов цветов"""
    queryset = FlowerType.objects.filter(is_available=True)
    serializer_class = FlowerTypeSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class PotViewSet(viewsets.ModelViewSet):
    """API для горшков"""
    queryset = Pot.objects.all()
    serializer_class = PotSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class UserFlowerViewSet(viewsets.ModelViewSet):
    """API для цветов пользователя"""
    serializer_class = UserFlowerSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserFlower.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return UserFlowerDetailSerializer
        return UserFlowerSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    # ==================== ПОЛИВ ====================
    @action(detail=True, methods=['post'])
    def water(self, request, pk=None):
        """Полив цветка (монеты начисляются в модели UserFlower.water)"""
        flower = self.get_object()
        amount = request.data.get('amount', 20)

        old_health = flower.health
        flower.water(amount)  # 👈 +1 монета + достижения внутри модели

        # 👇 Перечитываем профиль, чтобы отдать актуальные монеты
        profile = request.user.profile
        profile.refresh_from_db()

        return Response({
            'status': 'success',
            'message': f'Цветок {flower.name} полит',
            'water_level': flower.water_level,
            'health': flower.health,
            'health_change': flower.health - old_health,
            'coins': profile.coins,
        })

    # ==================== ПЕРЕСАДКА ====================
    @action(detail=True, methods=['post'])
    def repot(self, request, pk=None):
        """Пересадка цветка (раз в 2 дня, +3 монеты)"""
        flower = self.get_object()

        pot_id = request.data.get('pot_id') or request.data.get('pot')

        if pot_id is None:
            return Response({
                'status': 'error',
                'message': 'Не указан ID горшка'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Проверка кулдауна — 2 дня (48 часов)
        if flower.last_repot_at:
            cooldown = timedelta(days=2)
            next_repot = flower.last_repot_at + cooldown
            if timezone.now() < next_repot:
                seconds_left = int((next_repot - timezone.now()).total_seconds())
                return Response({
                    'status': 'cooldown',
                    'message': 'Пересаживать можно раз в 2 дня',
                    'seconds_left': seconds_left,
                    'next_repot_at': next_repot.isoformat(),
                }, status=status.HTTP_400_BAD_REQUEST)

        try:
            new_pot = Pot.objects.get(id=pot_id)
            flower.repot(new_pot)  # 👈 +3 монеты и last_repot_at внутри модели

            profile = request.user.profile
            profile.refresh_from_db()

            return Response({
                'status': 'success',
                'message': f'Цветок {flower.name} пересажен',
                'pot': PotSerializer(new_pot).data,
                'coins': profile.coins,
                'reward': 3,
            })
        except Pot.DoesNotExist:
            return Response({
                'status': 'error',
                'message': 'Горшок не найден'
            }, status=status.HTTP_404_NOT_FOUND)

    # ==================== ОБНОВЛЕНИЕ СОСТОЯНИЯ ====================
    @action(detail=True, methods=['post'])
    def update_state(self, request, pk=None):
        """Обновление состояния цветка"""
        flower = self.get_object()
        flower.update_state()

        return Response({
            'status': 'success',
            'flower': UserFlowerDetailSerializer(flower).data
        })

    # ==================== СТАТИСТИКА ====================
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Статистика по цветам пользователя"""
        flowers = self.get_queryset()
        total = flowers.count()
        alive = flowers.filter(is_alive=True).count()
        dead = total - alive

        return Response({
            'total': total,
            'alive': alive,
            'dead': dead,
            'need_water': flowers.filter(water_level__lt=30, is_alive=True).count(),
            'flowering': flowers.filter(stage='flowering', is_alive=True).count()
        })

    # ==================== ПОКУПКА УДОБРЕНИЯ ====================
    @action(detail=False, methods=['post'])
    def buy_fertilizer(self, request):
        """Покупка удобрения"""
        fertilizer_id = request.data.get('fertilizer_id')
        price = request.data.get('price', 0)

        if not fertilizer_id or not price:
            return Response({
                'status': 'error',
                'message': 'Не указан ID или цена удобрения'
            }, status=status.HTTP_400_BAD_REQUEST)

        profile = request.user.profile

        if profile.coins < price:
            return Response({
                'status': 'error',
                'message': 'Недостаточно монет'
            }, status=status.HTTP_400_BAD_REQUEST)

        profile.coins -= price
        profile.save()

        return Response({
            'status': 'success',
            'message': f'Удобрение {fertilizer_id} куплено',
            'coins': profile.coins,
        })


class UserProfileViewSet(viewsets.ModelViewSet):
    """API для профиля пользователя"""
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserProfile.objects.filter(user=self.request.user)

    def get_object(self):
        return self.request.user.profile


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    """API для пользователей (только чтение)"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]


class RegisterView(generics.CreateAPIView):
    """Регистрация нового пользователя"""
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        password = request.data.get('password')
        email = request.data.get('email', '')

        if not username or not password:
            return Response({
                'error': 'Username and password required'
            }, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(username=username, password=password, email=email)
        return Response({
            'user': UserSerializer(user).data,
            'message': 'User created successfully'
        }, status=status.HTTP_201_CREATED)


# ==================== ЕЖЕДНЕВНЫЙ ВХОД ====================
class DailyLoginView(APIView):
    """Начисляет монеты за ежедневный вход"""
    permission_classes = [IsAuthenticated]

    def calculate_reward(self, streak):
        """Возвращает награду по стрику (по твоей таблице)"""
        if streak >= 200: return 10
        if streak >= 120: return 9
        if streak >= 100: return 8
        if streak >= 70:  return 7
        if streak >= 40:  return 6
        if streak >= 19:  return 5
        if streak >= 12:  return 4
        if streak >= 7:   return 3
        if streak >= 3:   return 2
        return 1

    def post(self, request):
        profile = request.user.profile
        today = date.today()

        # 👇 ЕСЛИ УЖЕ ПОЛУЧАЛ СЕГОДНЯ — возвращаем актуальный streak и reward
        if profile.last_login_date == today:
            reward = self.calculate_reward(profile.login_streak)
            return Response({
                'status': 'already_claimed',
                'streak': profile.login_streak,
                'coins': profile.coins,
                'reward': reward,   # 👈 не 0, а по стрику!
                'message': 'Сегодня уже получал награду',
            })

        # Обновляем стрик
        yesterday = today - timedelta(days=1)
        if profile.last_login_date == yesterday:
            profile.login_streak += 1
        else:
            profile.login_streak = 1

        reward = self.calculate_reward(profile.login_streak)
        profile.coins += reward
        profile.last_login_date = today
        profile.save()

        return Response({
            'status': 'success',
            'streak': profile.login_streak,
            'reward': reward,
            'coins': profile.coins,
            'message': f'День {profile.login_streak}! +{reward} монет',
        })


# ==================== ДОСТИЖЕНИЯ ====================
class AchievementsView(APIView):
    """Получить и обновить достижения пользователя"""
    permission_classes = [IsAuthenticated]

    REWARDS = {
        'first_flower': 5,
        'water_10': 5,
        'water_50': 15,
        'violet_grow': 50,
        'orchid_grow': 50,
        'monstera_grow': 50,
        'growth_10': 10,
        'flowering': 50,
    }

    def _ensure_achievements(self, user):
        """Создаёт недостающие записи достижений"""
        existing = {a.achievement_id for a in user.achievements.all()}
        for ach_id, _ in UserAchievement.ACHIEVEMENT_IDS:
            if ach_id not in existing:
                UserAchievement.objects.create(
                    user=user,
                    achievement_id=ach_id,
                )

    def _recalculate(self, user):
        """Пересчитывает прогресс ВСЕХ достижений по текущим цветам"""
        self._ensure_achievements(user)

        flowers = user.flowers.all()
        # Лучший цветок (самый высокий)
        best_flower = flowers.filter(is_alive=True).order_by('-height').first()
        # Есть ли цветущие нужного типа
        has_violet_flowering = flowers.filter(
            flower_type__type='violet',
            stage='flowering',
            is_alive=True
        ).exists()
        has_orchid_flowering = flowers.filter(
            flower_type__type='orchid',
            stage='flowering',
            is_alive=True
        ).exists()
        has_monstera_flowering = flowers.filter(
            flower_type__type='monstera',
            stage='flowering',
            is_alive=True
        ).exists()
        has_any_flowering = flowers.filter(stage='flowering', is_alive=True).exists()

        for ach in user.achievements.all():
            if ach.is_completed:
                continue

            completed = False
            current_value = ach.current_value

            if ach.achievement_id == 'first_flower':
                completed = flowers.exists()
                current_value = 1 if completed else 0

            elif ach.achievement_id == 'water_10':
                current_value = best_flower.times_watered if best_flower else 0
                completed = current_value >= 10

            elif ach.achievement_id == 'water_50':
                current_value = best_flower.times_watered if best_flower else 0
                completed = current_value >= 50

            elif ach.achievement_id == 'violet_grow':
                completed = has_violet_flowering
                current_value = 1 if completed else 0

            elif ach.achievement_id == 'orchid_grow':
                completed = has_orchid_flowering
                current_value = 1 if completed else 0

            elif ach.achievement_id == 'monstera_grow':
                completed = has_monstera_flowering
                current_value = 1 if completed else 0

            elif ach.achievement_id == 'growth_10':
                current_value = int(best_flower.height) if best_flower else 0
                completed = current_value >= 10

            elif ach.achievement_id == 'flowering':
                completed = has_any_flowering
                current_value = 1 if completed else 0

            if completed:
                ach.is_completed = True
            ach.current_value = current_value
            ach.save()

    def _serialize(self, user):
        """Сериализует достижения для фронта"""
        return [{
            'id': a.achievement_id,
            'is_completed': a.is_completed,
            'is_claimed': a.is_claimed,
            'current_value': a.current_value,
            'reward': self.REWARDS.get(a.achievement_id, 0),
        } for a in user.achievements.all()]

    def get(self, request):
        """Список достижений (создаёт недостающие и пересчитывает)"""
        self._recalculate(request.user)
        return Response(self._serialize(request.user))

    def post(self, request):
        """Пересчитать статусы достижений (вызывать после действий)"""
        self._recalculate(request.user)
        return Response(self._serialize(request.user))


class ClaimAchievementView(APIView):
    """Забрать награду за достижение"""
    permission_classes = [IsAuthenticated]

    REWARDS = AchievementsView.REWARDS

    def post(self, request):
        achievement_id = request.data.get('achievement_id')

        if not achievement_id:
            return Response({'error': 'Не указан achievement_id'}, status=400)

        try:
            ach = UserAchievement.objects.get(
                user=request.user, achievement_id=achievement_id
            )
        except UserAchievement.DoesNotExist:
            return Response({'error': 'Достижение не найдено'}, status=404)

        if not ach.is_completed:
            return Response({'error': 'Достижение ещё не выполнено'}, status=400)

        if ach.is_claimed:
            return Response({'error': 'Уже забрано'}, status=400)

        reward = self.REWARDS.get(achievement_id, 0)
        ach.is_claimed = True
        ach.save()

        profile = request.user.profile
        profile.coins += reward
        profile.save()

        return Response({
            'status': 'success',
            'reward': reward,
            'coins': profile.coins,
        })