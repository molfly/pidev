# pidev — настройка pi для DeepSeek

Конфиги и скрипт, которые за одну команду настраивают агент [pi](https://pi.dev/) на работу
с моделями DeepSeek на любом маке.

## Быстрый старт

```bash
git clone https://github.com/molfly/pidev.git
cd pidev
cp .env.template .env    # впишите свой key_deepseek
./scripts/setup.sh
pi
```

Ключ DeepSeek берётся на [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys).

## Что делает `scripts/setup.sh`

1. Читает `key_deepseek` из `.env` (сам `.env` в репозиторий не уходит, см. `.gitignore`).
2. Ставит pi через `npm install -g @earendil-works/pi-coding-agent`, если его ещё нет.
3. Пишет ключ в `~/.pi/agent/auth.json` с правами `600`.
4. Копирует `conf/settings.json` в `~/.pi/agent/settings.json` — провайдер и модель по умолчанию.
5. Проверяет ключ запросом к `https://api.deepseek.com/models` и печатает список доступных моделей.

Оба файла в `~/.pi/agent/` обновляются слиянием: ключи и настройки других провайдеров не затираются.
Скрипт идемпотентен — повторный запуск безопасен.

## Структура

| Путь | Назначение |
|------|------------|
| `.env` | Ключи и локальные переменные. **Не коммитится.** |
| `.env.template` | Образец `.env` для нового мака |
| `conf/settings.json` | Провайдер и модель по умолчанию → `~/.pi/agent/settings.json` |
| `scripts/setup.sh` | Установка и настройка |
| `docs/deepseek.md` | Подробности: модели, цены, ручная настройка, диагностика |
| `templates/project/` | Заготовка нового проекта |

## Модели

DeepSeek входит в pi как встроенный провайдер, отдельный `models.json` не нужен.

| Модель | Контекст | Вход / выход, $ за 1M токенов |
|--------|----------|-------------------------------|
| `deepseek-v4-flash` (по умолчанию) | 1M | 0.14 / 0.28 |
| `deepseek-v4-pro` | 1M | 0.435 / 0.87 |
| `deepseek-v4-flash-vision-exp` | 1M | 0.14 / 0.28, понимает картинки |

Сменить модель в сессии — `/model` или `Ctrl+L`. Чтобы сохранить выбор как стартовый,
нажмите `Ctrl+S` в списке `/model` либо поправьте `conf/settings.json` и перезапустите скрипт.

## Заготовка нового проекта

`templates/project/` копируется целиком, чтобы не собирать структуру заново:

```bash
cp -R templates/project ~/git/НОВЫЙ-ПРОЕКТ
cd ~/git/НОВЫЙ-ПРОЕКТ
mv .gitignore.template .gitignore
git init
```

Внутри: `README.md` с плейсхолдерами, `.gitignore.template` (секреты, macOS, артефакты сборки),
пустые `apps/` и `docs/`. Файл игнора лежит под суффиксом `.template`, иначе он действовал бы
на сам этот репозиторий.
