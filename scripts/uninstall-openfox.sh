#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="$(basename -- "$0")"
TARGET_DIR="${1:-${OPENFOX_INSTALL_DIR:-$HOME/OpenFox}}"
REMOVE_OPENCODE="${OPENFOX_UNINSTALL_REMOVE_OPENCODE:-no}"
AUTO_YES="${OPENFOX_UNINSTALL_YES:-no}"
DRY_RUN="${OPENFOX_UNINSTALL_DRY_RUN:-no}"
REMOVE_OPENCODE_EXPLICIT=0
UNINSTALL_LANG=""
INTERACTIVE=0
PROMPT_FD=0
READ_KEY_TIMEOUT=1

if [[ -n "${OPENFOX_UNINSTALL_REMOVE_OPENCODE+x}" ]]; then
  REMOVE_OPENCODE_EXPLICIT=1
fi

normalize_uninstall_lang() {
  local value="${1:-}"
  value="${value%%.*}"
  value="$(printf '%s' "$value" | command tr '[:upper:]' '[:lower:]')"
  value="${value//_/-}"

  case "$value" in
    zh-tw|zh-hk|zh-mo|zh-hant)
      printf 'zh-TW'
      ;;
    zh|zh-cn|zh-sg|zh-hans)
      printf 'zh-CN'
      ;;
    en|en-us|en-gb)
      printf 'en'
      ;;
    *)
      printf 'en'
      ;;
  esac
}

init_uninstall_lang() {
  UNINSTALL_LANG="$(normalize_uninstall_lang "${OPENFOX_UNINSTALL_LANG:-${OPENFOX_LANG:-${LANG:-en}}}")"
}

