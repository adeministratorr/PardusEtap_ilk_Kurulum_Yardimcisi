#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/setup_etap23.sh"
LAUNCHER_SCRIPT="${SCRIPT_DIR}/setup_etap23_launcher.sh"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
export ETAP23_RUNTIME_DIR

GUI_MODE=0
ACTION_FLAG=""
ACTION_VALUE=""
REPORT_FILE=""
FORWARDED_ARGS=()

usage() {
  cat <<'EOF'
Kullanim:
  ./usb_onarim_araci.sh --gui
  sudo ./usb_onarim_araci.sh --report
  sudo ./usb_onarim_araci.sh --repair /dev/sdb

Bu sarmalayici, USB depolama raporu ve onarim islemlerini setup_etap23.sh icindeki merkezi kiplere yonlendirir.

Secenekler:
  --gui                Grafik arayuzlu USB onarim aracini ac
  --report             Bagli USB depolama aygitlarini raporla
  --repair AYGIT       Secilen USB depolama aygitini onarmayi dene
  --report-file DOSYA  Ciktiyi belirtilen rapor dosyasina da yaz
  --pause-on-error     Hata durumunda pencereyi kapatmadan once bekle
  -h, --help           Bu yardimi goster
EOF
}

fail() {
  printf 'HATA: %s\n' "$*" >&2
  exit 1
}

set_action() {
  local new_action="$1"

  if [[ -n "${ACTION_FLAG}" && "${ACTION_FLAG}" != "${new_action}" ]]; then
    fail "Yalnizca tek bir ana islem secilebilir."
  fi

  ACTION_FLAG="${new_action}"
}

parse_args() {
  while (($#)); do
    case "$1" in
      --gui)
        GUI_MODE=1
        ;;
      --report)
        set_action --usb-report
        ;;
      --repair)
        set_action --usb-repair
        shift
        [[ $# -gt 0 ]] || fail "--repair icin aygit yolu eksik."
        ACTION_VALUE="$1"
        ;;
      --report-file)
        shift
        [[ $# -gt 0 ]] || fail "--report-file icin dosya yolu eksik."
        REPORT_FILE="$1"
        ;;
      --pause-on-error)
        FORWARDED_ARGS+=("$1")
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

main() {
  parse_args "$@"
  [[ -x "${MAIN_SCRIPT}" ]] || fail "Ana betik bulunamadi veya calistirilabilir degil: ${MAIN_SCRIPT}"

  if ((GUI_MODE)) || { [[ -z "${ACTION_FLAG}" && ( -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ) ]]; }; then
    [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
    if [[ -n "${REPORT_FILE}" ]]; then
      exec "${LAUNCHER_SCRIPT}" --usb-repair-gui --report-file "${REPORT_FILE}"
    fi
    exec "${LAUNCHER_SCRIPT}" --usb-repair-gui
  fi

  [[ -n "${ACTION_FLAG}" ]] || fail "Bir islem secin veya --gui kullanin."

  FORWARDED_ARGS+=("${ACTION_FLAG}")

  if [[ "${ACTION_FLAG}" == "--usb-repair" ]]; then
    [[ -n "${ACTION_VALUE}" ]] || fail "Onarilacak USB aygiti belirlenemedi."
    FORWARDED_ARGS+=("${ACTION_VALUE}")
  fi

  if [[ -n "${REPORT_FILE}" ]]; then
    FORWARDED_ARGS+=(--report-file "${REPORT_FILE}")
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
    exec "${LAUNCHER_SCRIPT}" "${FORWARDED_ARGS[@]}"
  fi

  exec "${MAIN_SCRIPT}" "${FORWARDED_ARGS[@]}"
}

main "$@"
