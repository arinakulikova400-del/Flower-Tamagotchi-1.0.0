from django.contrib import admin
from .models import FlowerType, Pot, UserFlower, UserProfile
from .models import PlantAction  

@admin.register(FlowerType)
class FlowerTypeAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'base_water_needed', 'is_available')
    list_filter = ('type', 'is_available', 'sunlight_preference')
    search_fields = ('name', 'description')
    fields = ('name', 'type', 'base_water_needed', 'growth_rate', 'sunlight_preference', 
              'max_height', 'description', 'image', 'is_available')

@admin.register(Pot)
class PotAdmin(admin.ModelAdmin):
    list_display = ('size', 'color')
    list_filter = ('size',)
    search_fields = ('color',)
    fields = ('size', 'color', 'image')

@admin.register(UserFlower)
class UserFlowerAdmin(admin.ModelAdmin):
    list_display = ('name', 'user', 'flower_type', 'health', 'water_level', 'stage', 'is_alive')
    list_filter = ('stage', 'is_alive', 'flower_type')
    search_fields = ('name', 'user__username')
    readonly_fields = ('times_watered', 'last_watered', 'created_at', 'updated_at')
    
    # Разделение на секции для удобства
    fieldsets = (
        ('Основная информация', {
            'fields': ('user', 'flower_type', 'name', 'pot')
        }),
        ('Текущее состояние цветка', {
            'fields': ('health', 'water_level', 'height', 'age', 'stage', 'is_alive'),
            'description': 'Здесь отображается текущее состояние цветка'
        }),
        ('Статистика и история действий', {
            'fields': ('times_watered', 'last_watered', 'created_at', 'updated_at'),
            'description': 'Количество поливов и время последних действий'
        }),
    )
@admin.register(PlantAction)
class PlantActionAdmin(admin.ModelAdmin):
    list_display = ('plant', 'action_type', 'old_value', 'new_value', 'created_at')
    list_filter = ('action_type', 'created_at')
    search_fields = ('plant__name', 'plant__user__username')
    readonly_fields = ('created_at',)
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Информация о действии', {
            'fields': ('plant', 'action_type', 'notes')
        }),
        ('Изменения', {
            'fields': ('old_value', 'new_value')
        }),
        ('Время', {
            'fields': ('created_at',)
        }),
    )
    
@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'level')
    search_fields = ('user__username',)
    fields = ('user', 'level')
    readonly_fields = ('level',)



