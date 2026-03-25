#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
TTY_DEVICE="${TTY_DEVICE:-/dev/tty}"

GUI_MODE=0
ACTION=""
TARGET_FILE=""

usage() {
  cat <<'EOF'
Kullanim:
  ./log_rapor_araci.sh --gui
  ./log_rapor_araci.sh --list
  ./log_rapor_araci.sh --latest-report
  ./log_rapor_araci.sh --latest-log
  ./log_rapor_araci.sh --show /tam/yol/dosya.log

Bu arac, ETAP23 kurulum ve bakim akislari sirasinda kaydedilen rapor ve gunluk dosyalarini goruntuler.

Secenekler:
  --gui               Grafik arayuzlu log ve rapor aracini ac
  --list              Bulunan rapor ve gunluk dosyalarini listele
  --pick              Listeden dosya secip ac
  --latest-report     En yeni rapor dosyasini ac
  --latest-log        En yeni gunluk dosyasini ac
  --show DOSYA        Belirtilen dosyayi ac
  -h, --help          Bu yardimi goster
EOF
}

fail() {
  printf 'HATA: %s\n' "$*" >&2
  exit 1
}

has_tty() {
  [[ -t 1 && -r "${TTY_DEVICE}" && -w "${TTY_DEVICE}" ]]
}

print_line() {
  if has_tty; then
    printf '%b' "$*" >"${TTY_DEVICE}"
  else
    printf '%b' "$*"
  fi
}

pause_before_exit() {
  if has_tty; then
    printf '\nPencereyi kapatmadan once Enter tusuna basin...' >"${TTY_DEVICE}"
    read -r _ <"${TTY_DEVICE}" || sleep 10
  else
    printf '\nPencereyi kapatmadan once Enter tusuna basin...'
    read -r _ || sleep 10
  fi
}

read_line_from_user() {
  local reply=""

  if has_tty; then
    read -r reply <"${TTY_DEVICE}" || return 1
  else
    read -r reply || return 1
  fi

  printf '%s\n' "${reply}"
}