i18n_text() {
  local key="$1"
  case "$UNINSTALL_LANG" in
    zh-TW)
      case "$key" in
        menu_header) printf 'OpenFox 解除安裝';;
        menu_hint) printf '\n使用 ↑/↓ 移動，按 Enter 確認。\n';;
        lang_title) printf '選擇解除安裝語言';;
        lang_opt_en) printf 'English';;
        lang_opt_zh_tw) printf '繁體中文';;
        lang_opt_zh_cn) printf '简体中文';;
        opt_yes) printf '是';;
        opt_no) printf '否';;
        log_target_dir) printf 'OpenFox 目標目錄：%%s';;
        log_remove_opencode_enabled) printf '若有安裝，將一併移除 opencode。';;
        log_dry_run_enabled) printf '已啟用 Dry-run，不會刪除任何檔案。';;
        prompt_proceed_uninstall) printf '要繼續解除安裝嗎？';;
        err_uninstall_cancelled) printf '使用者已取消解除安裝。';;
        warn_pid_empty) printf 'PID 檔案存在但內容為空：%%s';;
        log_stopping_process) printf '正在停止 OpenFox 程序：%%s';;
        warn_no_process) printf '找不到仍在執行的 PID：%%s';;
        warn_dir_not_found) printf '找不到 OpenFox 目錄：%%s';;
        log_removing_dir) printf '正在刪除 OpenFox 目錄：%%s';;
        log_removing_launcher) printf '正在刪除 OpenFox 啟動器：%%s';;
        warn_launcher_points_elsewhere) printf '找到啟動器但指向其他路徑，已略過：%%s';;
        prompt_remove_opencode) printf '是否也要移除這台機器上的 opencode？';;
        log_keep_opencode) printf '保留 opencode，不進行移除。';;
        log_removing_opencode) printf '正在移除這台機器上的 opencode...';;
        log_running_self_uninstall) printf '正在執行 opencode 官方卸載...';;
        log_running_brew_uninstall) printf '正在執行 Homebrew 卸載：%%s';;
        log_removing_opencode_binary) printf '正在移除殘留的 opencode 執行檔：%%s';;
        warn_self_uninstall_failed) printf 'opencode 官方卸載失敗，改用套件管理器清理。';;
        warn_opencode_binary_remove_failed) printf '無法移除殘留的 opencode 執行檔：%%s';;
        warn_opencode_still_exists) printf 'PATH 中仍可找到 opencode，請執行 `command -v opencode` 檢查剩餘安裝來源。';;
        warn_opencode_still_exists_at) printf 'PATH 中仍可找到 opencode：%%s';;
        log_opencode_removed) printf 'PATH 中已找不到 opencode。';;
        log_uninstall_completed) printf '解除安裝完成。';;
        *) printf '%s' "$key";;
      esac
      ;;
    zh-CN)
      case "$key" in
        menu_header) printf 'OpenFox 卸载';;
        menu_hint) printf '\n使用 ↑/↓ 移动，按 Enter 确认。\n';;
        lang_title) printf '选择卸载语言';;
        lang_opt_en) printf 'English';;
        lang_opt_zh_tw) printf '繁體中文';;
        lang_opt_zh_cn) printf '简体中文';;
        opt_yes) printf '是';;
        opt_no) printf '否';;
        log_target_dir) printf 'OpenFox 目标目录：%%s';;
        log_remove_opencode_enabled) printf '如果存在，将同时移除 opencode。';;
        log_dry_run_enabled) printf '已启用 Dry-run，不会删除任何文件。';;
        prompt_proceed_uninstall) printf '是否继续卸载？';;
        err_uninstall_cancelled) printf '用户已取消卸载。';;
        warn_pid_empty) printf 'PID 文件存在但内容为空：%%s';;
        log_stopping_process) printf '正在停止 OpenFox 进程：%%s';;
        warn_no_process) printf '找不到仍在运行的 PID：%%s';;
        warn_dir_not_found) printf '找不到 OpenFox 目录：%%s';;
        log_removing_dir) printf '正在删除 OpenFox 目录：%%s';;
        log_removing_launcher) printf '正在删除 OpenFox 启动器：%%s';;
        warn_launcher_points_elsewhere) printf '检测到启动器但指向其他路径，已跳过：%%s';;
        prompt_remove_opencode) printf '是否也移除这台机器上的 opencode？';;
        log_keep_opencode) printf '保留 opencode，不执行移除。';;
        log_removing_opencode) printf '正在移除这台机器上的 opencode...';;
        log_running_self_uninstall) printf '正在执行 opencode 官方卸载...';;
        log_running_brew_uninstall) printf '正在执行 Homebrew 卸载：%%s';;
        log_removing_opencode_binary) printf '正在移除残留的 opencode 可执行文件：%%s';;
        warn_self_uninstall_failed) printf 'opencode 官方卸载失败，改用包管理器清理。';;
        warn_opencode_binary_remove_failed) printf '无法移除残留的 opencode 可执行文件：%%s';;
        warn_opencode_still_exists) printf 'PATH 中仍能找到 opencode，请执行 `command -v opencode` 检查剩余安装来源。';;
        warn_opencode_still_exists_at) printf 'PATH 中仍能找到 opencode：%%s';;
        log_opencode_removed) printf 'PATH 中已找不到 opencode。';;
        log_uninstall_completed) printf '卸载完成。';;
        *) printf '%s' "$key";;
      esac
      ;;
    *)
      case "$key" in
        menu_header) printf 'OpenFox Uninstall';;
        menu_hint) printf '\nUse ↑/↓ to move, Enter to confirm.\n';;
        lang_title) printf 'Choose uninstall language';;
        lang_opt_en) printf 'English';;
        lang_opt_zh_tw) printf '繁體中文';;
        lang_opt_zh_cn) printf '简体中文';;
        opt_yes) printf 'Yes';;
        opt_no) printf 'No';;
        log_target_dir) printf 'OpenFox target directory: %%s';;
        log_remove_opencode_enabled) printf 'opencode will also be removed if found.';;
        log_dry_run_enabled) printf 'Dry-run mode enabled. No files will be deleted.';;
        prompt_proceed_uninstall) printf 'Proceed with uninstall?';;
        err_uninstall_cancelled) printf 'Uninstall cancelled by user.';;
        warn_pid_empty) printf 'PID file exists but is empty: %%s';;
        log_stopping_process) printf 'Stopping OpenFox process: %%s';;
        warn_no_process) printf 'No running process found for PID: %%s';;
        warn_dir_not_found) printf 'OpenFox directory not found: %%s';;
        log_removing_dir) printf 'Removing OpenFox directory: %%s';;
        log_removing_launcher) printf 'Removing OpenFox launcher: %%s';;
        warn_launcher_points_elsewhere) printf 'Launcher exists but points elsewhere, skipped: %%s';;
        prompt_remove_opencode) printf 'Also remove opencode from this machine?';;
        log_keep_opencode) printf 'Keeping opencode installed.';;
        log_removing_opencode) printf 'Removing opencode from this machine...';;
        log_running_self_uninstall) printf 'Running opencode self-uninstall...';;
        log_running_brew_uninstall) printf 'Running Homebrew uninstall: %%s';;
        log_removing_opencode_binary) printf 'Removing remaining opencode binary: %%s';;
        warn_self_uninstall_failed) printf 'opencode self-uninstall failed; falling back to package manager cleanup.';;
        warn_opencode_binary_remove_failed) printf 'Failed to remove remaining opencode binary: %%s';;
        warn_opencode_still_exists) printf 'opencode command still exists in PATH. Run `command -v opencode` to inspect remaining installation.';;
        warn_opencode_still_exists_at) printf 'opencode command still exists in PATH at: %%s';;
        log_opencode_removed) printf 'opencode appears to be removed from PATH.';;
        log_uninstall_completed) printf 'Uninstall completed.';;
        *) printf '%s' "$key";;
      esac
      ;;
  esac
}

