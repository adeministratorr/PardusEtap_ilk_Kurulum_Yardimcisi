#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/setup_etap23.sh"
LAUNCHER_SCRIPT="${SCRIPT_DIR}/setup_etap23_launcher.sh"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
export ETAP23_RUNTIME_DIR

REINSTALL_AHENK=0
FULL_UPGRADE=0
SKIP_APT_UPDATE=0
GUI_MODE=0
PREFLIGHT=0
REPORT_FILE=""

usage() {
  cat <<'EOF'
Kullanim:
  sudo ./ahenk_kaldir.sh
  sudo ./ahenk_kaldir.sh --preflight
  sudo ./ahenk_kaldir.sh --reinstall-ahenk
  sudo ./ahenk_kaldir.sh --full-upgrade
  sudo ./ahenk_kaldir.sh --skip-apt-update
  ./ahenk_kaldir.sh --gui

Bu sarmalayici, islemi setup_etap23.sh icindeki merkezi bakim moduna yonlendirir.

Secenekler:
  --preflight          ETA Kayit oncesi on kontrol raporu olustur
  --reinstall-ahenk   Temizlikten sonra ahenk paketini yeniden kur
  --full-upgrade      Temizlikten sonra ahenk paketini yeniden kur ve tum paketleri guncelle
  --skip-apt-update   apt-get update adimini atla
  --report-file DOSYA Ciktiyi belirtilen rapor dosyasina da yaz
  --gui               Grafik arayuz ile ETA Kayit duzelt/sifirla akisini ac
  -h, --help          Bu yardimi goster
EOF
}

fail() {
  printf 'HATA: %s\n' "$*" >&2
  exit 1
}

parse_args() {
  while (($#)); do
    case "$1" in
      --preflight)
        PREFLIGHT=1
        ;;
      --reinstall-ahenk)
        REINSTALL_AHENK=1
        ;;
      --full-upgrade)
        FULL_UPGRADE=1
        ;;
      --skip-apt-update)
        SKIP_APT_UPDATE=1
        ;;
      --report-file)
        shift
        [[ $# -gt 0 ]] || fail "--report-file icin dosya yolu eksik."
        REPORT_FILE="$1"
        ;;
      --gui)
        GUI_MODE=1
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
  local forwarded_args=()

  parse_args "$@"
  [[ -x "${MAIN_SCRIPT}" ]] || fail "Ana betik bulunamadi veya calistirilabilir degil: ${MAIN_SCRIPT}"

  if ((GUI_MODE)); then
    [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
    if ((PREFLIGHT)); then
      if [[ -n "${REPORT_FILE}" ]]; then
        exec "${LAUNCHER_SCRIPT}" --eta-kayit-repair-gui --eta-kayit-preflight --report-file "${REPORT_FILE}"
      fi
      exec "${LAUNCHER_SCRIPT}" --eta-kayit-repair-gui --eta-kayit-preflight
    fi
    if [[ -n "${REPORT_FILE}" ]]; then
      exec "${LAUNCHER_SCRIPT}" --eta-kayit-repair-gui --report-file "${REPORT_FILE}"
    fi
    exec "${LAUNCHER_SCRIPT}" --eta-kayit-repair-gui
  fi

  if ((SKIP_APT_UPDATE)); then
    forwarded_args+=(--skip-apt-update)
  fi

  if [[ -n "${REPORT_FILE}" ]]; then
    forwarded_args+=(--report-file "${REPORT_FILE}")
  fi

  if ((PREFLIGHT)); then
    forwarded_args+=(--eta-kayit-preflight)
  elif ((FULL_UPGRADE)); then
    forwarded_args+=(--eta-kayit-repair-full-upgrade)
  elif ((REINSTALL_AHENK)); then
    forwarded_args+=(--eta-kayit-repair-reinstall-ahenk)
  else
    forwarded_args+=(--eta-kayit-repair)
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
    exec "${LAUNCHER_SCRIPT}" "${forwarded_args[@]}"
  fi

  exec "${MAIN_SCRIPT}" "${forwarded_args[@]}"
}

main "$@"