can_use_zenity() {
  command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

file_mtime() {
  local file_path="$1"

  if stat -c '%Y' "${file_path}" >/dev/null 2>&1; then
    stat -c '%Y' "${file_path}"
  else
    stat -f '%m' "${file_path}"
  fi
}

file_size_bytes() {
  local file_path="$1"

  if stat -c '%s' "${file_path}" >/dev/null 2>&1; then
    stat -c '%s' "${file_path}"
  else
    stat -f '%z' "${file_path}"
  fi
}

format_timestamp() {
  local unix_ts="$1"
  local formatted=""

  formatted="$(date -d "@${unix_ts}" '+%F %T' 2>/dev/null || true)"
  if [[ -z "${formatted}" ]]; then
    formatted="$(date -r "${unix_ts}" '+%F %T' 2>/dev/null || true)"
  fi
  [[ -n "${formatted}" ]] || formatted="${unix_ts}"
  printf '%s\n' "${formatted}"
}

classify_log_file() {
  local file_path="$1"
  local file_name=""

  file_name="$(basename "${file_path}")"

  case "${file_path}" in
    */reports/*|/tmp/etap23-reports/*)
      printf 'rapor\n'
      ;;
    *)
      case "${file_name}" in
        rapor-*.log)
          printf 'rapor\n'
          ;;
        *)
          printf 'gunluk\n'
          ;;
      esac
      ;;
  esac
}

collect_log_records() {
  (
    shopt -s nullglob
    local file_path="" mtime="" size="" file_type=""
    local seen_paths=""

    seen_paths=$'\n'

    for file_path in \
      "${ETAP23_RUNTIME_DIR}"/rapor-*.log \
      "${ETAP23_RUNTIME_DIR}"/reports/*.log \
      "${ETAP23_RUNTIME_DIR}"/*.log \
      /tmp/etap23-reports/rapor-*.log \
      /tmp/etap23-reports/*.log \
      /tmp/eta-kayit-*.log \
      /tmp/touch-calibration*.log \
      /tmp/etap23-launcher-report*.log; do
      [[ -f "${file_path}" ]] || continue
      case "${seen_paths}" in
        *$'\n'"${file_path}"$'\n'*)
          continue
          ;;
      esac
      seen_paths+="${file_path}"$'\n'
      mtime="$(file_mtime "${file_path}" 2>/dev/null || printf '0')"
      size="$(file_size_bytes "${file_path}" 2>/dev/null || printf '0')"
      file_type="$(classify_log_file "${file_path}")"
      printf '%s|%s|%s|%s\n' "${mtime}" "${file_type}" "${size}" "${file_path}"
    done

    if [[ -n "${HOME:-}" && -f "${HOME}/.local/state/etap-wine-bootstrap.log" ]]; then
      file_path="${HOME}/.local/state/etap-wine-bootstrap.log"
      case "${seen_paths}" in
        *$'\n'"${file_path}"$'\n'*)
          ;;
        *)
          mtime="$(file_mtime "${file_path}" 2>/dev/null || printf '0')"
          size="$(file_size_bytes "${file_path}" 2>/dev/null || printf '0')"
          printf '%s|%s|%s|%s\n' "${mtime}" "gunluk" "${size}" "${file_path}"
          ;;
      esac
    fi
  ) | sort -t '|' -k1,1nr -k4,4
}

records_exist() {
  collect_log_records | grep -q '.'
}

record_matches_kind() {
  local kind="$1"
  local file_type="$2"

  case "${kind}" in
    any)
      return 0
      ;;
    report)
      [[ "${file_type}" == "rapor" ]]
      ;;
    log)
      [[ "${file_type}" != "rapor" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

latest_file_for_kind() {
  local kind="$1"
  local mtime="" file_type="" size="" file_path=""

  while IFS='|' read -r mtime file_type size file_path; do
    [[ -n "${file_path}" ]] || continue
    if record_matches_kind "${kind}" "${file_type}"; then
      printf '%s\n' "${file_path}"
      return 0
    fi
  done < <(collect_log_records)

  return 1
}

render_inventory_text() {
  local index=0 mtime="" file_type="" size="" file_path=""

  if ! records_exist; then
    printf 'Kaydedilmis rapor veya gunluk dosyasi bulunamadi.\n'
    return 0
  fi

  printf 'Bulunan rapor ve gunluk dosyalari:\n\n'
  while IFS='|' read -r mtime file_type size file_path; do
    [[ -n "${file_path}" ]] || continue
    index=$((index + 1))
    printf '%d. [%s] %s | %s bayt\n' "${index}" "${file_type}" "$(format_timestamp "${mtime}")" "${size}"
    printf '   %s\n\n' "${file_path}"
  done < <(collect_log_records)
}

show_inventory_gui() {
  local temp_view

  temp_view="$(mktemp)"
  render_inventory_text >"${temp_view}"
  zenity --text-info \
    --title="ETAP Log ve Rapor Ozeti" \
    --width=960 \
    --height=680 \
    --filename="${temp_view}" || true
  rm -f "${temp_view}"
}

show_inventory_cli() {
  render_inventory_text
}

render_log_file_view() {
  local file_path="$1"

  [[ -f "${file_path}" ]] || fail "Dosya bulunamadi: ${file_path}"

  printf 'Dosya: %s\n' "${file_path}"
  printf 'Tur: %s\n' "$(classify_log_file "${file_path}")"
  printf 'Son degisiklik: %s\n' "$(format_timestamp "$(file_mtime "${file_path}")")"
  printf 'Boyut: %s bayt\n' "$(file_size_bytes "${file_path}")"
  printf '\n'
  cat "${file_path}"
}

show_log_file_gui() {
  local file_path="$1"
  local temp_view

  [[ -f "${file_path}" ]] || fail "Dosya bulunamadi: ${file_path}"

  temp_view="$(mktemp)"
  render_log_file_view "${file_path}" >"${temp_view}"
  zenity --text-info \
    --title="ETAP Log ve Rapor Araci" \
    --width=980 \
    --height=720 \
    --filename="${temp_view}" || true
  rm -f "${temp_view}"
}

show_log_file_cli() {
  local file_path="$1"

  render_log_file_view "${file_path}"
}

pick_log_file_gui() {
  local rows=()
  local mtime="" file_type="" size="" file_path="" selected=""

  while IFS='|' read -r mtime file_type size file_path; do
    [[ -n "${file_path}" ]] || continue
    rows+=(FALSE "${file_path}" "${file_type}" "$(format_timestamp "${mtime}")" "${size}")
  done < <(collect_log_records)

  if ((${#rows[@]} == 0)); then
    zenity --warning --title="Dosya Bulunamadi" --text="Kaydedilmis rapor veya gunluk dosyasi bulunamadi." || true
    return 1
  fi

  selected="$(zenity --list \
    --radiolist \
    --title="Log veya Rapor Sec" \
    --text="Acmak istediginiz dosyayi secin" \
    --width=980 \
    --height=420 \
    --column="Sec" \
    --column="Dosya" \
    --column="Tur" \
    --column="Tarih" \
    --column="Boyut (bayt)" \
    "${rows[@]}")" || return 1

  [[ -n "${selected}" ]] || return 1
  printf '%s\n' "${selected}"
}

pick_log_file_cli() {
  local entries=()
  local mtime="" file_type="" size="" file_path="" choice="" index

  while IFS='|' read -r mtime file_type size file_path; do
    [[ -n "${file_path}" ]] || continue
    entries+=("${mtime}|${file_type}|${size}|${file_path}")
  done < <(collect_log_records)

  if ((${#entries[@]} == 0)); then
    print_line 'Kaydedilmis rapor veya gunluk dosyasi bulunamadi.\n'
    return 1
  fi

  print_line 'Dosyalar:\n'
  for index in "${!entries[@]}"; do
    IFS='|' read -r mtime file_type size file_path <<<"${entries[index]}"
    print_line "  $((index + 1))) [${file_type}] $(format_timestamp "${mtime}") | ${size} bayt\n"
    print_line "      ${file_path}\n"
  done

  while true; do
    print_line 'Seciminiz: '
    choice="$(read_line_from_user || true)"
    if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#entries[@]} )); then
      printf '%s\n' "${entries[choice-1]##*|}"
      return 0
    fi
    print_line 'Gecersiz secim.\n\n'
  done
}

collect_gui_action() {
  local selection=""

  selection="$(zenity --list \
    --radiolist \
    --title="ETAP Log ve Rapor Araci" \
    --text="Yapmak istediginiz islemi secin" \
    --width=760 \
    --height=320 \
    --column="Sec" \
    --column="Kod" \
    --column="Aciklama" \
    FALSE latest_report "En yeni rapor dosyasini ac" \
    FALSE latest_log "En yeni gunluk dosyasini ac" \
    FALSE pick_file "Listeden dosya secerek ac" \
    FALSE list_inventory "Tum rapor ve gunluk ozetini goster")" || return 1

  [[ -n "${selection}" ]] || return 1
  printf '%s\n' "${selection}"
}

collect_cli_action() {
  local choice=""

  while true; do
    print_line 'ETAP Log ve Rapor Araci\n'
    print_line '  1) En yeni rapor dosyasini ac\n'
    print_line '  2) En yeni gunluk dosyasini ac\n'
    print_line '  3) Listeden dosya secerek ac\n'
    print_line '  4) Tum rapor ve gunluk ozetini goster\n'
    print_line '  q) Cikis\n'
    print_line 'Seciminiz: '
    choice="$(read_line_from_user || true)"

    case "${choice}" in
      1)
        printf 'latest_report\n'
        return 0
        ;;
      2)
        printf 'latest_log\n'
        return 0
        ;;
      3)
        printf 'pick_file\n'
        return 0
        ;;
      4)
        printf 'list_inventory\n'
        return 0
        ;;
      q|Q)
        return 1
        ;;
      *)
        print_line 'Gecersiz secim.\n\n'
        ;;
    esac
  done
}

run_selected_action() {
  local selected_action="$1"
  local file_path=""

  case "${selected_action}" in
    latest_report)
      file_path="$(latest_file_for_kind report || true)"
      [[ -n "${file_path}" ]] || fail "Kaydedilmis rapor dosyasi bulunamadi."
      if ((GUI_MODE)) && can_use_zenity; then
        show_log_file_gui "${file_path}"
      else
        show_log_file_cli "${file_path}"
      fi
      ;;
    latest_log)
      file_path="$(latest_file_for_kind log || true)"
      [[ -n "${file_path}" ]] || fail "Kaydedilmis gunluk dosyasi bulunamadi."
      if ((GUI_MODE)) && can_use_zenity; then
        show_log_file_gui "${file_path}"
      else
        show_log_file_cli "${file_path}"
      fi
      ;;
    pick_file)
      if ((GUI_MODE)) && can_use_zenity; then
        file_path="$(pick_log_file_gui || true)"
      else
        file_path="$(pick_log_file_cli || true)"
      fi
      [[ -n "${file_path}" ]] || return 1
      if ((GUI_MODE)) && can_use_zenity; then
        show_log_file_gui "${file_path}"
      else
        show_log_file_cli "${file_path}"
      fi
      ;;
    list_inventory)
      if ((GUI_MODE)) && can_use_zenity; then
        show_inventory_gui
      else
        show_inventory_cli
      fi
      ;;
    show_file)
      [[ -n "${TARGET_FILE}" ]] || fail "Acilacak dosya belirtilmedi."
      if ((GUI_MODE)) && can_use_zenity; then
        show_log_file_gui "${TARGET_FILE}"
      else
        show_log_file_cli "${TARGET_FILE}"
      fi
      ;;
    *)
      fail "Desteklenmeyen islem: ${selected_action}"
      ;;
  esac
}

parse_args() {
  while (($#)); do
    case "$1" in
      --gui)
        GUI_MODE=1
        ;;
      --list)
        ACTION="list_inventory"
        ;;
      --pick)
        ACTION="pick_file"
        ;;
      --latest-report)
        ACTION="latest_report"
        ;;
      --latest-log)
        ACTION="latest_log"
        ;;
      --show)
        ACTION="show_file"
        shift
        [[ $# -gt 0 ]] || fail "--show icin dosya yolu eksik."
        TARGET_FILE="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Bilinmeyen parametre: $1"
        ;;
    esac
    shift
  done
}

run_interactive_gui_loop() {
  local selection=""

  while true; do
    selection="$(collect_gui_action || true)"
    [[ -n "${selection}" ]] || return 0
    run_selected_action "${selection}" || true
  done
}

run_interactive_cli_loop() {
  local selection=""

  while true; do
    selection="$(collect_cli_action || true)"
    [[ -n "${selection}" ]] || return 0
    run_selected_action "${selection}" || true
    print_line '\n'
  done
}

main() {
  parse_args "$@"

  if [[ -z "${ACTION}" ]]; then
    if ((GUI_MODE)) || can_use_zenity; then
      GUI_MODE=1
      run_interactive_gui_loop
      exit 0
    fi

    run_interactive_cli_loop
    exit 0
  fi

  if ((GUI_MODE)) && can_use_zenity; then
    run_selected_action "${ACTION}"
    exit 0
  fi

  run_selected_action "${ACTION}"
}

main "$@"