i18n_printf() {
  local key="$1"
  shift
  printf "$(i18n_text "$key")" "$@"
}

init_prompt_io() {
  if [[ -t 0 ]]; then
    INTERACTIVE=1
    PROMPT_FD=0
    return
  fi

  if { exec 3<>/dev/tty; } 2>/dev/null; then
    INTERACTIVE=1
    PROMPT_FD=3
    return
  fi

  INTERACTIVE=0
  PROMPT_FD=0
}

close_prompt_io() {
  if [[ "$PROMPT_FD" -eq 3 ]]; then
    exec 3<&-
    exec 3>&-
  fi
}

tty_printf() {
  if [[ "$INTERACTIVE" -eq 1 ]]; then
    printf '%b' "$1" >/dev/tty
  fi
}

menu_prompt() {
  local title="$1"
  shift
  local options=("$@")
  local selected=0
  local key=""
  local seq=""
  local key_type=""

  if [[ "$INTERACTIVE" -ne 1 ]]; then
    printf '0'
    return
  fi

  local saved_tty
  saved_tty="$(stty -g </dev/tty 2>/dev/null || true)"

  while true; do
    tty_printf '\033[2J\033[H'
    tty_printf "$(i18n_text 'menu_header')\n\n$title\n\n"

    local i
    for ((i = 0; i < ${#options[@]}; i += 1)); do
      if [[ $i -eq $selected ]]; then
        tty_printf "  \033[36m> ${options[$i]}\033[0m\n"
      else
        tty_printf "    ${options[$i]}\n"
      fi
    done

    tty_printf "$(i18n_text 'menu_hint')"

    stty -echo -icanon min 1 time 0 </dev/tty 2>/dev/null || true
    key=""
    IFS= read -r -s -n 1 -u "$PROMPT_FD" key || true

    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -r -s -n 1 -t "$READ_KEY_TIMEOUT" -u "$PROMPT_FD" seq || true
      key+="$seq"
      seq=""
      IFS= read -r -s -n 1 -t "$READ_KEY_TIMEOUT" -u "$PROMPT_FD" seq || true
      key+="$seq"
    fi
    stty "$saved_tty" </dev/tty 2>/dev/null || true

    key_type="$key"
    case "$key" in
      $'\x1b[A'|$'\x1bOA'|k|K)
        key_type='up'
        ;;
      $'\x1b[B'|$'\x1bOB'|j|J)
        key_type='down'
        ;;
      '')
        key_type='enter'
        ;;
    esac

    case "$key_type" in
      up)
        if [[ $selected -gt 0 ]]; then
          selected=$((selected - 1))
        fi
        ;;
      down)
        if [[ $selected -lt $((${#options[@]} - 1)) ]]; then
          selected=$((selected + 1))
        fi
        ;;
      enter)
        tty_printf '\033[2J\033[H'
        printf '%s' "$selected"
        return
        ;;
    esac
  done
}

choose_uninstall_language() {
  if [[ "$INTERACTIVE" -ne 1 ]]; then
    return
  fi

  if [[ -n "${OPENFOX_UNINSTALL_LANG:-}" || -n "${OPENFOX_LANG:-}" ]]; then
    return
  fi

  local choice
  choice="$(menu_prompt "$(i18n_text 'lang_title')" "$(i18n_text 'lang_opt_en')" "$(i18n_text 'lang_opt_zh_tw')" "$(i18n_text 'lang_opt_zh_cn')")"
  case "$choice" in
    0) UNINSTALL_LANG='en' ;;
    1) UNINSTALL_LANG='zh-TW' ;;
    2) UNINSTALL_LANG='zh-CN' ;;
  esac
}

