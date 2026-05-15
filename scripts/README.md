# Скрипты sovereign

## `start-dev.sh`
Запуск окружения разработки. Поднимает Rails (backend) и Metro bundler (React Native) в tmux-сессии.

```bash
./scripts/start-dev.sh
```

## `stop-dev.sh`
Остановка tmux-сессии разработки.

```bash
./scripts/stop-dev.sh
```

## `build-prod.sh`
Сборка production-сборки мобильного приложения (APK/AAB/iOS).

```bash
./scripts/build-prod.sh
```

## `deploy-backend.sh`
Деплой Rails-бэкенда на production-сервер.

```bash
./scripts/deploy-backend.sh          # интерактивный режим
./scripts/deploy-backend.sh y y      # автоматический: сброс БД, загрузка сидов
./scripts/deploy-backend.sh n y      # автоматический: без сброса БД, с сидами
```

Настраиваемые переменные окружения:
- `BACKEND_DEPLOY_SERVER` — IP сервера (по умолчанию `62.173.148.168`)

## `deploy-to-tablets.sh`
Массовая установка APK на все Android-планшеты, подключённые по USB.

```bash
./scripts/deploy-to-tablets.sh                          # авто-поиск APK
./scripts/deploy-to-tablets.sh /путь/к/app-release.apk  # явный путь
```

## `get-ip.sh`
Вспомогательный скрипт определения IP-адреса. Не предназначен для прямого запуска.
