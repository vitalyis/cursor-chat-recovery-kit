#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=bin/lib/cursor_paths.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/cursor_paths.sh"

# === Настройки ===
WS_BASE="$(cursor_workspace_storage_dir)"

# Какие файлы считаем чатами (разные версии Cursor):
CHAT_PATTERNS=(
  -name "chat.json"
  -o -name "*chats*.json"
  -o -name "*chat*.sqlite"
  -o -name "state.vscdb"
)

usage() {
  cat <<'EOF'
Cursor Chat Recover — утилита для поиска и восстановления чатов Cursor.

Использование:
  # 1) Просканировать и вывести топ кандидатов (по размеру/дате)
  ./cursor-chat-recover.sh scan

  # 2) Показать все workspace IDs с датами последних изменений
  ./cursor-chat-recover.sh workspaces

  # 3) Скопировать чат-файлы из одного workspace в другой (dry-run)
  ./cursor-chat-recover.sh copy <SRC_WS_ID> <DST_WS_ID> [--apply]

  # 4) Узнать текущий (самый свежий) workspace ID по активности
  ./cursor-chat-recover.sh guess-latest

Примечания:
- Путь: $(cursor_workspace_storage_dir)
- По умолчанию copy работает в режиме dry-run. Добавь --apply, чтобы реально копировать.
- Перед копированием закрой Cursor.
EOF
}

need_ws_base() {
  if [[ ! -d "$WS_BASE" ]]; then
    echo "❌ Не найден каталог: $WS_BASE"
    exit 1
  fi
}

human_date() {
  # macOS stat -> epoch -> human
  date -r "$1" "+%Y-%m-%d %H:%M:%S"
}

scan() {
  need_ws_base
  echo "🔎 Сканирую чат-файлы под: $WS_BASE"
  # Соберем список: size_bytes|mtime_epoch|workspace_id|relative_path
  # shellcheck disable=2016
  find "$WS_BASE" \( "${CHAT_PATTERNS[@]}" \) -type f -print0 |
  while IFS= read -r -d '' f; do
    sz=$(stat -f "%z" "$f" 2>/dev/null || echo 0)
    mt=$(stat -f "%m" "$f" 2>/dev/null || echo 0)
    wsid=$(basename "$(dirname "$f")")
    rel="${f#"${WS_BASE}/$wsid/"}"
    echo "$sz|$mt|$wsid|$rel"
  done | sort -t'|' -k1,1nr -k2,2nr | awk -F'|' '
    BEGIN { printf("%-10s  %-19s  %-32s  %s\n","SIZE(KB)","MTIME","WORKSPACE_ID","FILE"); print "---------------------------------------------------------------------------------------------" }
    {
      kb = ($1/1024);
      cmd = "date -r "$2" +\"%Y-%m-%d %H:%M:%S\""
      cmd | getline d; close(cmd)
      printf("%-10.0f  %-19s  %-32s  %s\n", kb, d, $3, $4)
    }' | head -100
  echo ""
  echo "ℹ️  Смотри на самые большие/свежие файлы — это likely твои пропавшие чаты."
}

workspaces() {
  need_ws_base
  echo "📂 Перечень workspace ID с датой последней модификации:"
  find "$WS_BASE" -type d -maxdepth 1 -mindepth 1 -print0 |
  while IFS= read -r -d '' d; do
    wsid=$(basename "$d")
    # mtime по самым свежим файлам внутри
    latest=$(find "$d" -type f -exec stat -f "%m" {} \; 2>/dev/null | sort -nr | head -1 || echo 0)
    if [[ "$latest" == "0" ]]; then
      latest=$(stat -f "%m" "$d" 2>/dev/null || echo 0)
    fi
    echo "$latest|$wsid"
  done | sort -t'|' -k1,1nr | awk -F'|' '
    {
      cmd = "date -r "$1" +\"%Y-%m-%d %H:%M:%S\""
      cmd | getline d; close(cmd)
      printf("%-19s  %s\n", d, $2)
    }'
}