log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

warn() {
  printf '[%s] WARN: %s\n' "$SCRIPT_NAME" "$*" >&2
}

fail() {
  printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2
  exit 1
}

is_truthy() {
  local value="${1:-}"
  [[ "$value" =~ ^(1|true|yes|on)$ ]]
}

confirm() {
  local prompt="$1"
  local default_answer="$2"

  if is_truthy "$AUTO_YES"; then
    return 0
  fi

  if [[ "$INTERACTIVE" -ne 1 ]]; then
    [[ "$default_answer" == "yes" ]]
    return
  fi

  if [[ "$default_answer" == "yes" ]]; then
    [[ "$(menu_prompt "$prompt" "$(i18n_text 'opt_yes')" "$(i18n_text 'opt_no')")" == "0" ]]
    return
  fi

  [[ "$(menu_prompt "$prompt" "$(i18n_text 'opt_no')" "$(i18n_text 'opt_yes')")" == "1" ]]
}

run_cmd() {
  if is_truthy "$DRY_RUN"; then
    log "[dry-run] $*"
    return 0
  fi
  "$@"
}

stop_openfox_process() {
  local pid_file="$TARGET_DIR/openfox.pid"
  if [[ ! -f "$pid_file" ]]; then
    return
  fi

  local pid=""
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -z "$pid" ]]; then
    warn "$(i18n_printf 'warn_pid_empty' "$pid_file")"
    run_cmd rm -f "$pid_file"
    return
  fi

  if kill -0 "$pid" 2>/dev/null; then
    log "$(i18n_printf 'log_stopping_process' "$pid")"
    run_cmd kill -TERM "$pid"
  else
    warn "$(i18n_printf 'warn_no_process' "$pid")"
  fi

  run_cmd rm -f "$pid_file"
}

remove_openfox_files() {
  if [[ ! -e "$TARGET_DIR" ]]; then
    warn "$(i18n_printf 'warn_dir_not_found' "$TARGET_DIR")"
    return
  fi

  log "$(i18n_printf 'log_removing_dir' "$TARGET_DIR")"
  run_cmd rm -rf "$TARGET_DIR"
}

remove_openfox_launcher() {
  local launcher_paths=(
    "$HOME/.local/bin/openfox"
    "$HOME/.local/bin/openfox.cmd"
  )
  local launcher_path=""
  for launcher_path in "${launcher_paths[@]}"; do
    if [[ ! -f "$launcher_path" ]]; then
      continue
    fi

    if grep -Fq "$TARGET_DIR/scripts/openfox.sh" "$launcher_path" 2>/dev/null; then
      log "$(i18n_printf 'log_removing_launcher' "$launcher_path")"
      run_cmd rm -f "$launcher_path"
    else
      warn "$(i18n_printf 'warn_launcher_points_elsewhere' "$launcher_path")"
    fi
  done
}

remove_managed_block() {
  local rc_file="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local temp_file=""

  [[ -f "$rc_file" ]] || return 0

  temp_file="$(mktemp)"
  awk -v begin="$begin_marker" -v end="$end_marker" '
    index($0, begin) {
      skip = 1
      next
    }
    index($0, end) {
      skip = 0
      next
    }
    !skip {
      print
    }
  ' "$rc_file" >"$temp_file"

  run_cmd mv "$temp_file" "$rc_file"
}

remove_openfox_completions() {
  run_cmd rm -f "$HOME/.local/share/openfox/zsh-completions/_openfox"
  run_cmd rm -f "$HOME/.local/share/bash-completion/completions/openfox"

  remove_managed_block "$HOME/.zshrc" '# >>> OpenFox zsh completion >>>' '# <<< OpenFox zsh completion <<<'
  remove_managed_block "$HOME/.bash_profile" '# >>> OpenFox bash completion >>>' '# <<< OpenFox bash completion <<<'
  remove_managed_block "$HOME/.bashrc" '# >>> OpenFox bash completion >>>' '# <<< OpenFox bash completion <<<'
}

