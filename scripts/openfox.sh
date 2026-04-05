#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

pid_is_running() {
  local pid="${1:-}"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

process_cwd() {
  local pid="${1:-}"
  local cwd=""

  [[ -n "$pid" ]] || return 1

  if command -v lsof >/dev/null 2>&1; then
    cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1)"
  fi

  if [[ -z "$cwd" ]] && command -v pwdx >/dev/null 2>&1; then
    cwd="$(pwdx "$pid" 2>/dev/null | awk '{print $2}')"
  fi

  [[ -n "$cwd" ]] || return 1
  printf '%s\n' "$cwd"
}

list_project_node_script_pids() {
  local script_name="$1"
  local line=""
  local pid=""
  local cmd=""
  local cwd=""

  while IFS= read -r line; do
    pid="$(printf '%s\n' "$line" | awk '{print $1}')"
    [[ "$pid" =~ ^[0-9]+$ ]] || continue

    cmd="$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')"
    [[ "$cmd" == *node* ]] || continue
    [[ "$cmd" == *"$script_name"* ]] || continue

    cwd="$(process_cwd "$pid" || true)"
    [[ "$cwd" == "$PROJECT_ROOT" ]] || continue
    printf '%s\n' "$pid"
  done < <(ps -axo pid=,command=)
}

unique_pid_list() {
  local seen=" "
  local pid=""
  local output=""

  for pid in "$@"; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    if [[ "$seen" == *" $pid "* ]]; then
      continue
    fi
    seen+="$pid "
    output+="$pid"$'\n'
  done

  printf '%s' "$output"
}

collect_project_worker_pids() {
  local bot_pids=""
  local webhook_pids=""

  bot_pids="$(list_project_node_script_pids 'telegram-bot.mjs' || true)"
  webhook_pids="$(list_project_node_script_pids 'telegram-webhook-handler.mjs' || true)"

  unique_pid_list $bot_pids $webhook_pids
}

format_pid_csv() {
  local pids="$1"
  printf '%s' "$pids" | tr '\n' ',' | sed 's/,$//'
}

terminate_pid() {
  local pid="$1"
  local label="${2:-process}"

  if ! pid_is_running "$pid"; then
    return 0
  fi

  printf 'Stopping %s (PID %s)...\n' "$label" "$pid"
  kill -TERM "$pid" 2>/dev/null || true
}

force_kill_pid() {
  local pid="$1"
  local label="${2:-process}"

  if ! pid_is_running "$pid"; then
    return 0
  fi

  printf '%s (PID %s) did not exit after SIGTERM, sending SIGKILL.\n' "$label" "$pid"
  kill -KILL "$pid" 2>/dev/null || true
}

usage() {
  cat <<'EOF'
OpenFox command line helper

Usage:
  openfox start [-d]
  openfox stop
  openfox status
  openfox configure
  openfox uninstall
  openfox help

Options:
  start -d    Start in the background (detached), writing logs to openfox.log

Notes:
  - `openfox uninstall` runs the guided uninstall flow.
  - You can pass uninstall flags through environment variables:
      OPENFOX_UNINSTALL_REMOVE_OPENCODE=yes
      OPENFOX_UNINSTALL_YES=yes
      OPENFOX_UNINSTALL_DRY_RUN=yes
EOF
}

