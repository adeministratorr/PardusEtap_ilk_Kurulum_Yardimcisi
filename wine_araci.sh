#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/setup_etap23.sh"
LAUNCHER_SCRIPT="${SCRIPT_DIR}/setup_etap23_launcher.sh"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
export ETAP23_RUNTIME_DIR

GUI_MODE=0
ACTION_FLAG=""
VULKAN_FLAG=""
FORWARDED_ARGS=()

usage() {
  cat <<'EOF'
Kullanim:
  ./wine_araci.sh --gui
  sudo ./wine_araci.sh --install
  sudo ./wine_araci.sh --install-vulkan
  sudo ./wine_araci.sh --check
  sudo ./wine_araci.sh --version
  sudo ./wine_araci.sh --winecfg
  sudo ./wine_araci.sh --rebuild-prefix --wine-user etapadmin
  sudo ./wine_araci.sh --remove
  sudo ./wine_araci.sh --remove-purge-prefixes

Bu sarmalayici, Wine islemlerini setup_etap23.sh icindeki merkezi Wine kiplerine yonlendirir.

Secenekler:
  --gui                     Grafik arayuzlu Wine aracini ac
  --install                 Wine ve winetricks kur veya guncelle
  --install-vulkan          Wine kur/guncelle ve dxvk/vkd3d de ekle
  --check                   Wine durumunu kontrol et
  --version                 Wine ve winetricks surumlerini goster
  --winecfg                 winecfg ac
  --rebuild-prefix          Wine prefix klasorunu yeniden olustur
  --remove                  Wine paketlerini ve ETAP baslaticilarini kaldir
  --remove-purge-prefixes   Wine paketlerini kaldir ve prefix klasorlerini de sil
  --wine-user KULLANICI     Hedef kullanici
  --wine-prefix-name AD     Wine prefix klasor adi
  --wine-windows-version S  Windows surumu
  --enable-vulkan           dxvk ve vkd3d ekle
  --disable-vulkan          dxvk ve vkd3d ekleme
  --skip-apt-update         apt-get update adimini atla
  --pause-on-error          Hata durumunda pencereyi kapatmadan once bekle
  -h, --help                Bu yardimi goster
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
      --install)
        set_action --wine-install
        ;;
      --install-vulkan)
        set_action --wine-install
        VULKAN_FLAG="--enable-wine-vulkan"
        ;;
      --check)
        set_action --wine-check
        ;;
      --version)
        set_action --wine-version
        ;;
      --winecfg)
        set_action --winecfg
        ;;
      --rebuild-prefix)
        set_action --wine-rebuild-prefix
        ;;
      --remove)
        set_action --wine-remove
        ;;
      --remove-purge-prefixes)
        set_action --wine-remove-purge-prefixes
        ;;
      --wine-user|--wine-prefix-name|--wine-windows-version)
        option_name="$1"
        FORWARDED_ARGS+=("${option_name}")
        shift
        [[ $# -gt 0 ]] || fail "${option_name} icin deger eksik."
        FORWARDED_ARGS+=("$1")
        ;;
      --enable-vulkan)
        VULKAN_FLAG="--enable-wine-vulkan"
        ;;
      --disable-vulkan)
        VULKAN_FLAG="--disable-wine-vulkan"
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
    [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
    exec "${LAUNCHER_SCRIPT}" --wine-gui
  fi

  [[ -n "${ACTION_FLAG}" ]] || fail "Bir islem secin veya --gui kullanin."

  if [[ -n "${VULKAN_FLAG}" && "${ACTION_FLAG}" != "--wine-install" ]]; then
    fail "--enable-vulkan/--disable-vulkan yalnizca kurulum islemleri ile kullanilabilir."
  fi

  FORWARDED_ARGS+=("${ACTION_FLAG}")

  if [[ "${ACTION_FLAG}" == "--wine-install" ]]; then
    if [[ -z "${VULKAN_FLAG}" ]]; then
      FORWARDED_ARGS+=(--disable-wine-vulkan)
    else
      FORWARDED_ARGS+=("${VULKAN_FLAG}")
    fi
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    [[ -x "${LAUNCHER_SCRIPT}" ]] || fail "Baslatici bulunamadi veya calistirilabilir degil: ${LAUNCHER_SCRIPT}"
    exec "${LAUNCHER_SCRIPT}" "${FORWARDED_ARGS[@]}"
  fi

  exec "${MAIN_SCRIPT}" "${FORWARDED_ARGS[@]}"
}

main "$@"
