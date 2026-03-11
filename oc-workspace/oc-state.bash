#!/usr/bin/env bash
set -euo pipefail

ORIG_ARGS=("$@")
STATE_DIR="${OC_STATE_DIR:-$HOME/oc-state}"
LOCK_FILE="$STATE_DIR/.lock"
LOG_FILE="$STATE_DIR/requests.log"
WIP_FILE="$STATE_DIR/work-in-progress"
TODO_FILE="$STATE_DIR/what-to-do"
GUARD_FILE="$STATE_DIR/.awaiting-what-to-do"

mkdir -p "$STATE_DIR"
touch "$LOG_FILE"
exec 9>"$LOCK_FILE"
flock 9

init_state() {
  [[ -f "$WIP_FILE" ]] || printf 'false\n' > "$WIP_FILE"
  [[ -f "$TODO_FILE" ]] || : > "$TODO_FILE"
}

log_request() {
  local status="$1"
  local detail="$2"
  local ts argv
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf -v argv '%q ' "${ORIG_ARGS[@]}"
  printf '%s\tpid=%s\targv=%s\tstatus=%s\tdetail=%s\n' \
    "$ts" "$$" "${argv% }" "$status" "$detail" >> "$LOG_FILE"
}

fail() {
  local msg="$1"
  log_request "error" "$msg"
  printf '%s\n' "$msg" >&2
  exit 1
}

read_wip() {
  tr '[:upper:]' '[:lower:]' < "$WIP_FILE" | tr -d '[:space:]'
}

write_wip() {
  local value
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    true|false) ;;
    *) fail "work-in-progress must be true or false" ;;
  esac
  printf '%s\n' "$value" > "$WIP_FILE"
}

read_todo() {
  cat "$TODO_FILE"
}

write_todo() {
  printf '%s\n' "$1" > "$TODO_FILE"
}

step_from_todo() {
  local todo="$1"
  set -- $todo
  printf '%s\n' "${1:-}"
}

target_from_todo() {
  local todo="$1"
  set -- $todo
  printf '%s\n' "${2:-}"
}

valid_target() {
  local step="$1"
  local target="${2:-}"
  case "$step" in
    implement|reconsider|review|merge|fix)
      [[ "$target" =~ ^[0-9]+$ ]]
      ;;
    audit)
      [[ -z "$target" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

valid_transition() {
  local from_step="$1"
  local from_target="${2:-}"
  local to_step="$3"
  local to_target="${4:-}"

  if [[ -z "$from_step" ]]; then
    return 0
  fi

  # Any transition to the same step is forbidden.
  if [[ "$from_step" == "$to_step" ]]; then
    return 1
  fi

  case "$from_step:$to_step" in
    implement:review|implement:reconsider) return 0 ;;
    review:merge|review:fix) return 0 ;;
    reconsider:implement) return 0 ;;
    merge:audit) return 0 ;;
    fix:review|fix:reconsider) return 0 ;;
    audit:implement) return 0 ;;
    *) return 1 ;;
  esac
}

get_work_in_progress() {
  local current
  current="$(read_wip)"

  if [[ "$current" == "true" ]]; then
    if [[ -f "$GUARD_FILE" ]]; then
      write_wip false
      rm -f "$GUARD_FILE"
      log_request "ok" "guard triggered: returning false and persisting work-in-progress=false"
      printf 'false\n'
      return 0
    fi

    printf '%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$GUARD_FILE"
  fi

  log_request "ok" "returned work-in-progress=$current"
  printf '%s\n' "$current"
}

set_work_in_progress() {
  local value="$1"
  write_wip "$value"
  rm -f "$GUARD_FILE"
  log_request "ok" "set work-in-progress=$value"
}

get_what_to_do() {
  local todo
  todo="$(read_todo)"
  log_request "ok" "returned what-to-do=${todo:-<empty>}"
  printf '%s\n' "$todo"
}

set_what_to_do() {
  local step="$1"
  local target="${2:-}"
  local new_todo current_todo current_step current_target

  step="$(printf '%s' "$step" | tr '[:upper:]' '[:lower:]')"

  if ! valid_target "$step" "$target"; then
    fail "invalid what-to-do payload"
  fi

  current_todo="$(read_todo)"
  current_step="$(step_from_todo "$current_todo")"
  current_target="$(target_from_todo "$current_todo")"

  if ! valid_transition "$current_step" "$current_target" "$step" "$target"; then
    write_wip false
    rm -f "$GUARD_FILE"
    log_request "error" "invalid transition: ${current_todo:-<empty>} -> $step${target:+ $target}; work-in-progress forced to false"
    printf 'invalid transition: %s -> %s%s\n' \
      "${current_todo:-<empty>}" "$step" "${target:+ $target}" >&2
    exit 2
  fi

  if [[ -n "$target" ]]; then
    new_todo="$step $target"
  else
    new_todo="$step"
  fi

  write_todo "$new_todo"
  rm -f "$GUARD_FILE"
  log_request "ok" "set what-to-do=$new_todo"
}

usage() {
  cat <<'EOF'
Usage:
  oc-state get work-in-progress
  oc-state set work-in-progress true|false
  oc-state get what-to-do
  oc-state set what-to-do implement <issue_number>
  oc-state set what-to-do review <pr_number>
  oc-state set what-to-do reconsider <issue_number>
  oc-state set what-to-do merge <pr_number>
  oc-state set what-to-do fix <pr_number>
  oc-state set what-to-do audit
EOF
}

main() {
  init_state

  local cmd="${1:-}"
  local key="${2:-}"

  case "$cmd:$key" in
    get:work-in-progress)
      [[ $# -eq 2 ]] || fail "usage: oc-state get work-in-progress"
      get_work_in_progress
      ;;
    set:work-in-progress)
      [[ $# -eq 3 ]] || fail "usage: oc-state set work-in-progress true|false"
      set_work_in_progress "$3"
      ;;
    get:what-to-do)
      [[ $# -eq 2 ]] || fail "usage: oc-state get what-to-do"
      get_what_to_do
      ;;
    set:what-to-do)
      case $# in
        3) set_what_to_do "$3" ;;
        4) set_what_to_do "$3" "$4" ;;
        *) fail "usage: oc-state set what-to-do <implement|review|reconsider|merge|fix> <number> | audit" ;;
      esac
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