opencode_command_path() {
  command -v opencode 2>/dev/null || true
}

remove_remaining_opencode_binary() {
  local remaining_path="${1:-}"
  local parent_dir=""

  [[ -n "$remaining_path" ]] || return 1
  [[ -f "$remaining_path" ]] || return 1

  log "$(i18n_printf 'log_removing_opencode_binary' "$remaining_path")"
  if ! run_cmd rm -f "$remaining_path"; then
    warn "$(i18n_printf 'warn_opencode_binary_remove_failed' "$remaining_path")"
    return 1
  fi

  parent_dir="$(dirname -- "$remaining_path")"
  run_cmd rmdir "$parent_dir" 2>/dev/null || true
  hash -r 2>/dev/null || true
  return 0
}

resolve_remove_opencode() {
  if is_truthy "$REMOVE_OPENCODE"; then
    return 0
  fi

  if [[ $REMOVE_OPENCODE_EXPLICIT -eq 1 ]]; then
    return 1
  fi

  if ! command -v opencode >/dev/null 2>&1; then
    return 1
  fi

  if confirm "$(i18n_text 'prompt_remove_opencode')" no; then
    return 0
  fi

  return 1
}

uninstall_opencode() {
  if ! resolve_remove_opencode; then
    log "$(i18n_text 'log_keep_opencode')"
    return
  fi

  log "$(i18n_text 'log_removing_opencode')"

  if command -v opencode >/dev/null 2>&1; then
    local uninstall_args=(uninstall --force)
    if is_truthy "$DRY_RUN"; then
      uninstall_args+=(--dry-run)
    fi

    log "$(i18n_text 'log_running_self_uninstall')"
    run_cmd opencode "${uninstall_args[@]}" || warn "$(i18n_text 'warn_self_uninstall_failed')"
  fi

  if command -v brew >/dev/null 2>&1; then
    if brew list --formula 2>/dev/null | grep -qx 'opencode'; then
      log "$(i18n_printf 'log_running_brew_uninstall' 'brew uninstall --force opencode')"
      run_cmd brew uninstall --force opencode || true
    fi
    if brew list --formula 2>/dev/null | grep -qx 'anomalyco/tap/opencode'; then
      log "$(i18n_printf 'log_running_brew_uninstall' 'brew uninstall --force anomalyco/tap/opencode')"
      run_cmd brew uninstall --force anomalyco/tap/opencode || true
    fi
  fi

  if command -v npm >/dev/null 2>&1; then
    if npm ls -g opencode-ai --depth=0 >/dev/null 2>&1; then
      run_cmd npm uninstall -g opencode-ai || true
    fi
  fi

  hash -r 2>/dev/null || true

  local remaining_path=""
  remaining_path="$(opencode_command_path)"
  if [[ -n "$remaining_path" ]]; then
    remove_remaining_opencode_binary "$remaining_path" || true
    remaining_path="$(opencode_command_path)"
  fi

  if [[ -n "$remaining_path" ]]; then
    warn "$(i18n_printf 'warn_opencode_still_exists_at' "$remaining_path")"
    warn "$(i18n_text 'warn_opencode_still_exists')"
  else
    log "$(i18n_text 'log_opencode_removed')"
  fi
}

main() {
  init_prompt_io
  trap close_prompt_io EXIT
  init_uninstall_lang
  choose_uninstall_language
  [[ "$TARGET_DIR" == */ ]] && TARGET_DIR="${TARGET_DIR%/}"

  log "$(i18n_printf 'log_target_dir' "$TARGET_DIR")"
  if is_truthy "$REMOVE_OPENCODE"; then
    log "$(i18n_text 'log_remove_opencode_enabled')"
  fi
  if is_truthy "$DRY_RUN"; then
    log "$(i18n_text 'log_dry_run_enabled')"
  fi

  if ! confirm "$(i18n_text 'prompt_proceed_uninstall')" no; then
    fail "$(i18n_text 'err_uninstall_cancelled')"
  fi

  stop_openfox_process
  remove_openfox_files
  remove_openfox_launcher
  remove_openfox_completions
  uninstall_opencode

  log "$(i18n_text 'log_uninstall_completed')"
}

main "$@"
