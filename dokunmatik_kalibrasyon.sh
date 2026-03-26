#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/setup_etap23.sh"
LAUNCHER_SCRIPT="${SCRIPT_DIR}/setup_etap23_launcher.sh"
LAUNCHER_MODE_NAME="touch-calibration"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
export ETAP23_RUNTIME_DIR

GUI_MODE=0
ACTION_FLAG=""
FORWARDED_ARGS=()

usage() {
  cat <<'EOF'
Kullanim:
  ./dokunmatik_kalibrasyon.sh --gui
  sudo ./dokunmatik_kalibrasyon.sh --start
  sudo ./dokunmatik_kalibrasyon.sh --status
  sudo ./dokunmatik_kalibrasyon.sh --reset

Bu sarmalayici, dokunmatik kalibrasyon islemlerini setup_etap23.sh icindeki merkezi kalibrasyon kiplerine yonlendirir.

Secenekler:
  --gui               Grafik arayuzlu dokunmatik kalibrasyon aracini ac
  --start             Dokunmatik kalibrasyon ekranini baslat
  --status            Kayitli kalibrasyon durumunu goster
  --reset             Kayitli kalibrasyonu sifirla
  --skip-apt-update   apt-get update adimini atla
  --pause-on-error    Hata durumunda pencereyi kapatmadan once bekle
  -h, --help          Bu yardimi goster
EOF
}

fail() {
  printf 'HATA: %s\n' "$*" >&2
  exit 1
}

exec_launcher() {
  [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
  LAUNCHER_MODE="${LAUNCHER_MODE_NAME}" exec "${LAUNCHER_SCRIPT}" "$@"
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
      --start)
        set_action --touch-calibration-start
        ;;
      --status)
        set_action --touch-calibration-status
        ;;
      --reset)
        set_action --touch-calibration-reset
        ;;
      --skip-apt-update|--pause-on-error)
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
    exec_launcher --touch-calibration-gui
  fi

  [[ -n "${ACTION_FLAG}" ]] || fail "Bir islem secin veya --gui kullanin."

  FORWARDED_ARGS+=("${ACTION_FLAG}")

  if [[ "${EUID}" -ne 0 ]]; then
    exec_launcher "${FORWARDED_ARGS[@]}"
  fi

  exec "${MAIN_SCRIPT}" "${FORWARDED_ARGS[@]}"
}

main "$@"
