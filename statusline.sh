#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
DUR_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
H5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
D7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)

DIM='\033[2m'; RST='\033[0m'
WHITE='\033[97m'; CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; MAG='\033[35m'

# git branch + dirty marker
GIT=""
if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$DIR" symbolic-ref --short HEAD 2>/dev/null || git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null | head -1)" ]; then
    GIT=$(printf " ${MAG}%s${YELLOW}*${RST}" "$BRANCH")
  else
    GIT=$(printf " ${MAG}%s${RST}" "$BRANCH")
  fi
fi

# green under 50%, yellow under 80%, red above
lim_color() { if [ "$1" -ge 80 ]; then printf "$RED"; elif [ "$1" -ge 50 ]; then printf "$YELLOW"; else printf "$GREEN"; fi; }

# context bar, color by usage
C=$(lim_color "$PCT")
FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '#')$(printf '%*s' "$EMPTY" '' | tr ' ' '-')

LIMITS=""
if [ -n "$H5" ]; then LIMITS="${LIMITS} ${DIM}|${RST} 5h $(lim_color "$H5")${H5}%%${RST}"; fi
if [ -n "$D7" ]; then LIMITS="${LIMITS} ${DIM}|${RST} 7d $(lim_color "$D7")${D7}%%${RST}"; fi

MINS=$((DUR_MS / 60000))
DIRNAME=$(basename "$DIR")

printf "${CYAN}%s${RST} ${DIM}|${RST} ${WHITE}%s${RST}%s ${DIM}|${RST} ${C}[%s] %s%%${RST} ${DIM}|${RST} \$%.2f ${DIM}|${RST} ${GREEN}+%s${RST}/${RED}-%s${RST} ${DIM}|${RST} %sm${LIMITS}\n" \
  "$MODEL" "$DIRNAME" "$GIT" "$BAR" "$PCT" "$COST" "$ADDED" "$REMOVED" "$MINS"
