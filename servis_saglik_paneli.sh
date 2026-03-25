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
  ./servis_saglik_paneli.sh --gui
  sudo ./servis_saglik_paneli.sh --check
  sudo ./servis_saglik_paneli.sh --restart NetworkManager.service

Bu sarmalayici, servis saglik islemlerini setup_etap23.sh icindeki merkezi kiplerine yonlendirir.

Secenekler:
  --gui                Grafik arayuzlu servis saglik panelini ac
  --check              Temel servis ve timer durum raporunu olustur
  --restart BIRIM      Desteklenen servis veya timer'i yeniden baslat
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
      --check)
        set_action --service-health-check
        ;;
      --restart)
        set_action --service-health-restart
        shift
        [[ $# -gt 0 ]] || fail "--restart icin birim adi eksik."
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
      exec "${LAUNCHER_SCRIPT}" --service-health-gui --report-file "${REPORT_FILE}"
    fi
    exec "${LAUNCHER_SCRIPT}" --service-health-gui
  fi

  [[ -n "${ACTION_FLAG}" ]] || fail "Bir islem secin veya --gui kullanin."

  FORWARDED_ARGS+=("${ACTION_FLAG}")

  if [[ "${ACTION_FLAG}" == "--service-health-restart" ]]; then
    [[ -n "${ACTION_VALUE}" ]] || fail "Yeniden baslatilacak birim belirlenemedi."
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
