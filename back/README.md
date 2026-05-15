# Сюзерен / Era of Change — Backend API

Ruby on Rails API приложение для планшетного приложения "Сюзерен" (Era of Change).

## Стек

- Ruby 3.2.2
- Rails 7.0.10 (API mode)
- PostgreSQL

## Модели

| Модель | Поля | Связи |
|--------|------|-------|
| **Country** | `name` | has_many :provinces, :positions |
| **Province** | `name` | belongs_to :country |
| **Position** | `name` | belongs_to :country; has_many :action_types (через PositionActionType) |
| **ActionType** | `action_type` (prince/noble), `name`, `display_params` (C/P/C2/PF), `success_result`, `failure_result` | has_many :positions (через PositionActionType) |
| **PositionActionType** | — | связь M:N между Position и ActionType |
| **Action** | `cycle_number` | belongs_to :position, :action_type, :country, :second_country (опционально), :province (опционально) |
| **Parameter** | `current_cycle` | синглтон, хранит номер текущего цикла |

## API Endpoints

Все эндпоинты находятся под `http://localhost:3000/api/v1/`.

### CRUD

```
GET    /countries          — список стран
POST   /countries          — создать страну
GET    /countries/:id      — показать страну
PATCH  /countries/:id      — обновить страну
DELETE /countries/:id      — удалить страну

GET    /provinces          — список провинций
POST   /provinces          — создать провинцию
GET    /provinces/:id      — показать провинцию
PATCH  /provinces/:id      — обновить провинцию
DELETE /provinces/:id      — удалить провинцию

GET    /positions          — список должностей
POST   /positions          — создать должность
GET    /positions/:id      — показать должность
PATCH  /positions/:id      — обновить должность
DELETE /positions/:id      — удалить должность

GET    /action_types       — список типов действий
POST   /action_types       — создать тип действия
GET    /action_types/:id   — показать тип действия
PATCH  /action_types/:id   — обновить тип действия
DELETE /action_types/:id   — удалить тип действия

GET    /actions            — список совершённых действий
GET    /actions/:id        — показать действие
DELETE /actions/:id        — удалить действие

GET    /parameters         — параметры
GET    /parameters/:id     — показать параметр
PATCH  /parameters/:id     — обновить параметр
```

### Специализированные эндпоинты

```
GET /countries/:country_id/positions
  — должности в стране с их типами действий

GET /action_types/:id/with_lists?country_id=X
  — тип действия + три списка:
    • все страны, кроме X
    • провинции страны X
    • провинции всех стран, кроме X

POST /actions/perform
  — совершить действие должностью
  Body: { position_id, action_type_id, country_id?, second_country_id?, province_id? }
  Логика заполнения полей:
    • display_params = "C"  → country_id
    • display_params = "P"  → province_id (country_id из провинции)
    • display_params = "PF" → province_id (country_id из провинции)
    • display_params = "C2" → country_id + second_country_id
    • иначе → country_id

GET /countries/:country_id/actions/current_cycle
  — действия текущего цикла в выбранной стране

POST /parameters/next_cycle
  — увеличить current_cycle на 1
```

## Установка и запуск

```bash
# Установка зависимостей
bundle install

# Создание БД
rails db:create

# Миграции
rails db:migrate

# Наполнение данными
rails db:seed

# Запуск сервера
rails server
```

## Начальные данные

- **12 стран**, **21 провинция** — загружены из `countries.csv`
- **7 должностей**: Маршал, Государь, Управляющий, Тайный советник, Епископ, Инженер, Дипломат — созданы для Руси и Великого княжества Литовского
- **48 типов действий** — загружены из `roles.csv`
- **1 параметр** — `current_cycle = 1`