start_openfox() {
  local detach=0
  if [[ "${1:-}" == '-d' ]]; then
    detach=1
  fi

  # Ensure opencode and common tool paths are available in non-login shells.
  export PATH="${HOME}/.opencode/bin:/opt/homebrew/bin:/usr/local/bin:${HOME}/.local/bin:${PATH}"

  if [[ "$detach" -eq 1 ]]; then
    local log_file="$PROJECT_ROOT/openfox.log"
    local pid_file="$PROJECT_ROOT/openfox.pid"
    local active_workers=""
    local active_workers_csv=""

    active_workers="$(collect_project_worker_pids || true)"
    if [[ -n "$active_workers" ]]; then
      active_workers_csv="$(format_pid_csv "$active_workers")"
      printf 'OpenFox is already running (PID %s).\n' "$active_workers_csv"
      return 0
    fi

    if [[ -f "$pid_file" ]]; then
      local current_pid=""
      current_pid="$(cat "$pid_file" 2>/dev/null || true)"
      if [[ -n "$current_pid" ]] && pid_is_running "$current_pid"; then
        local current_cwd=""
        current_cwd="$(process_cwd "$current_pid" || true)"
        if [[ "$current_cwd" == "$PROJECT_ROOT" ]]; then
          printf 'OpenFox is already running (PID %s).\n' "$current_pid"
          return 0
        fi
      fi
      if [[ -n "$current_pid" ]]; then
        printf 'OpenFox pid file is stale, removing %s.\n' "$pid_file"
        rm -f "$pid_file"
      fi
    fi

    nohup npm --prefix "$PROJECT_ROOT" start >"$log_file" 2>&1 &
    local openfox_pid=$!
    printf '%s\n' "$openfox_pid" >"$pid_file"
    printf 'OpenFox started in background (PID %s).\n' "$openfox_pid"
    printf 'Log file: %s\n' "$log_file"
  else
    local active_workers=""
    local active_workers_csv=""

    active_workers="$(collect_project_worker_pids || true)"
    if [[ -n "$active_workers" ]]; then
      active_workers_csv="$(format_pid_csv "$active_workers")"
      printf 'OpenFox is already running (PID %s).\n' "$active_workers_csv"
      return 0
    fi

    npm --prefix "$PROJECT_ROOT" start
  fi
}

stop_openfox() {
  local pid_file="$PROJECT_ROOT/openfox.pid"
  local pid=""
  local worker_pids=""
  local all_pids=""
  local target_pid=""

  if [[ -f "$pid_file" ]]; then
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -z "$pid" ]]; then
      printf 'OpenFox pid file is empty, removing stale file.\n'
      rm -f "$pid_file"
    fi
  fi

  worker_pids="$(collect_project_worker_pids || true)"
  all_pids="$(unique_pid_list ${pid:-} $worker_pids)"

  if [[ -z "$all_pids" ]]; then
    if [[ -f "$pid_file" ]]; then
      rm -f "$pid_file"
    fi
    printf 'OpenFox is not running.\n'
    return 0
  fi

  for target_pid in $all_pids; do
    [[ -n "$target_pid" ]] || continue
    terminate_pid "$target_pid" "OpenFox process"
  done

  sleep 1

  for target_pid in $all_pids; do
    [[ -n "$target_pid" ]] || continue
    force_kill_pid "$target_pid" "OpenFox process"
  done

  rm -f "$pid_file"
}

status_openfox() {
  local pid_file="$PROJECT_ROOT/openfox.pid"
  local active_workers=""
  local active_workers_csv=""

  active_workers="$(collect_project_worker_pids || true)"
  if [[ -n "$active_workers" ]]; then
    active_workers_csv="$(format_pid_csv "$active_workers")"
    printf 'OpenFox status: running (PID %s)\n' "$active_workers_csv"
    return 0
  fi

  if [[ ! -f "$pid_file" ]]; then
    printf 'OpenFox status: stopped\n'
    return 0
  fi

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    printf 'OpenFox status: running (PID %s)\n' "$pid"
  else
    printf 'OpenFox status: stopped (stale pid file)\n'
  fi
}

uninstall_openfox() {
  bash "$SCRIPT_DIR/uninstall-openfox.sh" "$PROJECT_ROOT"
}

configure_openfox() {
  OPENFOX_INSTALL_DIR="$PROJECT_ROOT" OPENFOX_SKIP_REPO_UPDATE=yes OPENFOX_START_NOW=no bash "$SCRIPT_DIR/install-openfox.sh" "$PROJECT_ROOT"
}

main() {
  local command="${1:-help}"
  case "$command" in
    start)
      start_openfox "${2:-}"
      ;;
    stop)
      stop_openfox
      ;;
    status)
      status_openfox
      ;;
    configure)
      configure_openfox
      ;;
    uninstall)
      uninstall_openfox
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      printf 'Unknown command: %s\n\n' "$command" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
