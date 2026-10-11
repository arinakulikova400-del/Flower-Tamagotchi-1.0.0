# 🌸 Цветочный Тамагочи

### Бэкенд
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
Фронтенд
powershell
cd flutter_application_1
flutter pub get
flutter run -d edge --web-browser-flag "--disable-web-security"
⚠️ В lib/main.dart замени baseUrl на свой IP.

API
POST /api/register/ — регистрация

POST /api/login/ — логин → токен

GET /api/profile/ — профиль

GET /api/flowers/ — цветы

POST /api/flowers/{id}/water/ — полить (+1 монета)

POST /api/flowers/{id}/repot/ — пересадить (+3 монеты, раз в 2 дня)

POST /api/daily-login/ — ежедневный вход

GET/POST /api/achievements/ — достижения

POST /api/achievements/claim/ — забрать награду

Механика
Полив: +1 монета

Пересадка: +3 монеты, раз в 2 дня

Ежедневный вход: от 1 до 10 монет по стрику

Вода убывает ~25% за 24ч

Здоровье падает при воде < 20%

Стадии: seed → sprout → growing → mature → flowering