guess_latest() {
  need_ws_base
  echo "🤔 Угадываю самый свежий workspace..."
  latest_ws=$(find "$WS_BASE" -type d -maxdepth 1 -mindepth 1 -print0 |
  while IFS= read -r -d '' d; do
    wsid=$(basename "$d")
    latest=$(find "$d" -type f -exec stat -f "%m" {} \; 2>/dev/null | sort -nr | head -1 || echo 0)
    if [[ "$latest" == "0" ]]; then
      latest=$(stat -f "%m" "$d" 2>/dev/null || echo 0)
    fi
    echo "$latest|$wsid"
  done | sort -t'|' -k1,1nr | head -1 | cut -d'|' -f2)
  
  if [[ -n "$latest_ws" ]]; then
    echo "✅ Вероятно, активный workspace: $latest_ws"
    # Покажем что там есть
    echo "📋 Файлы чатов в нем:"
    find "$WS_BASE/$latest_ws" \( "${CHAT_PATTERNS[@]}" \) -type f 2>/dev/null |
    while read -r f; do
      sz=$(stat -f "%z" "$f" 2>/dev/null || echo 0)
      mt=$(stat -f "%m" "$f" 2>/dev/null || echo 0)
      rel="${f#"${WS_BASE}/$latest_ws/"}"
      dt=$(date -r "$mt" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
      printf "  %8.0fKB  %s  %s\n" "$((sz/1024))" "$dt" "$rel"
    done
  else
    echo "❌ Не удалось определить активный workspace"
  fi
}

copy_chats() {
  need_ws_base
  local src_ws="$1"
  local dst_ws="$2"
  local apply_flag="${3:-}"
  
  local src_dir="$WS_BASE/$src_ws"
  local dst_dir="$WS_BASE/$dst_ws"
  
  if [[ ! -d "$src_dir" ]]; then
    echo "❌ Источник не найден: $src_dir"
    exit 1
  fi
  
  if [[ ! -d "$dst_dir" ]]; then
    echo "❌ Назначение не найдено: $dst_dir"
    exit 1
  fi
  
  echo "📋 Ищу чат-файлы в workspace: $src_ws"
  local chat_files=()
  while IFS= read -r -d '' f; do
    chat_files+=("$f")
  done < <(find "$src_dir" \( "${CHAT_PATTERNS[@]}" \) -type f -print0 2>/dev/null)
  
  if [[ ${#chat_files[@]} -eq 0 ]]; then
    echo "❌ Не найдено чат-файлов в workspace: $src_ws"
    exit 1
  fi
  
  echo "🔄 Найдено ${#chat_files[@]} чат-файл(ов):"
  for f in "${chat_files[@]}"; do
    rel="${f#"$src_dir/"}"
    sz=$(stat -f "%z" "$f" 2>/dev/null || echo 0)
    printf "  %8.0fKB  %s\n" "$((sz/1024))" "$rel"
  done
  
  if [[ "$apply_flag" != "--apply" ]]; then
    echo ""
    echo "🔍 DRY RUN режим. Чтобы реально скопировать, добавь --apply"
    echo "Команда будет:"
    for f in "${chat_files[@]}"; do
      rel="${f#"$src_dir/"}"
      dst_file="$dst_dir/$rel"
      dst_parent=$(dirname "$dst_file")
      echo "  mkdir -p '$dst_parent' && cp '$f' '$dst_file'"
    done
  else
    echo ""
    echo "🚀 Копирую файлы..."
    for f in "${chat_files[@]}"; do
      rel="${f#"$src_dir/"}"
      dst_file="$dst_dir/$rel"
      dst_parent=$(dirname "$dst_file")
      
      echo "  Copying: $rel"
      mkdir -p "$dst_parent"
      cp "$f" "$dst_file"
    done
    echo "✅ Готово! Скопировано ${#chat_files[@]} файл(ов) из $src_ws в $dst_ws"
    echo "🔄 Перезапусти Cursor, чтобы изменения вступили в силу."
  fi
}

# === Main ===
case "${1:-}" in
  scan)
    scan
    ;;
  workspaces)
    workspaces
    ;;
  guess-latest)
    guess_latest
    ;;
  copy)
    if [[ $# -lt 3 ]]; then
      echo "❌ Использование: $0 copy <SRC_WS_ID> <DST_WS_ID> [--apply]"
      exit 1
    fi
    copy_chats "$2" "$3" "${4:-}"
    ;;
  help|--help|-h)
    usage
    ;;
  "")
    usage
    ;;
  *)
    echo "❌ Неизвестная команда: $1"
    usage
    exit 1
    ;;
esac
