from rest_framework import serializers
from django.contrib.auth.models import User
from .models import FlowerType, Pot, UserFlower, UserProfile


class FlowerTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = FlowerType
        fields = '__all__'


class PotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pot
        fields = '__all__'


class UserFlowerSerializer(serializers.ModelSerializer):
    flower_type_name = serializers.CharField(source='flower_type.name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = UserFlower
        fields = '__all__'
        read_only_fields = ['times_watered', 'created_at', 'updated_at']


class UserFlowerDetailSerializer(serializers.ModelSerializer):
    flower_type = FlowerTypeSerializer(read_only=True)
    pot = PotSerializer(read_only=True)

    class Meta:
        model = UserFlower
        fields = '__all__'


class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = UserProfile
        fields = [
            'id', 'user', 'username', 'email',
            'level', 'total_flowers', 'coins',
            'login_streak', 'last_login_date',
        ]


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']