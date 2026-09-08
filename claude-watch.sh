#!/bin/bash
# Follow the newest Claude Code session log and print thinking, commands,
# edits, and tool output as they happen. Usage: claude-watch.sh [project-dir] [parent-pid]
# If parent-pid is given, exit when that process is gone.
PROJ="${1:-$PWD}"
PARENT="$2"
SLUG=$(echo "$PROJ" | sed 's|/|-|g')
DIR="$HOME/.claude/projects/$SLUG"
[ -d "$DIR" ] || DIR="$HOME/.claude/projects"

newest() { ls -t "$DIR"/*.jsonl "$DIR"/*/*.jsonl 2>/dev/null | head -1; }

FILTER='
def c(n; s): "[" + n + "m" + s + "[0m";
def trunc(n): split("\n") as $l | if ($l|length) > n then ($l[0:n]|join("\n")) + "\n" + c("2"; "... " + (($l|length) - n|tostring) + " more lines") else . end;
def num: tostring | if length >= 4 then . else (" " * (4 - length)) + . end;
if .type == "assistant" then
  .message.content[] |
  if .type == "thinking" then
    (if (.thinking|length) > 0 then "\n" + c("35"; "[thinking]") + "\n" + c("2"; .thinking)
     else "\n" + c("35"; "[thinking]") + c("2"; " (content redacted by API; enable showThinkingSummaries and restart)") end)
  elif .type == "text" then
    "\n" + c("34"; "[claude] ") + (.text|split("\n")[0]|.[0:160])
  elif .type == "tool_use" then
    if .name == "Bash" then
      "\n" + c("33"; "$ ") + c("1"; .input.command) + (if .input.description then "\n" + c("2"; "# " + .input.description) else "" end)
    elif .name == "Edit" then
      "\n" + c("36"; "[edit] ") + .input.file_path
    elif .name == "Write" then
      "\n" + c("36"; "[write] ") + .input.file_path + "\n" + c("32"; (.input.content | trunc(80)))
    elif .name == "Read" then
      "\n" + c("36"; "[read] ") + .input.file_path
    elif .name == "Grep" or .name == "Glob" then
      "\n" + c("36"; "[" + (.name|ascii_downcase) + "] ") + (.input.pattern // "") + c("2"; " " + (.input.path // ""))
    elif .name == "Agent" then
      "\n" + c("36"; "[agent] ") + (.input.description // "")
    else
      "\n" + c("36"; "[" + .name + "] ") + (.input|tostring|.[0:200])
    end
  else empty end
elif .type == "user" then
  (if (.toolUseResult|type) == "object" then .toolUseResult else {} end) as $r |
  if (.message.content|type) == "string" then
    "\n" + c("32"; "[you] ") + (.message.content|.[0:200])
  elif $r.structuredPatch then
    # PR-style hunk: line number, then removed (red bg) / added (green bg) / context (dim)
    ($r.structuredPatch[] |
      reduce .lines[] as $l ({o: .oldStart, n: .newStart, out: []};
        if ($l|startswith("+")) then .out += [c("48;5;22"; (.n|num) + " + " + $l[1:])] | .n += 1
        elif ($l|startswith("-")) then .out += [c("48;5;52"; (.o|num) + " - " + $l[1:])] | .o += 1
        else .out += [c("2"; (.n|num) + "   " + $l[1:])] | .o += 1 | .n += 1 end)
      | .out[])
  elif $r.stdout != null then
    (($r.stdout // "") + (if ($r.stderr // "") != "" then "\n" + c("31"; $r.stderr) else "" end)) | select(length > 0) | trunc(25)
  elif $r.type == "text" then
    c("2"; "(read " + (($r.file.content // "")|split("\n")|length|tostring) + " lines)")
  elif (.message.content|type) == "array" then
    (.message.content[] | select(.type == "tool_result") |
      (if (.content|type) == "string" then .content else ([.content[]? | .text // ""]|join("\n")) end) | select(length > 0) | trunc(15))
  else empty end
else empty end
'

printf '\033[2mwatching %s\033[0m\n' "$DIR"
CUR=""
TAILPID=""
trap '[ -n "$TAILPID" ] && kill "$TAILPID" 2>/dev/null; exit' INT TERM
while true; do
  if [ -n "$PARENT" ] && ! kill -0 "$PARENT" 2>/dev/null; then
    [ -n "$TAILPID" ] && kill "$TAILPID" 2>/dev/null
    exit 0
  fi
  N=$(newest)
  if [ -n "$N" ] && [ "$N" != "$CUR" ]; then
    [ -n "$TAILPID" ] && kill "$TAILPID" 2>/dev/null
    CUR="$N"
    printf '\n\033[2m== session %s ==\033[0m\n' "$(basename "$CUR" .jsonl)"
    tail -n 0 -F "$CUR" 2>/dev/null | jq --unbuffered -r "$FILTER" &
    TAILPID=$!
  fi
  sleep 3
done
