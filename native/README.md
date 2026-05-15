# Сюзерен (Era of Change) — Нативное приложение

React Native приложение для планшета. Бэкенд: `https://sovereign-back.igroteh.su`

## Стек

- React Native 0.85
- TypeScript
- React Navigation 7 (native-stack)
- Android (планшет)

## Экраны

1. **Выбор страны** — Русь или Великое княжество Литовское
2. **Главное меню** — две кнопки: "Совершить действие" и "Посмотреть совершённые действия"

### Совершить действие

1. **Выбор должности** в выбранной стране (сортировка по алфавиту)
2. **Список действий** для выбранной должности (сортировка по алфавиту)
3. **Форма действия**:
   - Название действия
   - Результат при успехе / неудаче
   - Выпадающие списки в зависимости от типа (`display_params`):
     - **C** — страна (заполняется автоматически)
     - **P** — провинция выбранной страны
     - **PF** — провинции всех стран, кроме выбранной
     - **C2** — две выпадашки стран
   - Кнопка "Совершить действие" с мягкой валидацией

### Посмотреть совершённые действия

- Список действий текущего цикла (от старых к новым)
- Каждое действие можно отметить прочитанным (однократно, через `PATCH /api/v1/actions/:id/mark_read`)

## Запуск

```bash
cd native
npx react-native run-android
```

## API Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/api/v1/countries` | Список стран |
| GET | `/api/v1/countries/:id/positions` | Должности страны с типами действий |
| GET | `/api/v1/action_types/:id/with_lists?country_id=X` | Тип действия со списками для выпадашек |
| POST | `/api/v1/actions/perform` | Совершить действие |
| GET | `/api/v1/countries/:id/actions/current_cycle` | Действия текущего цикла |
| PATCH | `/api/v1/actions/:id/mark_read` | Отметить действие прочитанным |

## Структура проекта

```
src/
  config.ts              — настройки (API base URL)
  services/api.ts        — API-клиент + TypeScript интерфейсы
  navigation/types.ts    — типы навигации
  components/
    DropdownPicker.tsx   — кастомный выпадающий список
  screens/
    CountrySelectScreen.tsx
    MainMenuScreen.tsx
    PositionSelectScreen.tsx
    ActionTypeListScreen.tsx
    ActionFormScreen.tsx
    CompletedActionsScreen.tsx
```
