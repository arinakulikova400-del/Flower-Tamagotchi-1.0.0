from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework.authtoken.views import obtain_auth_token
from . import views

router = DefaultRouter()
router.register(r'flower-types', views.FlowerTypeViewSet)
router.register(r'pots', views.PotViewSet)
router.register(r'flowers', views.UserFlowerViewSet, basename='userflower')
router.register(r'profile', views.UserProfileViewSet, basename='userprofile')

urlpatterns = [
    path('', include(router.urls)),
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', obtain_auth_token, name='login'),
    
    # 👇 Новые эндпоинты
    path('daily-login/', views.DailyLoginView.as_view(), name='daily-login'),
    path('achievements/', views.AchievementsView.as_view(), name='achievements'),
    path('achievements/claim/', views.ClaimAchievementView.as_view(), name='claim-achievement'),
]