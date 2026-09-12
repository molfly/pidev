# pi + DeepSeek: подробности

## Как pi находит ключ

pi берёт учётные данные из двух мест, в таком порядке приоритета:

1. переменная окружения `DEEPSEEK_API_KEY`;
2. файл `~/.pi/agent/auth.json`.

Здесь используется второй вариант: `scripts/setup.sh` пишет туда

```json
{
  "deepseek": { "type": "api_key", "key": "sk-..." }
}
```

с правами `600`. Ключ не попадает ни в репозиторий, ни в `~/.zshrc`, ни в окружение
посторонних процессов. Тот же файл можно заполнить интерактивно командой `/login` внутри pi.

Каталог конфигов переопределяется переменной `PI_CODING_AGENT_DIR` — скрипт её учитывает.

## Настройки по умолчанию

`~/.pi/agent/settings.json` — глобальные настройки pi. Из репозитория туда уезжает только:

```json
{
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-v4-flash"
}
```

Настройки конкретного проекта кладутся в `.pi/settings.json` внутри этого проекта и
перекрывают глобальные. Полный список параметров — в [документации pi](https://pi.dev/docs/latest/settings).

## Модели

DeepSeek — встроенный провайдер pi (начиная с версий, где каталог содержит `deepseek.json`),
поэтому кастомный `~/.pi/agent/models.json` из
[инструкции DeepSeek](https://api-docs.deepseek.com/quick_start/agent_integrations/pi_mono/) не нужен.
Встроенный каталог уже содержит нужные `contextWindow`, `maxTokens`, `thinkingFormat` и цены.

| id | Контекст | Макс. выход | Reasoning | Картинки | $ / 1M вход | $ / 1M выход |
|----|----------|-------------|-----------|----------|-------------|--------------|
| `deepseek-v4-flash` | 1M | 384K | да | нет | 0.14 | 0.28 |
| `deepseek-v4-flash-vision-exp` | 1M | 384K | да | да | 0.14 | 0.28 |
| `deepseek-v4-pro` | 1M | 384K | да | нет | 0.435 | 0.87 |

Проверить, что видит pi:

```bash
pi --list-models deepseek
```

Запустить с конкретной моделью, минуя настройки:

```bash
pi --provider deepseek --model deepseek-v4-pro
```

Уровень «размышлений» переключается командой `/thinking` или флагом `--thinking high`.

## Ручная настройка без скрипта

```bash
npm install -g @earendil-works/pi-coding-agent
mkdir -p ~/.pi/agent
printf '{\n  "deepseek": { "type": "api_key", "key": "%s" }\n}\n' "$DEEPSEEK_API_KEY" > ~/.pi/agent/auth.json
chmod 600 ~/.pi/agent/auth.json
cp conf/settings.json ~/.pi/agent/settings.json
```

## Диагностика

| Симптом | Что делать |
|---------|------------|
| `No models available` | Ключ не найден: проверьте `~/.pi/agent/auth.json` и права на файл |
| `setup.sh` печатает `HTTP 401` | Ключ неверный или отозван — перевыпустите на platform.deepseek.com |
| `setup.sh` печатает `HTTP 402` | На балансе DeepSeek нет средств |
| Модели не появились после `npm update` | `pi update` обновляет каталоги моделей |

Быстрая проверка ключа в обход pi:

```bash
set -a; . .env; set +a
curl -s -o /dev/null -w '%{http_code}\n' https://api.deepseek.com/models \
  -H "Authorization: Bearer $key_deepseek"
```

Проверка, какой провайдер и модель активны внутри сессии pi (переменные доступны
инструменту `bash` агента): `echo "$PI_PROVIDER/$PI_MODEL"`.

## Ссылки

- [pi.dev](https://pi.dev/) · [документация](https://pi.dev/docs/latest) · [GitHub](https://github.com/earendil-works/pi)
- [Провайдеры и ключи](https://pi.dev/docs/latest/providers) · [Кастомные модели](https://pi.dev/docs/latest/models)
- [DeepSeek API](https://api-docs.deepseek.com/) · [Ключи](https://platform.deepseek.com/api_keys)
