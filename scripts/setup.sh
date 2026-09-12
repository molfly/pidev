#!/usr/bin/env bash
# Настройка pi (https://pi.dev) для работы с DeepSeek на macOS.
# Читает ключ из .env, ставит pi при необходимости, пишет ~/.pi/agent/{auth.json,settings.json}.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

die() { echo "Ошибка: $*" >&2; exit 1; }

# 1. Ключ из .env
[ -f "$ROOT/.env" ] || die "нет $ROOT/.env — скопируйте .env.template в .env и впишите ключ"
set -a; . "$ROOT/.env"; set +a
[ -n "${key_deepseek:-}" ] || die "в .env не задан key_deepseek"

# 2. Зависимости
command -v node >/dev/null || die "нужен Node.js: brew install node"
if ! command -v pi >/dev/null; then
  echo "Ставлю pi..."
  npm install -g @earendil-works/pi-coding-agent
fi
echo "pi $(pi --version)"

# Слияние JSON: существующие ключи других провайдеров/настроек не затираются.
# Патч передаётся через переменную окружения PATCH, чтобы не светить ключ в списке процессов.
merge_json() {
  PATCH="$2" node -e '
    const fs = require("fs");
    const file = process.argv[1];
    let cur = {};
    try { cur = JSON.parse(fs.readFileSync(file, "utf8") || "{}"); }
    catch (e) { if (e.code !== "ENOENT") { console.error(`Не разобрать ${file}: ${e.message}`); process.exit(1); } }
    fs.writeFileSync(file, JSON.stringify({ ...cur, ...JSON.parse(process.env.PATCH) }, null, 2) + "\n");
  ' "$1"
}

# 3. Ключ в ~/.pi/agent/auth.json
mkdir -p "$PI_DIR"
merge_json "$PI_DIR/auth.json" "$(key_deepseek="$key_deepseek" node -e \
  'console.log(JSON.stringify({ deepseek: { type: "api_key", key: process.env.key_deepseek } }))')"
chmod 600 "$PI_DIR/auth.json"
echo "Ключ записан: $PI_DIR/auth.json"

# 4. Провайдер и модель по умолчанию
merge_json "$PI_DIR/settings.json" "$(cat "$ROOT/conf/settings.json")"
echo "Настройки записаны: $PI_DIR/settings.json"

# 5. Проверка ключа у DeepSeek (заголовок идёт через stdin, а не через argv)
code=$(printf 'header = "Authorization: Bearer %s"\n' "$key_deepseek" |
  curl -sS -K - -o /dev/null -w '%{http_code}' https://api.deepseek.com/models)
[ "$code" = "200" ] || die "DeepSeek API ответил HTTP $code — проверьте key_deepseek в .env"
echo "Ключ принят DeepSeek API (HTTP 200)"

echo
echo "Готово. Доступные модели:"
pi --list-models deepseek
echo
echo "Запуск: pi   (сменить модель — /model или Ctrl+L)"
