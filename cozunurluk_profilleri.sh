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
  ./cozunurluk_profilleri.sh --gui
  sudo ./cozunurluk_profilleri.sh --status
  sudo ./cozunurluk_profilleri.sh --4k
  sudo ./cozunurluk_profilleri.sh --fhd
  sudo ./cozunurluk_profilleri.sh --native

Bu sarmalayici, ekran cozumunurluk profillerini setup_etap23.sh icindeki merkezi kiplere yonlendirir.

Secenekler:
  --gui                Grafik arayuzlu cozumunurluk aracini ac
  --status             Bagli ekranlari ve modlari raporla
  --4k                 4K profilini uygula
  --fhd                FHD profilini uygula
  --native             Yerel (auto) profili uygula
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
      --status)
        set_action --resolution-status
        ;;
      --4k)
        set_action --resolution-profile
        ACTION_VALUE="4k"
        ;;
      --fhd)
        set_action --resolution-profile
        ACTION_VALUE="fhd"
        ;;
      --native)
        set_action --resolution-profile
        ACTION_VALUE="native"
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
      exec "${LAUNCHER_SCRIPT}" --resolution-gui --report-file "${REPORT_FILE}"
    fi
    exec "${LAUNCHER_SCRIPT}" --resolution-gui
  fi

  [[ -n "${ACTION_FLAG}" ]] || fail "Bir islem secin veya --gui kullanin."

  FORWARDED_ARGS+=("${ACTION_FLAG}")

  if [[ "${ACTION_FLAG}" == "--resolution-profile" ]]; then
    [[ -n "${ACTION_VALUE}" ]] || fail "Uygulanacak cozumunurluk profili belirlenemedi."
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
