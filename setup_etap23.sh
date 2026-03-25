#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EAG_DEB="${EAG_DEB:-${SCRIPT_DIR}/e-ag-client_2.9.3_amd64.deb}"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
ETAPADMIN_USER="${ETAPADMIN_USER:-etapadmin}"
BOARD_NAME="${BOARD_NAME:-}"
WINE_PREFIX_NAME="${WINE_PREFIX_NAME:-.wine-etap}"
WINE_WINDOWS_VERSION="${WINE_WINDOWS_VERSION:-win10}"
WINETRICKS_PACKAGES="${WINETRICKS_PACKAGES:-renderer=gl allfonts corefonts liberation d3dx9 riched20 gdiplus msxml6 mingw vb6run vcrun6sp6 vcrun2012 vcrun2013 vcrun2022 mfc42}"
ENABLE_WINE_VULKAN_TRANSLATORS="${ENABLE_WINE_VULKAN_TRANSLATORS:-0}"
WINETRICKS_VULKAN_PACKAGES="${WINETRICKS_VULKAN_PACKAGES:-dxvk vkd3d}"
WINE_TARGET_USER="${WINE_TARGET_USER:-}"
IDLE_SHUTDOWN_MINUTES="${IDLE_SHUTDOWN_MINUTES:-90}"
SCHEDULED_SHUTDOWN_TIME="${SCHEDULED_SHUTDOWN_TIME:-17:20}"
# Kurulumun sonunda atanacak yeni etapadmin parolasi; bos ise degisim adimi atlanir.
ETAPADMIN_PASSWORD="${ETAPADMIN_PASSWORD-}"
# Kurulum sirasinda mevcut etapadmin parolasi; passwd yontemi bu degeri kullanir.
ETAPADMIN_CURRENT_PASSWORD="${ETAPADMIN_CURRENT_PASSWORD:-etap+pardus!}"
ETA_KAYIT_KURUM_KODU="${ETA_KAYIT_KURUM_KODU:-216183}"
ETA_KAYIT_SINIF="${ETA_KAYIT_SINIF:-}"
ETA_KAYIT_PACKAGE="${ETA_KAYIT_PACKAGE:-eta-register}"
ETA_KAYIT_DESKTOP_ID="${ETA_KAYIT_DESKTOP_ID:-tr.org.pardus.eta-register}"
ETA_KAYIT_MAINWINDOW_PATH="${ETA_KAYIT_MAINWINDOW_PATH:-/usr/share/pardus/eta-register/src/MainWindow.py}"
AHENK_PACKAGE="${AHENK_PACKAGE:-ahenk}"
AHENK_DB_PATH="${AHENK_DB_PATH:-/etc/ahenk/ahenk.db}"
AHENK_LEFTOVER_DIRS=(
  /usr/share/ahenk
  /var/lib/ahenk
  /var/log/ahenk
  /etc/ahenk
)
ETA_TOUCHDRV_TARGET_VERSION="${ETA_TOUCHDRV_TARGET_VERSION:-0.4.0}"
ETA_TOUCHDRV_FALLBACK_VERSION="${ETA_TOUCHDRV_FALLBACK_VERSION:-0.3.5}"
ETA_TOUCH_CALIBRATION_IDENTITY_MATRIX="${ETA_TOUCH_CALIBRATION_IDENTITY_MATRIX:-1 0 0 0 1 0 0 0 1}"
ETA_TOUCH_CALIBRATION_FILE="${ETA_TOUCH_CALIBRATION_FILE:-/etc/etap-touch-calibration.conf}"
ETA_TOUCH_CALIBRATION_APPLY_HELPER="${ETA_TOUCH_CALIBRATION_APPLY_HELPER:-/usr/local/bin/etap-touch-apply-calibration}"
ETA_TOUCH_CALIBRATION_GUI_HELPER="${ETA_TOUCH_CALIBRATION_GUI_HELPER:-/usr/local/libexec/etap-touch-calibration.py}"
ETA_TOUCH_CALIBRATION_AUTOSTART="${ETA_TOUCH_CALIBRATION_AUTOSTART:-/etc/xdg/autostart/etap-touch-calibration-apply.desktop}"
ETA_TOUCH_CALIBRATION_XSESSION="${ETA_TOUCH_CALIBRATION_XSESSION:-/etc/X11/Xsession.d/92etap-touch-calibration-apply}"
INTERACTIVE_MODE="${INTERACTIVE_MODE:-auto}"
ACTION_MODE="${ACTION_MODE:-setup}"

ENABLE_HOSTNAME_CHANGE="${ENABLE_HOSTNAME_CHANGE:-1}"
ENABLE_REMOVE_OGRENCI="${ENABLE_REMOVE_OGRENCI:-1}"
ENABLE_REMOVE_OGRETMEN="${ENABLE_REMOVE_OGRETMEN:-1}"
ENABLE_EAG_CLIENT="${ENABLE_EAG_CLIENT:-1}"
ENABLE_ETA_QR_LOGIN="${ENABLE_ETA_QR_LOGIN:-1}"
ENABLE_PACKAGE_UPGRADE="${ENABLE_PACKAGE_UPGRADE:-0}"
ENABLE_ETA_TOUCHDRV="${ENABLE_ETA_TOUCHDRV:-1}"
ENABLE_WINE="${ENABLE_WINE:-1}"
ENABLE_DISABLE_SCREENSAVER="${ENABLE_DISABLE_SCREENSAVER:-1}"
ENABLE_IDLE_SHUTDOWN="${ENABLE_IDLE_SHUTDOWN:-1}"
ENABLE_SCHEDULED_SHUTDOWN="${ENABLE_SCHEDULED_SHUTDOWN:-1}"
ENABLE_ETAPADMIN_PASSWORD="${ENABLE_ETAPADMIN_PASSWORD:-1}"
ENABLE_OPEN_ETA_KAYIT="${ENABLE_OPEN_ETA_KAYIT:-1}"

SKIP_APT_UPDATE=0
APT_UPDATED=0
CURRENT_STEP=""
CHECK_WARNINGS=0
PAUSE_ON_ERROR="${PAUSE_ON_ERROR:-0}"
ETAP23_USER_SUMMARY_FILE="${ETAP23_USER_SUMMARY_FILE:-}"
ETA_TOUCHDRV_STATE_INSTALLED_VERSION=""
ETA_TOUCHDRV_STATE_CANDIDATE_VERSION=""
ETA_TOUCHDRV_STATE_SERVICE_STATE=""
ETA_TOUCHDRV_STATE_STATUS_OUTPUT=""
ETA_TOUCHDRV_STATE_ACTIVE_LINE=""
LEGACY_ETAP_DENEYSEL_REPO_DISABLED=0
LEGACY_ETAP_DENEYSEL_REPO_FILES=()

usage() {
  cat <<EOF
Kullanim:
  sudo ./setup_etap23.sh
  sudo ./setup_etap23.sh --non-interactive --board-name etap-tahta-01

Betik etkilesimli kipte her adimi tek tek sorar.
Enter'a basarsaniz varsayilan secim korunur.

Genel secenekler:
  --interactive                     Etkilesimli kurulum sihirbazini zorla
  --non-interactive                 Soru sormadan mevcut degiskenlerle ilerle
  --pause-on-error                  Hata durumunda pencereyi kapatmadan once tusa basilmadini bekle
  --skip-apt-update                 apt-get update adimini atla
  --touchdrv-upgrade                Yalnizca yeni dokunmatik surucusunu kur/guncelle
  --touchdrv-only-upgrade           Tum sistemi degil yalnizca mevcut dokunmatik surucusunu guncelle
  --touchdrv-check                  Yalnizca dokunmatik surucusunu kontrol et
  --touchdrv-rollback               Yalnizca dokunmatik surucusunu eski surume geri al
  --touch-calibration-start         Dokunmatik kalibrasyon ekranini ac
  --touch-calibration-status        Kayitli dokunmatik kalibrasyon durumunu goster
  --touch-calibration-reset         Kayitli dokunmatik kalibrasyonunu sifirla
  --wine-install                    Yalnizca Wine ve winetricks kur/guncelle
  --wine-check                      Wine komutlari, baslaticilar ve prefix durumunu kontrol et
  --wine-version                    Kurulu Wine ve winetricks surumlerini goster
  --winecfg                         Aktif grafik oturumundaki kullanici icin winecfg ac
  --wine-remove                     Wine paketlerini ve ETAP baslaticilarini kaldir
  --wine-remove-purge-prefixes      Wine paketlerini kaldir ve Wine prefix klasorlerini de sil
  --wine-rebuild-prefix             Secilen kullanici icin Wine prefix klasorunu yeniden olustur
  --eta-kayit-repair                ETA Kayit icin eta-register kur/guncelle, ahenk kaydini temizle
  --eta-kayit-repair-reinstall-ahenk
                                    ETA Kayit onarimi yap ve sonunda ahenk paketini yeniden kur
  --eta-kayit-repair-full-upgrade   ETA Kayit onarimi yap, ahenk paketini yeniden kur ve son care olarak tum paketleri guncelle
  -h, --help                        Bu yardimi goster

Islem secenekleri:
  --board-name AD                   Tahta adi / hostname
  --change-hostname                 Tahta adini degistir
  --skip-hostname                   Tahta adini degistirme
  --remove-ogrenci                  ogrenci kullanicisini sil
  --keep-ogrenci                    ogrenci kullanicisini silme
  --remove-ogretmen                 ogretmen kullanicisini sil
  --keep-ogretmen                   ogretmen kullanicisini silme
  --install-eag-client              e-ag-client paketini kur
  --skip-eag-client                 e-ag-client paketini kurma
  --install-eta-qr-login            eta-qr-login paketini kur
  --skip-eta-qr-login               eta-qr-login paketini kurma
  --upgrade-packages                Kurulu sistem paketlerini guncelle
  --skip-upgrade-packages           Kurulu sistem paketlerini guncelleme
  --install-eta-touchdrv            eta-touchdrv paketini kur/guncelle
  --skip-eta-touchdrv               eta-touchdrv adimini atla
  --install-wine                    Wine ve winetricks kurulumunu yap
  --skip-wine                       Wine kurulumunu atla
  --disable-screensaver             Ekran koruyucu, blank ve DPMS'i kapat
  --keep-screensaver                Ekran koruyucu ayarlarini degistirme
  --change-etapadmin-password       etapadmin parolasini degistir
  --skip-etapadmin-password         etapadmin parolasini degistirme
  --open-eta-kayit                  Kurulum sonunda ETA Kayit'i ac
  --skip-eta-kayit                  ETA Kayit acilisini atla

ETA Kayit secenekleri:
  --eta-kayit-kurum-kodu KOD        ETA Kayit okul/kurum kodu
  --eta-kayit-sinif SINIF           ETA Kayit sinif bilgisi

Wine secenekleri:
  --wine-prefix-name AD             Kullanici ev dizinindeki Wine klasor adi
  --wine-user KULLANICI             Wine bakim modlarinda hedef kullanici
  --wine-windows-version SURUM      winetricks Windows surumu
  --winetricks-packages LISTE       Boslukla ayrilmis varsayilan winetricks listesi
  --enable-wine-vulkan              dxvk ve vkd3d kur
  --disable-wine-vulkan             dxvk ve vkd3d kurma
  --wine-vulkan-packages LISTE      Vulkan tabanli winetricks listesi

Guc yonetimi secenekleri:
  --enable-idle-shutdown            Bosta kalinca otomatik kapat
  --disable-idle-shutdown           Bosta kalinca kapatma
  --idle-shutdown-minutes DAKIKA    Bosta kapanma suresi
  --enable-scheduled-shutdown       Her gun belirli saatte kapat
  --disable-scheduled-shutdown      Saatli kapatma kapali olsun
  --scheduled-shutdown SAAT:DAKIKA  Gunluk kapanma saati
  --etapadmin-current-password SIFRE
                                  Mevcut etapadmin parolasi

Ortam degiskenleri:
  INTERACTIVE_MODE
  PAUSE_ON_ERROR
  BOARD_NAME
  EAG_DEB
  ETAPADMIN_USER
  ETAPADMIN_PASSWORD
  ETAPADMIN_CURRENT_PASSWORD
  ETA_KAYIT_KURUM_KODU
  ETA_KAYIT_SINIF
  ETA_KAYIT_PACKAGE
  ETA_KAYIT_DESKTOP_ID
  AHENK_PACKAGE
  AHENK_DB_PATH
  AHENK_LEFTOVER_DIRS
  ETA_TOUCHDRV_TARGET_VERSION
  ETA_TOUCHDRV_FALLBACK_VERSION
  ACTION_MODE
  WINE_PREFIX_NAME
  WINE_TARGET_USER
  WINE_WINDOWS_VERSION
  WINETRICKS_PACKAGES
  ENABLE_WINE_VULKAN_TRANSLATORS
  WINETRICKS_VULKAN_PACKAGES
  IDLE_SHUTDOWN_MINUTES
  SCHEDULED_SHUTDOWN_TIME
  ENABLE_HOSTNAME_CHANGE
  ENABLE_REMOVE_OGRENCI
  ENABLE_REMOVE_OGRETMEN
  ENABLE_EAG_CLIENT
  ENABLE_ETA_QR_LOGIN
  ENABLE_PACKAGE_UPGRADE
  ENABLE_ETA_TOUCHDRV
  ENABLE_WINE
  ENABLE_DISABLE_SCREENSAVER
  ENABLE_IDLE_SHUTDOWN
  ENABLE_SCHEDULED_SHUTDOWN
  ENABLE_ETAPADMIN_PASSWORD
  ENABLE_OPEN_ETA_KAYIT

Varsayilan winetricks listesi:
  ${WINETRICKS_PACKAGES}

Istege bagli Vulkan listesi:
  ${WINETRICKS_VULKAN_PACKAGES}
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >&2
}

user_warn() {
  log "KULLANICI_UYARI: $*"
}

clear_user_summary() {
  [[ -n "${ETAP23_USER_SUMMARY_FILE}" ]] || return 0
  : >"${ETAP23_USER_SUMMARY_FILE}" 2>/dev/null || true
}

append_user_summary_line() {
  [[ -n "${ETAP23_USER_SUMMARY_FILE}" ]] || return 0
  printf '%s\n' "$*" >>"${ETAP23_USER_SUMMARY_FILE}" 2>/dev/null || true
}

create_script_log_file() {
  local prefix="$1"
  local target_dir="${ETAP23_RUNTIME_DIR}"

  if [[ ! -d "${target_dir}" ]]; then
    mkdir -p "${target_dir}" 2>/dev/null || true
  fi

  if [[ -w "${target_dir}" ]]; then
    mktemp "${target_dir}/${prefix}.XXXXXX.log"
    return 0
  fi

  mktemp "/tmp/${prefix}.XXXXXX.log"
}

fail() {
  printf 'HATA: %s\n' "$*" >&2
  if [[ -n "${CURRENT_STEP}" ]]; then
    printf 'Basarisiz olan adim: %s\n' "${CURRENT_STEP}" >&2
  fi
  wait_on_error_if_requested
  exit 1
}

wait_on_error_if_requested() {
  if [[ "${PAUSE_ON_ERROR}" != "1" ]]; then
    return 0
  fi

  if [[ -r /dev/tty && -w /dev/tty ]]; then
    printf '\nHata nedeniyle cikis durduruldu. Pencereyi kapatmadan once Enter tusuna basin...' >/dev/tty
    read -r _ </dev/tty || sleep 15
  else
    printf '\nHata nedeniyle cikis durduruldu. 15 saniye beklenecek...\n' >&2
    sleep 15
  fi
}

handle_unexpected_error() {
  local status="$1"
  local line_no="$2"
  local command_text="$3"

  trap - ERR
  printf 'HATA: Beklenmeyen bir hata olustu.\n' >&2
  if [[ -n "${CURRENT_STEP}" ]]; then
    printf 'Basarisiz olan adim: %s\n' "${CURRENT_STEP}" >&2
  fi
  printf 'Komut: %s\n' "${command_text}" >&2
  printf 'Satir: %s\n' "${line_no}" >&2
  printf 'Ayrintilar yukaridaki mesajlarda yer aliyor.\n' >&2
  wait_on_error_if_requested
  exit "${status}"
}

cleanup_on_exit() {
  local exit_status=$?

  trap - EXIT
  restore_legacy_etap_deneysel_repo_entries_if_needed || true
  exit "${exit_status}"
}

run_step() {
  local description="$1"

  shift
  CURRENT_STEP="${description}"
  log "Baslatiliyor: ${CURRENT_STEP}"
  "$@"
  log "Tamamlandi: ${CURRENT_STEP}"
  CURRENT_STEP=""
}

postcheck_ok() {
  log "Kontrol OK: $*"
}

postcheck_info() {
  log "Kontrol BILGI: $*"
}

postcheck_warn() {
  CHECK_WARNINGS=$((CHECK_WARNINGS + 1))
  log "Kontrol UYARI: $*"
}

trap 'handle_unexpected_error $? ${LINENO} "$BASH_COMMAND"' ERR
trap cleanup_on_exit EXIT

require_root() {
  [[ "${EUID}" -eq 0 ]] || fail "Bu betik root yetkisi ile calistirilmalidir."
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Gerekli komut bulunamadi: $1"
}

resolve_system_command() {
  local command_name="$1"
  local resolved=""

  PATH='/usr/bin:/bin:/usr/sbin:/sbin' resolved="$(command -v "${command_name}" 2>/dev/null || true)"
  [[ -n "${resolved}" ]] || fail "Sistem komutu bulunamadi: ${command_name}"
  printf '%s\n' "${resolved}"
}

resolve_system_command_if_present() {
  local command_name="$1"
  local resolved=""

  PATH='/usr/bin:/bin:/usr/sbin:/sbin' resolved="$(command -v "${command_name}" 2>/dev/null || true)"
  printf '%s\n' "${resolved}"
}

list_home_users() {
  awk -F: '
    ($6 ~ "^/home/") &&
    ($7 !~ /(nologin|false)$/) {
      print $1 ":" $6
    }
  ' /etc/passwd | sort -u
}

user_exists() {
  getent passwd "$1" >/dev/null 2>&1
}

get_user_home() {
  getent passwd "$1" | cut -d: -f6
}

is_enabled() {
  [[ "$1" == "1" ]]
}

action_mode_is_touchdrv() {
  [[ "${ACTION_MODE}" == touchdrv-* ]]
}

action_mode_is_touch_calibration() {
  [[ "${ACTION_MODE}" == touch-calibration-* ]]
}

action_mode_is_wine_maintenance() {
  [[ "${ACTION_MODE}" == winecfg || "${ACTION_MODE}" == wine-* ]]
}

action_mode_is_eta_kayit_repair() {
  [[ "${ACTION_MODE}" == eta-kayit-repair* ]]
}

is_interactive_session() {
  case "${INTERACTIVE_MODE}" in
    auto)
      [[ -t 0 && -t 1 ]]
      ;;
    1|true|yes)
      return 0
      ;;
    0|false|no)
      return 1
      ;;
    *)
      fail "INTERACTIVE_MODE degeri auto, 1 veya 0 olmalidir."
      ;;
  esac
}

ask_yes_no() {
  local prompt="$1"
  local default_value="$2"
  local reply prompt_suffix

  if [[ "${default_value}" == "1" ]]; then
    prompt_suffix="[E/h]"
  else
    prompt_suffix="[e/H]"
  fi

  while true; do
    read -r -p "${prompt} ${prompt_suffix}: " reply
    reply="$(printf '%s' "${reply}" | tr '[:upper:]' '[:lower:]')"

    case "${reply}" in
      "")
        [[ "${default_value}" == "1" ]]
        return
        ;;
      e|evet|y|yes)
        return 0
        ;;
      h|hayir|n|no)
        return 1
        ;;
      *)
        printf 'Lutfen e veya h girin.\n' >&2
        ;;
    esac
  done
}

ask_value() {
  local prompt="$1"
  local default_value="$2"
  local reply

  read -r -p "${prompt} [${default_value}]: " reply
  printf '%s\n' "${reply:-${default_value}}"
}

prompt_custom_etapadmin_password() {
  local first second

  printf 'Yonetici parolasini degistirme adimi acik.\n'
  if [[ -n "${ETAPADMIN_PASSWORD}" ]]; then
    printf 'Enter tusuna basarsaniz kayitli varsayilan parola kullanilir.\n'
  else
    printf 'Enter tusuna basarsaniz parola degistirme adimi uyariyla atlanir.\n'
  fi

  read -r -s -p "Yeni ${ETAPADMIN_USER} parolasi: " first
  printf '\n'

  if [[ -z "${first}" ]]; then
    if [[ -n "${ETAPADMIN_PASSWORD}" ]]; then
      log "Kayitli varsayilan ${ETAPADMIN_USER} parolasi kullanilacak."
    else
      log "Uyari: ${ETAPADMIN_USER} parolasi bos birakildi; parola degistirme adimi atlanacak."
      ENABLE_ETAPADMIN_PASSWORD=0
    fi
    return
  fi

  read -r -s -p "Parolayi tekrar girin: " second
  printf '\n'

  [[ "${first}" == "${second}" ]] || fail "Girilen parolalar eslesmiyor."
  ETAPADMIN_PASSWORD="${first}"
}

current_hostname() {
  hostnamectl --static 2>/dev/null || hostname
}

normalize_board_name() {
  printf '%s' "$1" |
    sed \
      -e 's/[Çç]/c/g' \
      -e 's/[Ğğ]/g/g' \
      -e 's/[İIıi]/i/g' \
      -e 's/[Öö]/o/g' \
      -e 's/[Şş]/s/g' \
      -e 's/[Üü]/u/g' |
    tr '[:upper:]' '[:lower:]' |
    sed -E \
      -e 's/[^a-z0-9]+/-/g' \
      -e 's/^-+//' \
      -e 's/-+$//' \
      -e 's/-+/-/g'
}

board_name_is_valid() {
  [[ -n "${BOARD_NAME}" ]] || return 1
  [[ ${#BOARD_NAME} -le 63 ]] || return 1
  [[ "${BOARD_NAME}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]
}

parse_args() {
  while (($#)); do
    case "$1" in
      --interactive)
        INTERACTIVE_MODE=1
        ;;
      --non-interactive)
        INTERACTIVE_MODE=0
        ;;
      --pause-on-error)
        PAUSE_ON_ERROR=1
        ;;
      --skip-apt-update)
        SKIP_APT_UPDATE=1
        ;;
      --touchdrv-upgrade)
        ACTION_MODE=touchdrv-upgrade
        ;;
      --touchdrv-only-upgrade)
        ACTION_MODE=touchdrv-only-upgrade
        ;;
      --touchdrv-check)
        ACTION_MODE=touchdrv-check
        ;;
      --touchdrv-rollback)
        ACTION_MODE=touchdrv-rollback
        ;;
      --touch-calibration-start)
        ACTION_MODE=touch-calibration-start
        ;;
      --touch-calibration-status)
        ACTION_MODE=touch-calibration-status
        ;;
      --touch-calibration-reset)
        ACTION_MODE=touch-calibration-reset
        ;;
      --wine-install)
        ACTION_MODE=wine-install
        ;;
      --wine-check)
        ACTION_MODE=wine-check
        ;;
      --wine-version)
        ACTION_MODE=wine-version
        ;;
      --winecfg)
        ACTION_MODE=winecfg
        ;;
      --wine-remove)
        ACTION_MODE=wine-remove
        ;;
      --wine-remove-purge-prefixes)
        ACTION_MODE=wine-remove-purge-prefixes
        ;;
      --wine-rebuild-prefix)
        ACTION_MODE=wine-rebuild-prefix
        ;;
      --eta-kayit-repair)
        ACTION_MODE=eta-kayit-repair
        ;;
      --eta-kayit-repair-reinstall-ahenk)
        ACTION_MODE=eta-kayit-repair-reinstall-ahenk
        ;;
      --eta-kayit-repair-full-upgrade)
        ACTION_MODE=eta-kayit-repair-full-upgrade
        ;;
      --board-name)
        shift
        [[ $# -gt 0 ]] || fail "--board-name icin deger eksik."
        BOARD_NAME="$1"
        ;;
      --change-hostname)
        ENABLE_HOSTNAME_CHANGE=1
        ;;
      --skip-hostname)
        ENABLE_HOSTNAME_CHANGE=0
        ;;
      --remove-ogrenci)
        ENABLE_REMOVE_OGRENCI=1
        ;;
      --keep-ogrenci)
        ENABLE_REMOVE_OGRENCI=0
        ;;
      --remove-ogretmen)
        ENABLE_REMOVE_OGRETMEN=1
        ;;
      --keep-ogretmen)
        ENABLE_REMOVE_OGRETMEN=0
        ;;
      --install-eag-client)
        ENABLE_EAG_CLIENT=1
        ;;
      --skip-eag-client)
        ENABLE_EAG_CLIENT=0
        ;;
      --install-eta-qr-login)
        ENABLE_ETA_QR_LOGIN=1
        ;;
      --skip-eta-qr-login)
        ENABLE_ETA_QR_LOGIN=0
        ;;
      --upgrade-packages)
        ENABLE_PACKAGE_UPGRADE=1
        ;;
      --skip-upgrade-packages)
        ENABLE_PACKAGE_UPGRADE=0
        ;;
      --install-eta-touchdrv)
        ENABLE_ETA_TOUCHDRV=1
        ;;
      --skip-eta-touchdrv)
        ENABLE_ETA_TOUCHDRV=0
        ;;
      --install-wine)
        ENABLE_WINE=1
        ;;
      --skip-wine)
        ENABLE_WINE=0
        ;;
      --disable-screensaver)
        ENABLE_DISABLE_SCREENSAVER=1
        ;;
      --keep-screensaver)
        ENABLE_DISABLE_SCREENSAVER=0
        ;;
      --change-etapadmin-password)
        ENABLE_ETAPADMIN_PASSWORD=1
        ;;
      --skip-etapadmin-password)
        ENABLE_ETAPADMIN_PASSWORD=0
        ;;
      --open-eta-kayit)
        ENABLE_OPEN_ETA_KAYIT=1
        ;;
      --skip-eta-kayit)
        ENABLE_OPEN_ETA_KAYIT=0
        ;;
      --eta-kayit-kurum-kodu|--eta-kayit-okul-kodu)
        shift
        [[ $# -gt 0 ]] || fail "--eta-kayit-kurum-kodu icin deger eksik."
        ETA_KAYIT_KURUM_KODU="$1"
        ;;
      --eta-kayit-sinif)
        shift
        [[ $# -gt 0 ]] || fail "--eta-kayit-sinif icin deger eksik."
        ETA_KAYIT_SINIF="$1"
        ;;
      --wine-prefix|--wine-prefix-name)
        shift
        [[ $# -gt 0 ]] || fail "--wine-prefix-name icin deger eksik."
        WINE_PREFIX_NAME="$1"
        ;;
      --wine-user)
        shift
        [[ $# -gt 0 ]] || fail "--wine-user icin deger eksik."
        WINE_TARGET_USER="$1"
        ;;
      --wine-windows-version)
        shift
        [[ $# -gt 0 ]] || fail "--wine-windows-version icin deger eksik."
        WINE_WINDOWS_VERSION="$1"
        ;;
      --winetricks-packages)
        shift
        [[ $# -gt 0 ]] || fail "--winetricks-packages icin deger eksik."
        WINETRICKS_PACKAGES="$1"
        ;;
      --enable-wine-vulkan)
        ENABLE_WINE_VULKAN_TRANSLATORS=1
        ;;
      --disable-wine-vulkan)
        ENABLE_WINE_VULKAN_TRANSLATORS=0
        ;;
      --wine-vulkan-packages)
        shift
        [[ $# -gt 0 ]] || fail "--wine-vulkan-packages icin deger eksik."
        WINETRICKS_VULKAN_PACKAGES="$1"
        ;;
      --enable-idle-shutdown)
        ENABLE_IDLE_SHUTDOWN=1
        ;;
      --disable-idle-shutdown)
        ENABLE_IDLE_SHUTDOWN=0
        ;;
      --idle-shutdown-minutes)
        shift
        [[ $# -gt 0 ]] || fail "--idle-shutdown-minutes icin deger eksik."
        IDLE_SHUTDOWN_MINUTES="$1"
        ;;
      --enable-scheduled-shutdown)
        ENABLE_SCHEDULED_SHUTDOWN=1
        ;;
      --disable-scheduled-shutdown)
        ENABLE_SCHEDULED_SHUTDOWN=0
        ;;
      --scheduled-shutdown)
        shift
        [[ $# -gt 0 ]] || fail "--scheduled-shutdown icin deger eksik."
        SCHEDULED_SHUTDOWN_TIME="$1"
        ;;
      --etapadmin-password)
        shift
        [[ $# -gt 0 ]] || fail "--etapadmin-password icin deger eksik."
        ETAPADMIN_PASSWORD="$1"
        ;;
      --etapadmin-current-password)
        shift
        [[ $# -gt 0 ]] || fail "--etapadmin-current-password icin deger eksik."
        ETAPADMIN_CURRENT_PASSWORD="$1"
        ;;
      --eag-deb)
        shift
        [[ $# -gt 0 ]] || fail "--eag-deb icin deger eksik."
        EAG_DEB="$1"
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

assert_supported_os() {
  [[ -f /etc/os-release ]] || fail "/etc/os-release bulunamadi."
  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    pardus|debian|ubuntu)
      ;;
    *)
      if [[ "${ID_LIKE:-}" != *debian* ]]; then
        fail "Bu betik yalnizca Pardus/Debian turevlerinde desteklenir."
      fi
      ;;
  esac

  [[ "$(uname -m)" == "x86_64" ]] || fail "Bu betik amd64/x86_64 sistem bekler."
}

validate_bool() {
  [[ "$1" =~ ^[01]$ ]]
}

validate_settings() {
  [[ "${ACTION_MODE}" =~ ^(setup|touchdrv-upgrade|touchdrv-only-upgrade|touchdrv-check|touchdrv-rollback|touch-calibration-start|touch-calibration-status|touch-calibration-reset|wine-install|wine-check|wine-version|winecfg|wine-remove|wine-remove-purge-prefixes|wine-rebuild-prefix|eta-kayit-repair|eta-kayit-repair-reinstall-ahenk|eta-kayit-repair-full-upgrade)$ ]] || \
    fail "ACTION_MODE setup, touchdrv-upgrade, touchdrv-only-upgrade, touchdrv-check, touchdrv-rollback, touch-calibration-start, touch-calibration-status, touch-calibration-reset, wine-install, wine-check, wine-version, winecfg, wine-remove, wine-remove-purge-prefixes, wine-rebuild-prefix, eta-kayit-repair, eta-kayit-repair-reinstall-ahenk veya eta-kayit-repair-full-upgrade olmalidir."
  validate_bool "${ENABLE_HOSTNAME_CHANGE}" || fail "ENABLE_HOSTNAME_CHANGE yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_REMOVE_OGRENCI}" || fail "ENABLE_REMOVE_OGRENCI yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_REMOVE_OGRETMEN}" || fail "ENABLE_REMOVE_OGRETMEN yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_EAG_CLIENT}" || fail "ENABLE_EAG_CLIENT yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_ETA_QR_LOGIN}" || fail "ENABLE_ETA_QR_LOGIN yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_PACKAGE_UPGRADE}" || fail "ENABLE_PACKAGE_UPGRADE yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_ETA_TOUCHDRV}" || fail "ENABLE_ETA_TOUCHDRV yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_WINE}" || fail "ENABLE_WINE yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_DISABLE_SCREENSAVER}" || fail "ENABLE_DISABLE_SCREENSAVER yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_WINE_VULKAN_TRANSLATORS}" || fail "ENABLE_WINE_VULKAN_TRANSLATORS yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_IDLE_SHUTDOWN}" || fail "ENABLE_IDLE_SHUTDOWN yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_SCHEDULED_SHUTDOWN}" || fail "ENABLE_SCHEDULED_SHUTDOWN yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_ETAPADMIN_PASSWORD}" || fail "ENABLE_ETAPADMIN_PASSWORD yalnizca 0 veya 1 olabilir."
  validate_bool "${ENABLE_OPEN_ETA_KAYIT}" || fail "ENABLE_OPEN_ETA_KAYIT yalnizca 0 veya 1 olabilir."
  validate_bool "${PAUSE_ON_ERROR}" || fail "PAUSE_ON_ERROR yalnizca 0 veya 1 olabilir."
  [[ "${INTERACTIVE_MODE}" =~ ^(auto|0|1|true|false|yes|no)$ ]] || fail "INTERACTIVE_MODE degeri gecersiz."
  [[ -z "${WINE_TARGET_USER}" || "${WINE_TARGET_USER}" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || fail "WINE_TARGET_USER gecersiz."

  if is_enabled "${ENABLE_OPEN_ETA_KAYIT}"; then
    [[ "${ETA_KAYIT_KURUM_KODU}" =~ ^[0-9]+$ ]] || fail "ETA Kayit kurum kodu yalnizca rakamlardan olusmalidir."
  fi

  if is_enabled "${ENABLE_WINE}" || action_mode_is_wine_maintenance; then
    [[ "${WINE_PREFIX_NAME}" =~ ^[^/]+$ ]] || fail "Wine klasor adi tek bir dizin adi olmalidir."
  fi

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    [[ "${IDLE_SHUTDOWN_MINUTES}" =~ ^[0-9]+$ ]] || fail "Bosta kapanma suresi tam sayi olmalidir."
    ((IDLE_SHUTDOWN_MINUTES > 0)) || fail "Bosta kapanma suresi sifirdan buyuk olmalidir."
  fi

  if is_enabled "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    [[ "${SCHEDULED_SHUTDOWN_TIME}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] || fail "Gunluk kapanma saati SS:DD biciminde olmalidir."
  fi
}

prepare_board_name() {
  if ! is_enabled "${ENABLE_HOSTNAME_CHANGE}"; then
    BOARD_NAME=""
    return
  fi

  BOARD_NAME="$(normalize_board_name "${BOARD_NAME}")"
  board_name_is_valid || fail "Tahta adi gecersiz. Harf, rakam ve tire kullanin."
}

resolve_eta_kayit_sinif() {
  local fallback_board_name

  if ! is_enabled "${ENABLE_OPEN_ETA_KAYIT}"; then
    return
  fi

  if [[ -n "${ETA_KAYIT_SINIF//[[:space:]]/}" ]]; then
    return
  fi

  if [[ -n "${BOARD_NAME}" ]]; then
    fallback_board_name="${BOARD_NAME}"
  else
    fallback_board_name="$(current_hostname)"
  fi

  fallback_board_name="$(normalize_board_name "${fallback_board_name}")"
  [[ -n "${fallback_board_name}" ]] || fail "ETA Kayit sinif bilgisi bos ve tahta adi da belirlenemedi."

  ETA_KAYIT_SINIF="${fallback_board_name}"
  log "ETA Kayit sinif bilgisi bos birakildigi icin tahta adi kullanilacak: ${ETA_KAYIT_SINIF}"
}

ensure_etapadmin_password_step_has_value() {
  if ! is_enabled "${ENABLE_ETAPADMIN_PASSWORD}"; then
    return
  fi

  if [[ -n "${ETAPADMIN_PASSWORD}" ]]; then
    return
  fi

  log "Uyari: ${ETAPADMIN_USER} parolasi bos; parola degistirme adimi atlanacak."
  ENABLE_ETAPADMIN_PASSWORD=0
}

configure_interactive_choices() {
  local current_name entered touchdrv_block_default

  if ! is_interactive_session; then
    return
  fi

  printf '\nETAP23 ilk kurulum sihirbazi acildi.\n'
  printf 'Enter tusuna basarsaniz varsayilan secim kullanilir.\n\n'

  if ask_yes_no "Tahta adi degistirilsin mi?" "${ENABLE_HOSTNAME_CHANGE}"; then
    ENABLE_HOSTNAME_CHANGE=1
    current_name="${BOARD_NAME:-$(current_hostname)}"
    while true; do
      entered="$(ask_value "Tahta adi" "${current_name}")"
      BOARD_NAME="$(normalize_board_name "${entered}")"
      if board_name_is_valid; then
        printf 'Kullanilacak tahta adi: %s\n' "${BOARD_NAME}"
        break
      fi
      printf 'Gecersiz ad. Harf, rakam ve tire kullanin.\n' >&2
    done
  else
    ENABLE_HOSTNAME_CHANGE=0
  fi

  if ask_yes_no "ogrenci kullanicisi silinsin mi?" "${ENABLE_REMOVE_OGRENCI}"; then
    ENABLE_REMOVE_OGRENCI=1
  else
    ENABLE_REMOVE_OGRENCI=0
  fi

  if ask_yes_no "ogretmen kullanicisi silinsin mi?" "${ENABLE_REMOVE_OGRETMEN}"; then
    ENABLE_REMOVE_OGRETMEN=1
  else
    ENABLE_REMOVE_OGRETMEN=0
  fi

  if ask_yes_no "e-ag-client paketi kurulsun mu?" "${ENABLE_EAG_CLIENT}"; then
    ENABLE_EAG_CLIENT=1
  else
    ENABLE_EAG_CLIENT=0
  fi

  if ask_yes_no "eta-qr-login paketi kurulsun mu?" "${ENABLE_ETA_QR_LOGIN}"; then
    ENABLE_ETA_QR_LOGIN=1
  else
    ENABLE_ETA_QR_LOGIN=0
  fi

  if ask_yes_no "Kurulu sistem paketleri guncellensin mi?" "${ENABLE_PACKAGE_UPGRADE}"; then
    ENABLE_PACKAGE_UPGRADE=1
  else
    ENABLE_PACKAGE_UPGRADE=0
  fi

  touchdrv_block_default=0
  if ! is_enabled "${ENABLE_ETA_TOUCHDRV}"; then
    touchdrv_block_default=1
  fi

  if ask_yes_no "Dokunmatik surucusunu guncellemeyi engelle?" "${touchdrv_block_default}"; then
    ENABLE_ETA_TOUCHDRV=0
  else
    ENABLE_ETA_TOUCHDRV=1
  fi

  if ask_yes_no "Wine kurulumu yapilsin mi?" "${ENABLE_WINE}"; then
    ENABLE_WINE=1
    WINE_WINDOWS_VERSION="$(ask_value "Wine icin Windows surumu" "${WINE_WINDOWS_VERSION}")"
    WINE_PREFIX_NAME="$(ask_value "Kullanici bazli Wine klasor adi" "${WINE_PREFIX_NAME}")"

    if ask_yes_no "Vulkan tabanli dxvk/vkd3d de kurulsun mu? (Eski Intel grafiklerde sorun cikarabilir.)" "${ENABLE_WINE_VULKAN_TRANSLATORS}"; then
      ENABLE_WINE_VULKAN_TRANSLATORS=1
      printf 'Bilgi: Vulkan tabanli ceviriciler eski Intel iGPU sistemlerde calismayabilir.\n'
      printf 'Sorun yasarsaniz betigi tekrar --disable-wine-vulkan ile calistirabilirsiniz.\n'
    else
      ENABLE_WINE_VULKAN_TRANSLATORS=0
    fi
  else
    ENABLE_WINE=0
    ENABLE_WINE_VULKAN_TRANSLATORS=0
  fi

  if ask_yes_no "Ekran koruyucu, ekran karartma ve DPMS kapatilsin mi?" "${ENABLE_DISABLE_SCREENSAVER}"; then
    ENABLE_DISABLE_SCREENSAVER=1
  else
    ENABLE_DISABLE_SCREENSAVER=0
  fi

  if ask_yes_no "Tahta bosta kalinca otomatik kapansin mi?" "${ENABLE_IDLE_SHUTDOWN}"; then
    ENABLE_IDLE_SHUTDOWN=1
    while true; do
      IDLE_SHUTDOWN_MINUTES="$(ask_value "Bosta kapanma suresi (dakika)" "${IDLE_SHUTDOWN_MINUTES}")"
      if [[ "${IDLE_SHUTDOWN_MINUTES}" =~ ^[0-9]+$ ]] && ((IDLE_SHUTDOWN_MINUTES > 0)); then
        break
      fi
      printf 'Lutfen sifirdan buyuk bir dakika degeri girin.\n' >&2
    done
  else
    ENABLE_IDLE_SHUTDOWN=0
  fi

  if ask_yes_no "Tahta her gun belirli saatte kapansin mi?" "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    ENABLE_SCHEDULED_SHUTDOWN=1
    while true; do
      SCHEDULED_SHUTDOWN_TIME="$(ask_value "Gunluk kapanma saati (SS:DD)" "${SCHEDULED_SHUTDOWN_TIME}")"
      if [[ "${SCHEDULED_SHUTDOWN_TIME}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        break
      fi
      printf 'Lutfen saati SS:DD biciminde girin.\n' >&2
    done
  else
    ENABLE_SCHEDULED_SHUTDOWN=0
  fi

  if ask_yes_no "${ETAPADMIN_USER} parolasi degistirilsin mi?" "${ENABLE_ETAPADMIN_PASSWORD}"; then
    ENABLE_ETAPADMIN_PASSWORD=1
    prompt_custom_etapadmin_password
  else
    ENABLE_ETAPADMIN_PASSWORD=0
  fi

  if ask_yes_no "Kurulum sonunda ETA Kayit uygulamasi acilsin mi?" "${ENABLE_OPEN_ETA_KAYIT}"; then
    ENABLE_OPEN_ETA_KAYIT=1
    while true; do
      ETA_KAYIT_KURUM_KODU="$(ask_value "ETA Kayit okul/kurum kodu" "${ETA_KAYIT_KURUM_KODU}")"
      if [[ "${ETA_KAYIT_KURUM_KODU}" =~ ^[0-9]+$ ]]; then
        break
      fi
      printf 'Lutfen yalnizca rakamlardan olusan bir kod girin.\n' >&2
    done
    while true; do
      ETA_KAYIT_SINIF="$(ask_value "ETA Kayit sinif bilgisi (bos birakirsaniz tahta adi kullanilir)" "${ETA_KAYIT_SINIF}")"
      break
    done
    printf 'Bilgi: ETA Kayit icin tahta internete bagli olmali ve kayit sirasinda yonetici yetkili sifre gerekebilir.\n'
  else
    ENABLE_OPEN_ETA_KAYIT=0
  fi

  printf '\nSecimler alindi. Kurulum baslatiliyor.\n\n'
}

apt_update_once() {
  if ((SKIP_APT_UPDATE)); then
    return
  fi

  if ((APT_UPDATED == 0)); then
    log "Paket listesi guncelleniyor."
    run_apt_update_with_legacy_etap_repo_recovery
    APT_UPDATED=1
  fi
}

upgrade_installed_packages() {
  local upgrade_status=0
  local touchdrv_temporarily_held=0

  apt_update_once
  log "Kurulu sistem paketleri guncelleniyor."

  if ! is_enabled "${ENABLE_ETA_TOUCHDRV}" && package_installed eta-touchdrv; then
    if package_is_held eta-touchdrv; then
      log "eta-touchdrv zaten hold durumunda; paket guncellemesi sirasinda atlanacak."
    else
      log "Dokunmatik surucusu guncellemesi engellendigi icin eta-touchdrv gecici olarak hold yapiliyor."
      apt-mark hold eta-touchdrv >/dev/null
      touchdrv_temporarily_held=1
    fi
  fi

  set +e
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  upgrade_status=$?
  set -e

  if ((touchdrv_temporarily_held == 1)); then
    log "Gecici eta-touchdrv hold kaldiriliyor."
    apt-mark unhold eta-touchdrv >/dev/null || true
  fi

  return "${upgrade_status}"
}

disable_legacy_etap_deneysel_repo_entries() {
  local sources_file modified=0 backup_file

  while IFS= read -r -d '' sources_file; do
    if ! grep -Eq '^[[:space:]]*deb(-src)?[[:space:]].*(depo\.etap\.org\.tr.*deneysel|deneysel.*depo\.etap\.org\.tr)' "${sources_file}"; then
      continue
    fi

    backup_file="${sources_file}.bak.etap23"
    if [[ ! -e "${backup_file}" ]]; then
      cp -a "${sources_file}" "${backup_file}"
    fi

    sed -i -E \
      '/^[[:space:]]*deb(-src)?[[:space:]].*(depo\.etap\.org\.tr.*deneysel|deneysel.*depo\.etap\.org\.tr)/ s/^/# disabled by setup_etap23.sh: /' \
      "${sources_file}"

    log "Eski ETAP deneysel deposu devre disi birakildi: ${sources_file}"
    LEGACY_ETAP_DENEYSEL_REPO_FILES+=("${sources_file}")
    modified=1
  done < <(find /etc/apt -maxdepth 2 -type f \( -name 'sources.list' -o -name '*.list' \) -print0 2>/dev/null)

  if ((modified == 1)); then
    LEGACY_ETAP_DENEYSEL_REPO_DISABLED=1
  fi

  ((modified == 1))
}

restore_legacy_etap_deneysel_repo_entries_if_needed() {
  local sources_file backup_file restored=0

  if ((LEGACY_ETAP_DENEYSEL_REPO_DISABLED == 0)); then
    return 0
  fi

  for sources_file in "${LEGACY_ETAP_DENEYSEL_REPO_FILES[@]:-}"; do
    [[ -n "${sources_file}" ]] || continue
    backup_file="${sources_file}.bak.etap23"
    [[ -e "${backup_file}" ]] || continue

    cp -a "${backup_file}" "${sources_file}"
    log "Deneysel depo girdisi yeniden etkinlestirildi: ${sources_file}"
    restored=1
  done

  if ((restored == 1)); then
    log "Bilgi: Deneysel depo yedekten geri acildi. Gerekirse daha sonra apt-get update ile elle kontrol edin."
  fi

  LEGACY_ETAP_DENEYSEL_REPO_DISABLED=0
  LEGACY_ETAP_DENEYSEL_REPO_FILES=()
}

run_apt_update_with_legacy_etap_repo_recovery() {
  local update_output update_status=0

  update_output="$(mktemp)"

  set +e
  DEBIAN_FRONTEND=noninteractive apt-get update 2>&1 | tee "${update_output}"
  update_status=${PIPESTATUS[0]}
  set -e

  if ((update_status == 0)); then
    rm -f "${update_output}"
    return 0
  fi

  if grep -Eq 'depo\.etap\.org\.tr.*deneysel|deneysel.*depo\.etap\.org\.tr' "${update_output}"; then
    log "Uyari: Eski ETAP deneysel deposu 404 hatasi veriyor."

    if disable_legacy_etap_deneysel_repo_entries; then
      log "Paket listesi guncellemesi eski depo kapatilarak yeniden deneniyor."
      rm -f "${update_output}"
      DEBIAN_FRONTEND=noninteractive apt-get update
      return 0
    fi
  fi

  rm -f "${update_output}"
  return "${update_status}"
}

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'
}

package_is_held() {
  apt-mark showhold 2>/dev/null | grep -Fxq "$1"
}

install_packages_if_missing() {
  local missing=()
  local pkg

  for pkg in "$@"; do
    if ! package_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if ((${#missing[@]})); then
    apt_update_once
    log "Kurulacak paketler: ${missing[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
  fi
}

ensure_wine_headless_runtime_tools() {
  local missing_packages=()

  if ! command -v xvfb-run >/dev/null 2>&1; then
    missing_packages+=(xvfb)
  fi

  if ! command -v xauth >/dev/null 2>&1; then
    missing_packages+=(xauth)
  fi

  if ((${#missing_packages[@]})); then
    log "Wine icin gerekli basiz araclar eksik bulundu: ${missing_packages[*]}"
    install_packages_if_missing "${missing_packages[@]}"
  fi

  command -v xvfb-run >/dev/null 2>&1 || fail "xvfb-run komutu bulunamadi. Wine adimi icin xvfb paketi gereklidir."
  command -v xauth >/dev/null 2>&1 || fail "xauth komutu bulunamadi. Wine adimi icin xauth paketi gereklidir."
  log "Wine icin xvfb-run ve xauth dogrulandi."
}

ensure_i386_architecture() {
  if ! dpkg --print-foreign-architectures | grep -qx 'i386'; then
    log "Wine icin i386 mimarisi ekleniyor."
    dpkg --add-architecture i386
    APT_UPDATED=0
  fi
}

remove_user_if_present() {
  local username="$1"

  if ! id "${username}" >/dev/null 2>&1; then
    log "${username} kullanicisi yok, atlaniyor."
    return
  fi

  log "${username} kullanicisi siliniyor."
  loginctl terminate-user "${username}" >/dev/null 2>&1 || true
  pkill -KILL -u "${username}" >/dev/null 2>&1 || true

  if ! userdel -r "${username}" >/dev/null 2>&1; then
    userdel "${username}" >/dev/null 2>&1 || true
  fi

  if getent group "${username}" >/dev/null 2>&1; then
    groupdel "${username}" >/dev/null 2>&1 || true
  fi
}

set_password_with_passwd() {
  python3 - "$1" "$2" "$3" <<'PY'
import os
import pty
import select
import signal
import sys
import unicodedata

user = sys.argv[1]
password = sys.argv[2]
current_password = sys.argv[3]

CURRENT_PROMPTS = (
    "current unix password",
    "current password",
    "old password",
    "mevcut parola",
    "mevcut sifre",
    "eski parola",
    "eski sifre",
)

FIRST_PROMPTS = (
    "new unix password",
    "new password",
    "enter new unix password",
    "yeni unix parolasi",
    "yeni parola",
    "yeni sifre",
)
SECOND_PROMPTS = (
    "retype new unix password",
    "retype new password",
    "repeat new password",
    "tekrar girin",
    "yeniden girin",
    "parolayi tekrar",
)


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = value.encode("ascii", "ignore").decode("ascii", "ignore")
    return value.lower()


pid, fd = pty.fork()
if pid == 0:
    os.execvp("passwd", ["passwd", user])

sent_current = False
sent_first = False
sent_second = False
buffer = ""

while True:
    ready, _, _ = select.select([fd], [], [], 45)
    if not ready:
        os.kill(pid, signal.SIGTERM)
        print("passwd komutundan zamaninda yanit alinamadi.", file=sys.stderr)
        _, status = os.waitpid(pid, 0)
        sys.exit(os.waitstatus_to_exitcode(status) if os.WIFEXITED(status) else 1)

    try:
        data = os.read(fd, 1024)
    except OSError:
        break

    if not data:
        break

    text = data.decode(errors="ignore")
    sys.stderr.write(text)
    sys.stderr.flush()

    buffer = (buffer + text)[-400:]
    normalized = normalize(buffer)

    if not sent_current and not sent_first and any(prompt in normalized for prompt in CURRENT_PROMPTS):
        if not current_password:
            os.kill(pid, signal.SIGTERM)
            print("passwd mevcut parola istedi ancak bir deger saglanmadi.", file=sys.stderr)
            _, status = os.waitpid(pid, 0)
            sys.exit(os.waitstatus_to_exitcode(status) if os.WIFEXITED(status) else 1)
        os.write(fd, (current_password + "\n").encode())
        sent_current = True
        buffer = ""
        continue

    if not sent_first and any(prompt in normalized for prompt in FIRST_PROMPTS):
        os.write(fd, (password + "\n").encode())
        sent_first = True
        buffer = ""
        continue

    if sent_first and not sent_second and any(prompt in normalized for prompt in SECOND_PROMPTS):
        os.write(fd, (password + "\n").encode())
        sent_second = True
        buffer = ""

_, status = os.waitpid(pid, 0)
if os.WIFEXITED(status):
    sys.exit(os.WEXITSTATUS(status))
if os.WIFSIGNALED(status):
    sys.exit(128 + os.WTERMSIG(status))
sys.exit(1)
PY
}

set_etapadmin_password() {
  local hashed_password

  getent passwd "${ETAPADMIN_USER}" >/dev/null 2>&1 || fail "${ETAPADMIN_USER} kullanicisi bulunamadi."
  log "${ETAPADMIN_USER} parolasi guncelleniyor."

  hashed_password="$(printf '%s' "${ETAPADMIN_PASSWORD}" | openssl passwd -6 -stdin)"
  if usermod -p "${hashed_password}" "${ETAPADMIN_USER}"; then
    log "${ETAPADMIN_USER} parolasi usermod yontemi ile etkilesimsiz guncellendi."
    return 0
  fi

  log "Uyari: usermod yontemi basarisiz oldu. chpasswd ile yedek deneme yapiliyor."
  if printf '%s:%s\n' "${ETAPADMIN_USER}" "${ETAPADMIN_PASSWORD}" | chpasswd; then
    log "${ETAPADMIN_USER} parolasi chpasswd yedek yontemi ile guncellendi."
    return 0
  fi

  log "Uyari: chpasswd yedek yontemi de basarisiz oldu. passwd ile son deneme yapiliyor."
  if set_password_with_passwd "${ETAPADMIN_USER}" "${ETAPADMIN_PASSWORD}" "${ETAPADMIN_CURRENT_PASSWORD}"; then
    log "${ETAPADMIN_USER} parolasi passwd son deneme yontemi ile guncellendi."
    return 0
  fi

  fail "${ETAPADMIN_USER} parolasi hicbir yontemle guncellenemedi."
}

set_board_hostname() {
  local previous_hostname

  previous_hostname="$(current_hostname)"
  log "Tahta adi ${BOARD_NAME} olarak ayarlaniyor."
  hostnamectl set-hostname "${BOARD_NAME}"
  printf '%s\n' "${BOARD_NAME}" >/etc/hostname

  if [[ -f /etc/hosts ]]; then
    if grep -qE '^127\.0\.1\.1[[:space:]]+' /etc/hosts; then
      sed -i -E "s/^127\.0\.1\.1[[:space:]]+.*/127.0.1.1\t${BOARD_NAME}/" /etc/hosts
    else
      printf '127.0.1.1\t%s\n' "${BOARD_NAME}" >>/etc/hosts
    fi
  fi

  if [[ -n "${previous_hostname}" && "${previous_hostname}" != "${BOARD_NAME}" ]]; then
    log "Onceki tahta adi: ${previous_hostname}"
  fi
}

read_process_env_value() {
  local pid="$1"
  local key="$2"

  [[ -r "/proc/${pid}/environ" ]] || return 1

  tr '\0' '\n' <"/proc/${pid}/environ" 2>/dev/null | awk -F= -v key="${key}" '
    $1 == key {
      sub(/^[^=]*=/, "", $0)
      print $0
      exit
    }
  '
}

find_session_xauthority() {
  local user_name="$1"
  local leader_pid="$2"
  local candidate uid home_dir

  candidate="$(read_process_env_value "${leader_pid}" XAUTHORITY || true)"
  if [[ -n "${candidate}" && -r "${candidate}" ]]; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  uid="$(id -u "${user_name}" 2>/dev/null || true)"
  home_dir="$(getent passwd "${user_name}" | cut -d: -f6)"

  for candidate in \
    "${home_dir}/.Xauthority" \
    "/run/user/${uid}/gdm/Xauthority"; do
    if [[ -n "${candidate}" && -r "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

ACTIVE_GUI_SESSION_TYPE=""
ACTIVE_GUI_USER=""
ACTIVE_GUI_DISPLAY=""
ACTIVE_GUI_XAUTHORITY=""
ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS=""
ACTIVE_GUI_XDG_RUNTIME_DIR=""
ACTIVE_GUI_WAYLAND_DISPLAY=""

apply_active_gui_session() {
  local session_type="$1"
  local user_name="$2"
  local display="$3"
  local xauthority="$4"
  local dbus_address="$5"
  local xdg_runtime_dir="$6"
  local wayland_display="$7"

  ACTIVE_GUI_SESSION_TYPE="${session_type}"
  ACTIVE_GUI_USER="${user_name}"
  ACTIVE_GUI_DISPLAY="${display}"
  ACTIVE_GUI_XAUTHORITY="${xauthority}"
  ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS="${dbus_address}"
  ACTIVE_GUI_XDG_RUNTIME_DIR="${xdg_runtime_dir}"
  ACTIVE_GUI_WAYLAND_DISPLAY="${wayland_display}"

  if [[ -z "${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}" && -n "${ACTIVE_GUI_XDG_RUNTIME_DIR}" ]]; then
    ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS="unix:path=${ACTIVE_GUI_XDG_RUNTIME_DIR}/bus"
  fi
}

resolve_gui_user_from_environment() {
  local user_name=""
  local uid_value=""

  if [[ -n "${ETAP23_GUI_USER:-}" ]]; then
    printf '%s\n' "${ETAP23_GUI_USER}"
    return 0
  fi

  if [[ -n "${SUDO_USER:-}" ]]; then
    printf '%s\n' "${SUDO_USER}"
    return 0
  fi

  if [[ -n "${PKEXEC_UID:-}" ]]; then
    uid_value="${PKEXEC_UID}"
    user_name="$(getent passwd "${uid_value}" 2>/dev/null | cut -d: -f1)"
    if [[ -n "${user_name}" ]]; then
      printf '%s\n' "${user_name}"
      return 0
    fi
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    user_name="$(id -un 2>/dev/null || true)"
    if [[ -n "${user_name}" ]]; then
      printf '%s\n' "${user_name}"
      return 0
    fi
  fi

  return 1
}

find_graphical_session_from_explicit_environment() {
  local session_type user_name display xauthority dbus_address xdg_runtime_dir wayland_display

  display="${ETAP23_GUI_DISPLAY:-}"
  wayland_display="${ETAP23_GUI_WAYLAND_DISPLAY:-}"
  [[ -n "${display}" || -n "${wayland_display}" ]] || return 1

  user_name="$(resolve_gui_user_from_environment || true)"
  [[ -n "${user_name}" ]] || return 1

  session_type="${ETAP23_GUI_SESSION_TYPE:-}"
  if [[ -z "${session_type}" ]]; then
    if [[ -n "${wayland_display}" ]]; then
      session_type="wayland"
    else
      session_type="x11"
    fi
  fi

  xauthority="${ETAP23_GUI_XAUTHORITY:-}"
  if [[ "${session_type}" == "x11" && -z "${xauthority}" ]]; then
    xauthority="$(find_session_xauthority "${user_name}" "" || true)"
  fi

  if [[ "${session_type}" == "x11" && ( -z "${display}" || -z "${xauthority}" ) ]]; then
    return 1
  fi

  dbus_address="${ETAP23_GUI_DBUS_SESSION_BUS_ADDRESS:-}"
  xdg_runtime_dir="${ETAP23_GUI_XDG_RUNTIME_DIR:-}"

  apply_active_gui_session \
    "${session_type}" \
    "${user_name}" \
    "${display}" \
    "${xauthority}" \
    "${dbus_address}" \
    "${xdg_runtime_dir}" \
    "${wayland_display}"

  log "Aktif grafik oturumu ortam degiskenlerinden algilandi: ${ACTIVE_GUI_USER} (${ACTIVE_GUI_SESSION_TYPE})"
  return 0
}

find_graphical_session_from_current_environment() {
  local session_type user_name display xauthority dbus_address xdg_runtime_dir wayland_display

  display="${DISPLAY:-}"
  wayland_display="${WAYLAND_DISPLAY:-}"
  [[ -n "${display}" || -n "${wayland_display}" ]] || return 1

  user_name="$(resolve_gui_user_from_environment || true)"
  [[ -n "${user_name}" ]] || return 1

  if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
    session_type="${XDG_SESSION_TYPE}"
  elif [[ -n "${wayland_display}" ]]; then
    session_type="wayland"
  else
    session_type="x11"
  fi

  xauthority="${XAUTHORITY:-}"
  if [[ "${session_type}" == "x11" && -z "${xauthority}" ]]; then
    xauthority="$(find_session_xauthority "${user_name}" "" || true)"
  fi

  if [[ "${session_type}" == "x11" && ( -z "${display}" || -z "${xauthority}" ) ]]; then
    return 1
  fi

  dbus_address="${DBUS_SESSION_BUS_ADDRESS:-}"
  xdg_runtime_dir="${XDG_RUNTIME_DIR:-}"

  apply_active_gui_session \
    "${session_type}" \
    "${user_name}" \
    "${display}" \
    "${xauthority}" \
    "${dbus_address}" \
    "${xdg_runtime_dir}" \
    "${wayland_display}"

  log "Aktif grafik oturumu mevcut ortamdan algilandi: ${ACTIVE_GUI_USER} (${ACTIVE_GUI_SESSION_TYPE})"
  return 0
}

find_active_graphical_session() {
  local session_id active remote leader user_name session_type display xauthority

  ACTIVE_GUI_SESSION_TYPE=""
  ACTIVE_GUI_USER=""
  ACTIVE_GUI_DISPLAY=""
  ACTIVE_GUI_XAUTHORITY=""
  ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS=""
  ACTIVE_GUI_XDG_RUNTIME_DIR=""
  ACTIVE_GUI_WAYLAND_DISPLAY=""

  if find_graphical_session_from_explicit_environment; then
    return 0
  fi

  if find_graphical_session_from_current_environment; then
    return 0
  fi

  command -v loginctl >/dev/null 2>&1 || return 1

  while IFS= read -r session_id; do
    [[ -n "${session_id}" ]] || continue

    active="$(loginctl show-session "${session_id}" -p Active --value 2>/dev/null || true)"
    remote="$(loginctl show-session "${session_id}" -p Remote --value 2>/dev/null || true)"
    session_type="$(loginctl show-session "${session_id}" -p Type --value 2>/dev/null || true)"
    leader="$(loginctl show-session "${session_id}" -p Leader --value 2>/dev/null || true)"
    user_name="$(loginctl show-session "${session_id}" -p Name --value 2>/dev/null || true)"

    [[ "${active}" == "yes" ]] || continue
    [[ "${remote}" == "no" ]] || continue
    [[ "${session_type}" == "x11" || "${session_type}" == "wayland" ]] || continue
    [[ -n "${leader}" && -r "/proc/${leader}/environ" ]] || continue

    display="$(read_process_env_value "${leader}" DISPLAY || true)"
    xauthority=""

    if [[ "${session_type}" == "x11" ]]; then
      xauthority="$(find_session_xauthority "${user_name}" "${leader}" || true)"
      [[ -n "${display}" && -n "${xauthority}" ]] || continue
    fi

    apply_active_gui_session \
      "${session_type}" \
      "${user_name}" \
      "${display}" \
      "${xauthority}" \
      "$(read_process_env_value "${leader}" DBUS_SESSION_BUS_ADDRESS || true)" \
      "$(read_process_env_value "${leader}" XDG_RUNTIME_DIR || true)" \
      "$(read_process_env_value "${leader}" WAYLAND_DISPLAY || true)"

    log "Aktif grafik oturumu loginctl ile algilandi: ${ACTIVE_GUI_USER} (${ACTIVE_GUI_SESSION_TYPE})"
    return 0
  done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')

  return 1
}

find_eta_kayit_desktop_file() {
  local desktop_file

  if package_installed "${ETA_KAYIT_PACKAGE}"; then
    while IFS= read -r desktop_file; do
      [[ -f "${desktop_file}" ]] || continue

      if [[ "$(basename "${desktop_file}")" == "${ETA_KAYIT_PACKAGE}.desktop" ]] || \
        [[ "$(basename "${desktop_file}")" == "${ETA_KAYIT_DESKTOP_ID}.desktop" ]] || \
        grep -Eiq 'ETA([[:space:]]+Kay[ıi]t|[[:space:]]+Register)' "${desktop_file}"; then
        printf '%s\n' "${desktop_file}"
        return 0
      fi
    done < <(dpkg-query -L "${ETA_KAYIT_PACKAGE}" 2>/dev/null | awk '/\.desktop$/ {print}')
  fi

  while IFS= read -r desktop_file; do
    [[ -f "${desktop_file}" ]] || continue

    if [[ "$(basename "${desktop_file}")" == "${ETA_KAYIT_PACKAGE}.desktop" ]] || \
      [[ "$(basename "${desktop_file}")" == "${ETA_KAYIT_DESKTOP_ID}.desktop" ]] || \
      grep -Eiq 'ETA([[:space:]]+Kay[ıi]t|[[:space:]]+Register)' "${desktop_file}"; then
      printf '%s\n' "${desktop_file}"
      return 0
    fi
  done < <(find /usr/share/applications /usr/local/share/applications -type f -name '*.desktop' 2>/dev/null | sort)

  return 1
}

find_eta_kayit_command() {
  local candidate

  for candidate in \
    "/usr/bin/${ETA_KAYIT_PACKAGE}" \
    "/usr/local/bin/${ETA_KAYIT_PACKAGE}"; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

patch_eta_kayit_mainwindow_if_needed() {
  local target_file="${ETA_KAYIT_MAINWINDOW_PATH}"
  local backup_file="${target_file}.etap23-orig"
  local patch_status=0
  local current_marker='patched by setup_etap23.sh: eta-register safe_get guards v3'

  [[ -f "${target_file}" ]] || return 0

  if grep -Fq "confirm_grid_school_label" "${target_file}" 2>/dev/null; then
    log "Yeni ETA Kayit arayuzu tespit edildi; legacy safe_get yamasi atlandi: ${target_file}"
    return 0
  fi

  if grep -Fq "${current_marker}" "${target_file}" 2>/dev/null; then
    return 0
  fi

  if [[ ! -f "${backup_file}" ]]; then
    cp -p "${target_file}" "${backup_file}" || {
      log "UYARI: ETA Kayit MainWindow.py yedegi alinamadi: ${backup_file}"
      return 0
    }
  fi

  set +e
  python3 - "${target_file}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
original = text
current_marker = "# patched by setup_etap23.sh: eta-register safe_get guards v3\n"
legacy_markers = (
    "# patched by setup_etap23.sh: guard non-dict eta-register data rows\n",
    "# patched by setup_etap23.sh: eta-register safe_get guards v2\n",
    current_marker,
)
helper_name = "_etap23_safe_get"
top_level_helper_signature = "def _etap23_safe_get("
class_helper_signature = "    def _etap23_safe_get("
top_level_helper_block = """
def _etap23_safe_get(obj, key, default=None):
    return obj.get(key, default) if isinstance(obj, dict) else default
"""
class_helper_block = """
    def _etap23_safe_get(self, obj, key, default=None):
        return _etap23_safe_get(obj, key, default)
"""

for marker in legacy_markers:
    text = text.replace(marker, "")

if top_level_helper_signature not in text:
    import_block = re.search(
        r"(?m)^(?:(?:from\s+\S+\s+import\s+[^\n]+|import\s+[^\n]+)\n)+",
        text,
    )
    if import_block:
        insert_at = import_block.end()
        text = text[:insert_at] + "\n" + top_level_helper_block.strip() + "\n\n" + text[insert_at:]
    else:
        text = top_level_helper_block.strip() + "\n\n" + text

if class_helper_signature not in text:
    class_block = re.search(r"(?m)^class\s+MainWindow\s*:\s*\n", text)
    if class_block:
        insert_at = class_block.end()
        text = text[:insert_at] + class_helper_block.strip("\n") + "\n\n" + text[insert_at:]


def replace_simple_get(match):
    return f"{helper_name}({match.group('var')}, {match.group('args')})"

patterns = [
    (
        r'(?m)^(\s*)if\s+([A-Za-z_][A-Za-z0-9_]*)\.get\("([^"]+)"\)\s*==\s*([A-Za-z_][A-Za-z0-9_]*)\s*:',
        rf'\1if {helper_name}(\2, "\3") == \4:',
    ),
    (
        r"(?m)^(\s*)if\s+([A-Za-z_][A-Za-z0-9_]*)\.get\('([^']+)'\)\s*==\s*([A-Za-z_][A-Za-z0-9_]*)\s*:",
        rf"\1if {helper_name}(\2, '\3') == \4:",
    ),
]

for pattern, replacement in patterns:
    text = re.sub(pattern, replacement, text)

text = re.sub(
    r"""(?x)
    \b(?P<var>[A-Za-z_][A-Za-z0-9_]*)\.get\(
      (?P<args>
        (?:
          "(?:[^"\\]|\\.)*"
          |
          '(?:[^'\\]|\\.)*'
        )
        (?:\s*,\s*[^)]*)?
      )
    \)
    """,
    replace_simple_get,
    text,
)

if text == original:
    raise SystemExit(3)

if current_marker not in text:
    text = current_marker + text

path.write_text(text, encoding="utf-8")
PY
  patch_status=$?
  set -e

  case "${patch_status}" in
    0)
      log "ETA Kayit MainWindow.py dosyasina safe_get guard yamasi uygulandi: ${target_file}"
      ;;
    3)
      log "ETA Kayit MainWindow.py icinde beklenen .get kullanimlari bulunamadi; patch uygulanmadi."
      ;;
    *)
      log "UYARI: ETA Kayit MainWindow.py yamasi uygulanamadi: ${target_file}"
      ;;
  esac
}

eta_kayit_mainwindow_needs_runtime_repair() {
  local target_file="${ETA_KAYIT_MAINWINDOW_PATH}"

  [[ -f "${target_file}" ]] || return 1

  if grep -Fq "confirm_grid_school_label" "${target_file}" 2>/dev/null; then
    grep -Fq "patched by setup_etap23.sh" "${target_file}" 2>/dev/null
    return
  fi

  if grep -Fq "import std_opr" "${target_file}" 2>/dev/null; then
    [[ ! -f "/usr/share/pardus/eta-register/src/std_opr.py" ]]
    return
  fi

  return 1
}

eta_kayit_backup_looks_modern_and_clean() {
  local backup_file="${ETA_KAYIT_MAINWINDOW_PATH}.etap23-orig"

  [[ -f "${backup_file}" ]] || return 1
  grep -Fq "confirm_grid_school_label" "${backup_file}" 2>/dev/null || return 1
  grep -Fq "patched by setup_etap23.sh" "${backup_file}" 2>/dev/null && return 1
  grep -Fq "import std_opr" "${backup_file}" 2>/dev/null && return 1
  return 0
}

repair_eta_kayit_runtime_if_needed() {
  local target_file="${ETA_KAYIT_MAINWINDOW_PATH}"
  local backup_file="${target_file}.etap23-orig"

  if ! eta_kayit_mainwindow_needs_runtime_repair; then
    return 0
  fi

  log "ETA Kayit MainWindow.py dosyasi bozuk veya paket surumuyle uyumsuz gorunuyor."

  if eta_kayit_backup_looks_modern_and_clean; then
    if cp -pf "${backup_file}" "${target_file}"; then
      log "ETA Kayit MainWindow.py temiz yedekten geri yuklendi: ${target_file}"
      return 0
    fi
  fi

  if package_installed "${ETA_KAYIT_PACKAGE}"; then
    log "${ETA_KAYIT_PACKAGE} paketi yeniden kurulup ETA Kayit dosyalari onariliyor."
    if DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall "${ETA_KAYIT_PACKAGE}"; then
      return 0
    fi
  fi

  log "UYARI: ETA Kayit dosyalari otomatik onarilamadi: ${target_file}"
  return 0
}

write_eta_kayit_register_helper() {
  local helper=/usr/local/libexec/etap-eta-kayit-register.py

  install -d -m 0755 /usr/local/libexec

  cat >"${helper}" <<'EOF'
#!/usr/bin/env python3
import re
import sys
import time
import unicodedata

try:
    import pyatspi
except Exception as exc:  # pragma: no cover - hedef sistemde calisacak
    print(f"python3-pyatspi kullanilamadi: {exc}", file=sys.stderr)
    sys.exit(2)

WINDOW_TERMS = ("eta kayit", "eta kayıt")
RADIO_TERMS = ("okul kodu ile kaydet",)
ENTRY_TERMS = ("okul kod", "kurum kod")
CLASS_TERMS = ("sinif", "sınıf", "sinif adi", "sınıf adı", "room name")
CHECK_CODE_TERMS = ("okul kodunu kontrol et", "okul kodunu kontol et")
SAVE_BOARD_TERMS = ("bu tahtayi kaydet", "bu tahtayı kaydet")
SAVE_TERMS = ("bu tahtayi kaydet", "bu tahtayı kaydet", "kaydet")
APPLY_TERMS = ("uygula", "apply")
CANCEL_TERMS = ("iptal et", "cancel")
CONFIRM_TERMS = ("emin misiniz", "kaydedilecektir", "akilli tahta", "akıllı tahta")
SUCCESS_TERMS = (
    "cihaziniz asagidaki bilgilerle kayitlidir",
    "your device is registered with the following information",
    "duzenle",
    "edit",
)


def debug(message):
    print(f"[eta-helper] {message}", flush=True)


def normalize(value):
    if value is None:
        return ""
    value = str(value).replace("İ", "I").replace("ı", "i")
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return " ".join(value.lower().split())


def term_matches(content, term):
    if not content or not term:
        return False
    pattern = r"(?<!\w)" + re.escape(term) + r"(?!\w)"
    return re.search(pattern, content) is not None


def iter_nodes(node, depth=0, max_depth=40):
    yield node
    if depth >= max_depth:
        return
    try:
        child_count = node.childCount
    except Exception:
        return

    for index in range(child_count):
      try:
          child = node[index]
      except Exception:
          continue
      yield from iter_nodes(child, depth + 1, max_depth)


def role_name(node):
    try:
        return normalize(node.getRoleName())
    except Exception:
        return ""


def node_name(node):
    try:
        return normalize(node.name)
    except Exception:
        return ""


def node_description(node):
    try:
        return normalize(node.description)
    except Exception:
        return ""


def node_matches(node, terms):
    content = " ".join(part for part in (node_name(node), node_description(node)) if part)
    return any(term_matches(content, term) for term in terms)


def node_content(node):
    parts = [node_name(node), node_description(node), normalize(read_text(node))]
    return " ".join(part for part in parts if part)


def extents_are_usable(extents):
    if extents is None:
        return False

    x, y, width, height = extents
    return width > 1 and height > 1 and x > -1000000 and y > -1000000


def has_editable_text(node):
    try:
        node.queryEditableText()
        return True
    except Exception:
        return False


def is_actionable(node):
    try:
        action = node.queryAction()
    except Exception:
        return False
    return action.nActions > 0


def is_enabled(node):
    try:
        state = node.getState()
    except Exception:
        return True
    return (
        state.contains(pyatspi.STATE_ENABLED)
        and state.contains(pyatspi.STATE_SENSITIVE)
        and not state.contains(pyatspi.STATE_DEFUNCT)
    )


def is_visible(node):
    extents = node_extents(node)
    if extents_are_usable(extents):
        return True

    try:
        state = node.getState()
    except Exception:
        return False

    if state.contains(pyatspi.STATE_DEFUNCT):
        return False

    return state.contains(pyatspi.STATE_SHOWING) and state.contains(pyatspi.STATE_VISIBLE)


def grab_focus(node):
    try:
        component = node.queryComponent()
        component.grabFocus()
        return True
    except Exception:
        return False


def set_text(node, value):
    editable = node.queryEditableText()
    editable.setTextContents(value)


def read_text(node):
    try:
        text_iface = node.queryText()
        return text_iface.getText(0, text_iface.characterCount)
    except Exception:
        return ""


def node_extents(node):
    try:
        component = node.queryComponent()
        extents = component.getExtents(pyatspi.XY_SCREEN)
    except Exception:
        return None

    return (
        int(extents.x),
        int(extents.y),
        int(extents.width),
        int(extents.height),
    )


def same_control(node, other):
    if other is None:
        return False
    if node is other:
        return True
    if role_name(node) != role_name(other):
        return False

    left_extents = node_extents(node)
    right_extents = node_extents(other)
    if left_extents is not None and right_extents is not None and left_extents == right_extents:
        return True

    return (
        node_name(node) == node_name(other)
        and node_description(node) == node_description(other)
        and normalize(read_text(node)) == normalize(read_text(other))
    )


def fill_entry(node, value, timeout_seconds=8, attempts=3):
    expected = normalize(value)

    for _ in range(attempts):
        grab_focus(node)
        time.sleep(0.2)
        set_text(node, value)

        deadline = time.time() + timeout_seconds
        while time.time() < deadline:
            current = normalize(read_text(node))
            if current == expected or expected in current:
                return True
            time.sleep(0.3)

        time.sleep(0.5)

    return False


def click(node):
    action = node.queryAction()
    preferred = ("click", "press", "activate")

    for index in range(action.nActions):
        name = normalize(action.getName(index))
        if any(pref in name for pref in preferred):
            return action.doAction(index)

    if action.nActions:
        return action.doAction(0)

    return False


def press_key(keysym):
    try:
        pyatspi.Registry.generateKeyboardEvent(keysym, None, pyatspi.KEY_SYM)
        return True
    except Exception:
        return False


def component_center(node):
    if node is None:
        return None

    candidates = [node]
    parent = parent_node(node)
    if parent is not None:
        candidates.append(parent)

    for candidate in iter_nodes(node, max_depth=2):
        candidates.append(candidate)

    seen = set()

    for candidate in candidates:
        marker = id(candidate)
        if marker in seen:
            continue
        seen.add(marker)

        try:
            component = candidate.queryComponent()
            extents = component.getExtents(pyatspi.XY_SCREEN)
        except Exception:
            continue

        if extents.width <= 0 or extents.height <= 0:
            continue

        x = int(extents.x + (extents.width / 2))
        y = int(extents.y + (extents.height / 2))
        return (x, y)

    return None


def move_mouse_to_node(node, settle_seconds=0.12):
    center = component_center(node)
    if center is None:
        return None

    x, y = center
    offset_x = x - 8 if x > 12 else x + 8
    offset_y = y - 8 if y > 12 else y + 8

    try:
        debug(f"Fare dugme merkezine tasiniyor: x={x} y={y}")
        pyatspi.Registry.generateMouseEvent(offset_x, offset_y, "abs")
        time.sleep(settle_seconds)
        pyatspi.Registry.generateMouseEvent(x, y, "abs")
        time.sleep(settle_seconds)
        return (x, y)
    except Exception:
        return None


def mouse_click(node):
    center = move_mouse_to_node(node)
    if center is None:
        return False

    x, y = center

    try:
        pyatspi.Registry.generateMouseEvent(x, y, "b1c")
        return True
    except Exception:
        return False


def mouse_press_release(node):
    center = move_mouse_to_node(node, settle_seconds=0.15)
    if center is None:
        return False

    x, y = center

    try:
        time.sleep(0.05)
        pyatspi.Registry.generateMouseEvent(x, y, "b1p")
        time.sleep(0.18)
        pyatspi.Registry.generateMouseEvent(x, y, "b1r")
        return True
    except Exception:
        return False


def mouse_press_release_repeat(node):
    if not mouse_press_release(node):
        return False

    time.sleep(0.2)
    return mouse_press_release(node)


def mouse_double_click(node):
    center = move_mouse_to_node(node)
    if center is None:
        return False

    x, y = center

    try:
        pyatspi.Registry.generateMouseEvent(x, y, "b1d")
        return True
    except Exception:
        return False


def parent_node(node):
    try:
        return node.parent
    except Exception:
        return None


def find_application_node(node):
    current = node
    while current is not None:
        if role_name(current) == "application":
            return current
        current = parent_node(current)
    return None


def find_window(timeout_seconds):
    deadline = time.time() + timeout_seconds
    desktop = pyatspi.Registry.getDesktop(0)

    while time.time() < deadline:
        for app_index in range(desktop.childCount):
            app = desktop[app_index]
            for node in iter_nodes(app, max_depth=4):
                role = role_name(node)
                if role not in {"frame", "window", "dialog", "application"}:
                    continue
                if node_matches(node, WINDOW_TERMS):
                    return node
        time.sleep(1)

    return None


def find_first(root, matcher):
    for node in iter_nodes(root):
        if matcher(node):
            return node
    return None


def find_button(root, terms):
    return find_first(
        root,
        lambda node: is_actionable(node)
        and is_enabled(node)
        and is_visible(node)
        and node_matches(node, terms),
    )


def wait_for_button(root, terms, timeout_seconds):
    deadline = time.time() + timeout_seconds

    while time.time() < deadline:
        button = find_button(root, terms)
        if button is not None:
            return button
        time.sleep(1)

    return None


def root_contains_terms(root, terms):
    for node in iter_nodes(root):
        if is_visible(node) and any(term_matches(node_content(node), term) for term in terms):
            return True
    return False


def save_completed(root, class_entry):
    if root_contains_terms(root, SUCCESS_TERMS):
        debug("Kaydet sonrasi basari terimi bulundu.")
        return True

    try:
        state = class_entry.getState()
        if state.contains(pyatspi.STATE_DEFUNCT):
            debug("Kaydet sonrasi sinif alani defunct oldu.")
            return True
    except Exception:
        debug("Kaydet sonrasi sinif alaninin durumu okunamadi; arayuz degismis olabilir.")
        return True

    if find_button(root, SAVE_BOARD_TERMS) is None and find_button(root, SAVE_TERMS) is None:
        debug("Kaydet sonrasi kaydet dugmesi artik gorunmuyor.")
        return True

    return False


def wait_for_success(success_probe, poll_count=15, sleep_seconds=0.4):
    if success_probe is None:
        return True

    for poll_index in range(poll_count):
        if success_probe():
            debug(f"Dugme tetikleme sonrasi durum degisti. yoklama={poll_index + 1}")
            return True
        time.sleep(sleep_seconds)

    return False


def trigger_button(button, success_probe=None, use_mouse_fallback=False, use_key_fallback=False, prefer_mouse=False):
    action_methods = [
        ("action", lambda: click(button)),
    ]

    key_methods = []
    if use_key_fallback:
        key_methods.extend([
            ("space", lambda: press_key(32)),
            ("enter", lambda: press_key(65293)),
        ])

    mouse_methods = []
    if use_mouse_fallback:
        mouse_methods.extend([
            ("mouse-press-release", lambda: mouse_press_release(button)),
            ("mouse-press-release-repeat", lambda: mouse_press_release_repeat(button)),
            ("mouse-click", lambda: mouse_click(button)),
            ("mouse-double-click", lambda: mouse_double_click(button)),
        ])

    methods = []
    if prefer_mouse:
        methods.extend(mouse_methods)
        methods.extend(action_methods)
        methods.extend(key_methods)
    else:
        methods.extend(action_methods)
        methods.extend(key_methods)
        methods.extend(mouse_methods)

    attempted = []

    for method_name, method in methods:
        method_result = method()
        attempted.append(f"{method_name}={'ok' if method_result else 'fail'}")
        debug(f"Dugme tetikleme denemesi: {attempted[-1]}")

        if not method_result:
            continue

        if wait_for_success(success_probe):
            return True

    debug(f"Dugme tetikleme sonrasi beklenen durum degisikligi gorulmedi. denemeler={attempted or ['none']}")
    return False


def describe_node(node):
    if node is None:
        return "<none>"
    return (
        f"role={role_name(node)!r} "
        f"name={node_name(node)!r} "
        f"desc={node_description(node)!r} "
        f"text={normalize(read_text(node))!r} "
        f"extents={node_extents(node)!r}"
    )


def button_debug(root, terms):
    button = find_button(root, terms)
    return describe_node(button)


def matching_nodes_debug(root, terms):
    matches = []

    for node in iter_nodes(root):
        if node_matches(node, terms):
            matches.append(describe_node(node))
            if len(matches) >= 8:
                break

    if not matches:
        return "<none>"

    return " | ".join(matches)


def related_roots(root):
    roots = []
    seen = set()

    for candidate in (root, find_application_node(root)):
        if candidate is None:
            continue

        marker = id(candidate)
        if marker in seen:
            continue

        seen.add(marker)
        roots.append(candidate)

    if not roots:
        desktop = pyatspi.Registry.getDesktop(0)
        if desktop is not None:
            roots.append(desktop)

    return roots


def find_button_across_roots(root, terms):
    for candidate_root in related_roots(root):
        button = find_button(candidate_root, terms)
        if button is not None:
            return button, candidate_root
    return None, None


def wait_for_button_across_roots(root, terms, timeout_seconds):
    deadline = time.time() + timeout_seconds

    while time.time() < deadline:
        button, owner_root = find_button_across_roots(root, terms)
        if button is not None:
            return button, owner_root
        time.sleep(1)

    return None, None


def button_debug_across_roots(root, terms):
    button, _owner_root = find_button_across_roots(root, terms)
    return describe_node(button)


def root_contains_terms_across_roots(root, terms):
    for candidate_root in related_roots(root):
        if root_contains_terms(candidate_root, terms):
            return True
    return False


def detect_post_save_state(root, class_entry):
    apply_button, _apply_root = find_button_across_roots(root, APPLY_TERMS)
    if apply_button is not None:
        debug("Kaydet sonrasi Uygula dugmesi goruldu.")
        return "apply"

    if root_contains_terms_across_roots(root, CONFIRM_TERMS):
        debug("Kaydet sonrasi onay ekrani metni goruldu.")
        return "apply"

    if root_contains_terms_across_roots(root, SUCCESS_TERMS):
        debug("Kaydet sonrasi final basari terimi bulundu.")
        return "done"

    try:
        state = class_entry.getState()
        if state.contains(pyatspi.STATE_DEFUNCT):
            debug("Kaydet sonrasi sinif alani defunct oldu.")
            return "done"
    except Exception:
        debug("Kaydet sonrasi sinif alaninin durumu okunamadi; arayuz degismis olabilir.")
        return "done"

    return None


def detect_post_apply_state(root):
    apply_button, _apply_root = find_button_across_roots(root, APPLY_TERMS)
    cancel_button, _cancel_root = find_button_across_roots(root, CANCEL_TERMS)

    if root_contains_terms_across_roots(root, SUCCESS_TERMS):
        debug("Uygula sonrasi final basari terimi bulundu.")
        return "done"

    if apply_button is not None:
        try:
            if not is_enabled(apply_button):
                debug("Uygula dugmesi tiklama sonrasi pasif gorunuyor.")
                return "done"
        except Exception:
            pass

    if not root_contains_terms_across_roots(root, CONFIRM_TERMS):
        debug("Uygula sonrasi onay ekrani metni kayboldu.")
        return "done"

    if apply_button is None and cancel_button is None:
        debug("Uygula sonrasi onay dugmeleri gorunmuyor.")
        return "done"

    return None


def activate_apply_if_present(root, timeout_seconds=12):
    apply_button, apply_root = wait_for_button_across_roots(root, APPLY_TERMS, timeout_seconds)
    if apply_button is None:
        debug("Kaydet sonrasi Uygula dugmesi beklenen surede gorunmedi.")
        return False

    debug(
        "Kaydet sonrasi Uygula dugmesi bulundu: "
        f"{describe_node(apply_button)} arama-koku={describe_node(apply_root)}"
    )

    def apply_success_probe():
        current_button = find_button(apply_root, APPLY_TERMS)
        current_cancel = find_button(apply_root, CANCEL_TERMS)

        try:
            state = apply_button.getState()
            if state.contains(pyatspi.STATE_DEFUNCT):
                debug("Uygula dugmesi defunct oldu; basari kabul edildi.")
                return "done"
            if not state.contains(pyatspi.STATE_ENABLED) or not state.contains(pyatspi.STATE_SENSITIVE):
                debug("Uygula dugmesi pasif gorunuyor; basari kabul edildi.")
                return "done"
        except Exception:
            debug("Uygula dugmesi durumu okunamadi; basari kabul edildi.")
            return "done"

        if root_contains_terms(apply_root, SUCCESS_TERMS):
            debug("Uygula kokunde final basari terimi bulundu.")
            return "done"

        if current_button is None and current_cancel is None:
            debug("Uygula kokunde onay dugmeleri gorunmuyor.")
            return "done"

        if not root_contains_terms(apply_root, CONFIRM_TERMS):
            debug("Uygula kokunde onay metni kayboldu.")
            return "done"

        return None

    return activate_button_until(
        apply_root,
        APPLY_TERMS,
        6,
        apply_success_probe,
        attempts=3,
        use_mouse_fallback=True,
        use_key_fallback=True,
        prefer_mouse=True,
    ) is not None


def activate_button(root, terms, timeout_seconds, attempts=3, use_mouse_fallback=False, use_key_fallback=False, success_probe=None, prefer_mouse=False):
    for attempt_index in range(attempts):
        button = wait_for_button(root, terms, timeout_seconds)
        if button is None:
            debug(f"Dugme bulunamadi. terms={terms!r}")
            return False

        grab_focus(root)
        grab_focus(button)
        time.sleep(0.3)
        debug(
            f"Dugme aktivasyon denemesi {attempt_index + 1}/{attempts}. "
            f"dugme={describe_node(button)}"
        )

        if trigger_button(
            button,
            success_probe=success_probe,
            use_mouse_fallback=use_mouse_fallback,
            use_key_fallback=use_key_fallback,
            prefer_mouse=prefer_mouse,
        ):
            time.sleep(0.5)
            return True

        time.sleep(1)

    debug(f"Dugme aktivasyonu basarisiz. terms={terms!r} eslesenler={matching_nodes_debug(root, terms)}")
    return False


def activate_button_until(root, terms, timeout_seconds, success_probe, attempts=3, use_mouse_fallback=False, use_key_fallback=False, prefer_mouse=False):
    for attempt_index in range(attempts):
        button = wait_for_button(root, terms, timeout_seconds)
        if button is None:
            debug(f"Dugme bulunamadi. terms={terms!r}")
            return None

        grab_focus(root)
        grab_focus(button)
        time.sleep(0.3)
        debug(
            f"Dugme aktivasyon denemesi {attempt_index + 1}/{attempts}. "
            f"dugme={describe_node(button)}"
        )

        if trigger_button(
            button,
            success_probe=lambda: success_probe() is not None,
            use_mouse_fallback=use_mouse_fallback,
            use_key_fallback=use_key_fallback,
            prefer_mouse=prefer_mouse,
        ):
            time.sleep(0.5)
            result = success_probe()
            if result is not None:
                return result

        time.sleep(1)

    debug(f"Dugme aktivasyonu basarisiz. terms={terms!r} eslesenler={matching_nodes_debug(root, terms)}")
    return None


def wait_for_class_entry(root, previous_entry, previous_value, timeout_seconds):
    deadline = time.time() + timeout_seconds

    while time.time() < deadline:
        class_entry = find_class_entry(root, previous_entry, previous_value)
        if class_entry is not None:
            return class_entry
        time.sleep(1)

    return None


def find_entry(root):
    labeled_entry = find_first(
        root,
        lambda node: has_editable_text(node)
        and is_enabled(node)
        and is_visible(node)
        and node_matches(node, ENTRY_TERMS),
    )
    if labeled_entry is not None:
        return labeled_entry

    return find_first(
        root,
        lambda node: has_editable_text(node) and is_enabled(node) and is_visible(node),
    )


def editable_entries(root):
    return [
        node
        for node in iter_nodes(root)
        if has_editable_text(node) and is_enabled(node) and is_visible(node)
    ]


def choose_best_class_entry(candidates, previous_entry, previous_value):
    previous_extents = node_extents(previous_entry)
    previous_value = normalize(previous_value)
    ranked = []

    for node in candidates:
        if same_control(node, previous_entry):
            continue

        current_text = normalize(read_text(node))
        extents = node_extents(node)
        score = 0

        if node_matches(node, CLASS_TERMS):
            score += 100
        if not current_text:
            score += 5
        if current_text and current_text == previous_value:
            score -= 100
        if current_text.isdigit():
            score -= 20

        if previous_extents is not None and extents is not None:
            if extents[1] > previous_extents[1] + 2:
                score += 20
            if extents[0] > previous_extents[0] + 2:
                score += 10

        ranked.append((
            score,
            extents[1] if extents is not None else 10 ** 9,
            extents[0] if extents is not None else 10 ** 9,
            node,
        ))

    if not ranked:
        return None

    ranked.sort(key=lambda item: (-item[0], item[1], item[2]))
    return ranked[0][3]


def find_class_entry(root, previous_entry, previous_value):
    candidates = editable_entries(root)
    labeled_candidates = [node for node in candidates if node_matches(node, CLASS_TERMS)]

    if labeled_candidates:
        return choose_best_class_entry(labeled_candidates, previous_entry, previous_value)

    return choose_best_class_entry(candidates, previous_entry, previous_value)


def choose_school_code_mode(root):
    radio = find_first(
        root,
        lambda node: is_actionable(node)
        and is_enabled(node)
        and is_visible(node)
        and role_name(node) in {"radio button", "toggle button", "push button"}
        and node_matches(node, RADIO_TERMS),
    )

    if radio is None:
        return False

    grab_focus(radio)
    return click(radio)


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--probe-window":
        return 0 if find_window(3) is not None else 1

    if len(sys.argv) != 3:
        print("Kullanim: etap-eta-kayit-register.py <kurum-kodu> <sinif>", file=sys.stderr)
        return 2

    kurum_kodu = sys.argv[1].strip()
    sinif = sys.argv[2].strip()
    if not kurum_kodu.isdigit():
        print("Kurum kodu yalnizca rakamlardan olusmalidir.", file=sys.stderr)
        return 2
    if not sinif:
        print("Sinif bilgisi bos birakilamaz.", file=sys.stderr)
        return 2

    window = find_window(45)
    if window is None:
        print("ETA Kayit penceresi bulunamadi.", file=sys.stderr)
        return 1
    debug(f"ETA penceresi bulundu: {describe_node(window)}")

    choose_school_code_mode(window)
    time.sleep(1)

    entry = find_entry(window)
    if entry is None:
        print("ETA Kayit icinde kurum kodu giris alani bulunamadi.", file=sys.stderr)
        return 1

    if not fill_entry(entry, kurum_kodu):
        print("ETA Kayit icinde kurum kodu beklenen sekilde yazilamadi.", file=sys.stderr)
        return 1
    debug(f"Kurum kodu alani dolduruldu: {describe_node(entry)}")

    check_button = wait_for_button(window, CHECK_CODE_TERMS, 15)
    if check_button is not None:
        class_entry = activate_button_until(
            window,
            CHECK_CODE_TERMS,
            15,
            lambda: wait_for_class_entry(window, entry, kurum_kodu, 6),
            attempts=3,
            use_mouse_fallback=False,
            use_key_fallback=True,
        )
        if class_entry is None:
            print(
                "ETA Kayit icinde sinif giris alani bulunamadi. "
                f"Kontrol dugmesi: {button_debug(window, CHECK_CODE_TERMS)}",
                file=sys.stderr,
            )
            return 1

        if not fill_entry(class_entry, sinif):
            print("ETA Kayit icinde sinif bilgisi beklenen sekilde yazilamadi.", file=sys.stderr)
            return 1
        debug(f"Sinif alani dolduruldu: {describe_node(class_entry)}")

        save_button = wait_for_button(window, SAVE_BOARD_TERMS, 20)
        if save_button is None:
            print("Sinif icin kaydet dugmesi bulunamadi.", file=sys.stderr)
            return 1

        post_save_state = activate_button_until(
            window,
            SAVE_BOARD_TERMS,
            20,
            lambda: detect_post_save_state(window, class_entry),
            attempts=5,
            use_mouse_fallback=False,
            use_key_fallback=True,
        )
        if post_save_state is None:
            print(
                "Sinif kaydi icin kaydet dugmesine basilamadi. "
                f"Kaydet dugmesi: {button_debug(window, SAVE_BOARD_TERMS)}",
                file=sys.stderr,
            )
            return 1

        if post_save_state == "apply" and not activate_apply_if_present(window):
            print(
                "Kaydet sonrasi Uygula dugmesine basilamadi. "
                f"Uygula dugmesi: {button_debug_across_roots(window, APPLY_TERMS)}",
                file=sys.stderr,
            )
            return 1

        print("ETA Kayit okul kodu kontrol edilip sinif bilgisi dolduruldu; kaydet ve uygula eylemleri tetiklendi.")
        return 0

    save_button = wait_for_button(window, SAVE_TERMS, 15)

    if save_button is None:
        print("Kaydet dugmesi bulunamadi.", file=sys.stderr)
        return 1

    class_entry = activate_button_until(
        window,
        SAVE_TERMS,
        15,
        lambda: wait_for_class_entry(window, entry, kurum_kodu, 6),
        attempts=3,
        use_mouse_fallback=False,
        use_key_fallback=True,
    )

    if class_entry is None:
        print(
            "ETA Kayit icinde sinif giris alani bulunamadi. "
            f"Ilk kaydet dugmesi: {button_debug(window, SAVE_TERMS)}",
            file=sys.stderr,
        )
        return 1

    if not fill_entry(class_entry, sinif):
        print("ETA Kayit icinde sinif bilgisi beklenen sekilde yazilamadi.", file=sys.stderr)
        return 1
    debug(f"Sinif alani dolduruldu: {describe_node(class_entry)}")

    save_button = wait_for_button(window, SAVE_TERMS, 20)

    if save_button is None:
        print("Sinif icin kaydet dugmesi bulunamadi.", file=sys.stderr)
        return 1

    post_save_state = activate_button_until(
        window,
        SAVE_TERMS,
        20,
        lambda: detect_post_save_state(window, class_entry),
        attempts=5,
        use_mouse_fallback=False,
        use_key_fallback=True,
    )
    if post_save_state is None:
        print(
            "Sinif kaydi icin kaydet dugmesine basilamadi. "
            f"Kaydet dugmesi: {button_debug(window, SAVE_TERMS)}",
            file=sys.stderr,
        )
        return 1

    if post_save_state == "apply" and not activate_apply_if_present(window):
        print(
            "Kaydet sonrasi Uygula dugmesine basilamadi. "
            f"Uygula dugmesi: {button_debug_across_roots(window, APPLY_TERMS)}",
            file=sys.stderr,
        )
        return 1

    print("ETA Kayit kurum kodu ve sinif bilgisi doldurulup kaydet ve uygula eylemleri tetiklendi.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF

  chmod 0755 "${helper}"
}

open_eta_kayit_if_available() {
  local desktop_file
  local eta_command
  local launch_command=()
  local env_args=()
  local helper=/usr/local/libexec/etap-eta-kayit-register.py
  local eta_log
  local helper_log
  local launch_pid=""
  local launch_status=0
  local launch_command_label=""
  local existing_window_open=0

  if ! find_active_graphical_session; then
    log "Aktif grafik oturumu bulunamadigi icin ETA Kayit otomatik acilamadi."
    log "Tahta internete bagliyken Pardus uygulama menusunden 'ETA Kayit' yazilimini acabilirsiniz."
    user_warn "ETA Kayit otomatik tamamlanamadi. Aktif grafik oturumu bulunamadigi icin uygulamayi elle acmaniz gerekiyor."
    return 0
  fi

  if package_installed "${ETA_KAYIT_PACKAGE}"; then
    if eta_command="$(find_eta_kayit_command)"; then
      launch_command=("${eta_command}")
    elif command -v gtk-launch >/dev/null 2>&1 && [[ -n "${ETA_KAYIT_DESKTOP_ID}" ]]; then
      launch_command=(gtk-launch "${ETA_KAYIT_DESKTOP_ID}")
    elif command -v gtk-launch >/dev/null 2>&1; then
      launch_command=(gtk-launch "${ETA_KAYIT_PACKAGE}")
    fi
  fi

  if ((${#launch_command[@]} == 0)) && desktop_file="$(find_eta_kayit_desktop_file)"; then
    if command -v gio >/dev/null 2>&1; then
      launch_command=(gio launch "${desktop_file}")
    elif command -v gtk-launch >/dev/null 2>&1; then
      launch_command=(gtk-launch "$(basename "${desktop_file}" .desktop)")
    fi
  fi

  if ((${#launch_command[@]} == 0)); then
    log "ETA Kayit uygulamasi bulunamadi. Beklenen paket/uygulama adi: ${ETA_KAYIT_PACKAGE}"
    log "Beklenen masaustu kimligi: ${ETA_KAYIT_DESKTOP_ID}.desktop"
    log "Pardus uygulama menusunde 'ETA Kayit' diye aratarak elle acabilirsiniz."
    user_warn "ETA Kayit otomatik tamamlanamadi. Uygulama baslatilamadi; kaydi elle acip tamamlamaniz gerekiyor."
    return 0
  fi

  repair_eta_kayit_runtime_if_needed
  patch_eta_kayit_mainwindow_if_needed

  if [[ -n "${eta_command:-}" ]]; then
    log "ETA Kayit uygulamasi paket komutu ile acilacak: ${eta_command}"
  fi
  launch_command_label="${launch_command[*]}"

  log "ETA Kayit uygulamasi aciliyor. Tahtanin internete bagli oldugundan emin olun."
  log "Okul/kurum kodu: ${ETA_KAYIT_KURUM_KODU}"
  log "Sinif: ${ETA_KAYIT_SINIF}"
  log "Kayit sirasinda yonetici yetkili sifre istenebilir."
  log "ETA Kayit baslatma komutu: ${launch_command_label}"

  [[ -n "${ACTIVE_GUI_DISPLAY}" ]] && env_args+=("DISPLAY=${ACTIVE_GUI_DISPLAY}")
  [[ -n "${ACTIVE_GUI_XAUTHORITY}" ]] && env_args+=("XAUTHORITY=${ACTIVE_GUI_XAUTHORITY}")
  [[ -n "${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}" ]] && env_args+=("DBUS_SESSION_BUS_ADDRESS=${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}")
  [[ -n "${ACTIVE_GUI_XDG_RUNTIME_DIR}" ]] && env_args+=("XDG_RUNTIME_DIR=${ACTIVE_GUI_XDG_RUNTIME_DIR}")
  [[ -n "${ACTIVE_GUI_WAYLAND_DISPLAY}" ]] && env_args+=("WAYLAND_DISPLAY=${ACTIVE_GUI_WAYLAND_DISPLAY}")

  if [[ -x "${helper}" ]] && runuser -u "${ACTIVE_GUI_USER}" -- env \
    "${env_args[@]}" \
    "${helper}" --probe-window >/dev/null 2>&1; then
    existing_window_open=1
    log "ETA Kayit penceresi zaten acik gorunuyor. Mevcut pencere uzerinden devam edilecek."
  fi

  eta_log="$(create_script_log_file eta-kayit-launch)"
  helper_log="$(create_script_log_file eta-kayit-helper)"
  log "ETA Kayit uygulama gunlugu: ${eta_log}"
  log "ETA Kayit otomasyon gunlugu: ${helper_log}"

  if (( ! existing_window_open )); then
    runuser -u "${ACTIVE_GUI_USER}" -- env \
      "${env_args[@]}" \
      "${launch_command[@]}" >"${eta_log}" 2>&1 &
    launch_pid=$!

    sleep 3

    if ! kill -0 "${launch_pid}" 2>/dev/null; then
      set +e
      wait "${launch_pid}"
      launch_status=$?
      set -e

      if grep -Eiq 'device is registered|registered[^[:alnum:]]+.*true|showing info page|status:[[:space:]]*true' "${eta_log}"; then
        log "ETA Kayit uygulamasi, bu tahtanin zaten kayitli oldugunu bildirdi. Ek islem yapilmadi."
        return 0
      fi

      log "ETA Kayit baslatma komutu erken sonlandi; pencere aramasi ile devam edilecek."
      if [[ "${launch_status}" -ne 0 ]]; then
        log "ETA Kayit baslatma komutu cikis kodu: ${launch_status}"
      fi
    else
      disown "${launch_pid}" 2>/dev/null || true
    fi
  else
    : >"${eta_log}"
  fi

  if [[ ! -x "${helper}" ]]; then
    log "ETA Kayit otomasyon yardimcisi bulunamadi. Uygulama acildi, kodu elle girebilirsiniz."
    log "Ayrintili uygulama gunlugu: ${eta_log}"
    log "Ayrintili otomasyon gunlugu: ${helper_log}"
    user_warn "ETA Kayit otomatik tamamlanamadi. Yardimci arac bulunamadigi icin kurum kodunu ve sinif bilgisini elle girmeniz gerekiyor."
    return 0
  fi

  if runuser -u "${ACTIVE_GUI_USER}" -- env \
    "${env_args[@]}" \
    "${helper}" "${ETA_KAYIT_KURUM_KODU}" "${ETA_KAYIT_SINIF}" >"${helper_log}" 2>&1; then
    sleep 2
    if grep -Eq 'Traceback \(most recent call last\)|AttributeError:|TypeError:|KeyError:' "${eta_log}"; then
      log "ETA Kayit dugmesi tetiklendi ancak uygulama icinde Python hatasi olustu."
      log "ETA Kayit otomasyon gunlugu: ${helper_log}"
      log "ETA Kayit uygulama gunlugu: ${eta_log}"
      user_warn "ETA Kayit otomatik tamamlanamadi. Uygulama icinde hata olustugu icin kaydi elle kontrol etmeniz gerekiyor."
      return 0
    fi

    log "ETA Kayit icin kurum kodu ve sinif bilgisi girilip kaydet eylemleri tetiklendi."
    log "Kayit loglari korundu. Uygulama gunlugu: ${eta_log}"
    log "Kayit loglari korundu. Otomasyon gunlugu: ${helper_log}"
  else
    if grep -Eiq 'device is registered|registered[^[:alnum:]]+.*true|showing info page|status:[[:space:]]*true' "${eta_log}"; then
      log "ETA Kayit uygulamasi, bu tahtanin zaten kayitli oldugunu bildirdi. Ek islem yapilmadi."
      return 0
    fi

    if grep -Eq 'Traceback \(most recent call last\)|AttributeError:|TypeError:|KeyError:' "${eta_log}"; then
      log "ETA Kayit dugmesi tetiklendi ancak uygulama icinde Python hatasi olustu."
      log "ETA Kayit otomasyon gunlugu: ${helper_log}"
      log "ETA Kayit uygulama gunlugu: ${eta_log}"
      user_warn "ETA Kayit otomatik tamamlanamadi. Uygulama icinde hata olustugu icin kaydi elle kontrol etmeniz gerekiyor."
      return 0
    fi

    log "ETA Kayit otomasyonu tamamlanamadi. Uygulama acik kaldi; kurum kodu, sinif ve varsa yonetici sifresini elle tamamlayabilirsiniz."
    log "ETA Kayit otomasyon gunlugu: ${helper_log}"
    log "ETA Kayit uygulama gunlugu: ${eta_log}"
    user_warn "ETA Kayit otomatik tamamlanamadi. Uygulama acik kaldi; kurum kodu, sinif ve gerekiyorsa yonetici sifresini elle tamamlamaniz gerekiyor."
  fi
}

ensure_eta_kayit_package_ready_for_launch() {
  local package_was_installed=0

  if package_installed "${ETA_KAYIT_PACKAGE}"; then
    package_was_installed=1
  fi

  if install_or_upgrade_eta_kayit_package; then
    return 0
  fi

  if ((package_was_installed)); then
    log "Uyari: ${ETA_KAYIT_PACKAGE} guncellenemedi. Mevcut kurulu surum ile ETA Kayit acilacak."
    return 0
  fi

  log "Hata: ${ETA_KAYIT_PACKAGE} paketi kurulamadigi icin ETA Kayit acilamayacak."
  return 1
}

prepare_eag_package() {
  local temp_dir fixed_deb postinst

  [[ -f "${EAG_DEB}" ]] || fail "e-ag paketi bulunamadi: ${EAG_DEB}"
  require_command dpkg-deb
  require_command sed

  temp_dir="$(mktemp -d)"
  fixed_deb="${temp_dir}/e-ag-client-fixed.deb"

  dpkg-deb -R "${EAG_DEB}" "${temp_dir}/pkg"

  postinst="${temp_dir}/pkg/DEBIAN/postinst"
  if [[ -f "${postinst}" ]] && grep -q '\[\[' "${postinst}"; then
    log "e-ag-client paketi icindeki postinst dosyasi bash uyumlu hale getiriliyor."
    sed -i '1 s|/bin/sh|/bin/bash|' "${postinst}"
  fi

  if [[ -f "${postinst}" ]] && grep -q '^e-ag-client-tray&$' "${postinst}"; then
    log "e-ag-client postinst icindeki tray baslatma adimi GUI yoksa atlanacak sekilde duzenleniyor."
    python3 - "${postinst}" <<'PY'
from pathlib import Path
import sys

postinst = Path(sys.argv[1])
content = postinst.read_text()
content = content.replace(
    "e-ag-client-tray&",
    "if command -v e-ag-client-tray >/dev/null 2>&1 && [[ -n \"${DISPLAY:-}\" ]]; then\n"
    "e-ag-client-tray >/dev/null 2>&1 &\n"
    "fi",
)
postinst.write_text(content)
PY
  fi

  dpkg-deb -b "${temp_dir}/pkg" "${fixed_deb}" >/dev/null
  printf '%s\n' "${fixed_deb}"
}

install_eag_client() {
  local deb_to_install

  deb_to_install="$(prepare_eag_package)"
  apt_update_once
  log "e-ag-client paketi kuruluyor."
  if DEBIAN_FRONTEND=noninteractive apt-get install -y "${deb_to_install}"; then
    return 0
  fi

  log "Uyari: e-ag-client ilk denemede kurulamadı. Bagimlilik onarimi deneniyor."
  DEBIAN_FRONTEND=noninteractive apt-get install -f -y || true
  log "e-ag-client kurulumu yeniden deneniyor."
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${deb_to_install}"
}

install_eta_qr_login_if_needed() {
  if package_installed eta-qr-login; then
    log "eta-qr-login zaten kurulu."
    return
  fi

  apt_update_once
  log "eta-qr-login paketi kuruluyor."
  DEBIAN_FRONTEND=noninteractive apt-get install -y eta-qr-login
}

log_eta_touchdrv_reinstall_hint() {
  log "Dokunmatik tamamen gitmisse veya beta paket kurulmus olabilecekse su komutlari deneyin:"
  log "  sudo apt update"
  log "  sudo apt purge eta-touchdrv"
  log "  sudo apt install eta-touchdrv"
  log "Bu islem beta paketi temizleyip guncel surumu yeniden kurar."
}

postcheck_eta_touchdrv_reinstall_hint() {
  postcheck_info "Dokunmatik tamamen gitmis veya beta paket suphe varsa su komutlari deneyin:"
  postcheck_info "  sudo apt update"
  postcheck_info "  sudo apt purge eta-touchdrv"
  postcheck_info "  sudo apt install eta-touchdrv"
}

eta_touchdrv_installed_version() {
  dpkg-query -W -f='${Version}' eta-touchdrv 2>/dev/null || true
}

eta_touchdrv_candidate_version() {
  apt-cache policy eta-touchdrv 2>/dev/null | awk '/Candidate:/ {print $2; exit}'
}

eta_touchdrv_service_state() {
  systemctl is-active eta-touchdrv 2>/dev/null || true
}

eta_touchdrv_status_output() {
  systemctl --no-pager --full status eta-touchdrv 2>&1 || true
}

eta_touchdrv_extract_active_line() {
  local status_output="${1:-}"
  local line trimmed

  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    if [[ "${trimmed}" == Active:* ]]; then
      printf '%s\n' "${trimmed}"
      return 0
    fi
  done <<<"${status_output}"
}

refresh_eta_touchdrv_state() {
  ETA_TOUCHDRV_STATE_INSTALLED_VERSION=""
  ETA_TOUCHDRV_STATE_CANDIDATE_VERSION=""
  ETA_TOUCHDRV_STATE_SERVICE_STATE=""
  ETA_TOUCHDRV_STATE_STATUS_OUTPUT=""
  ETA_TOUCHDRV_STATE_ACTIVE_LINE=""

  if package_installed eta-touchdrv; then
    ETA_TOUCHDRV_STATE_INSTALLED_VERSION="$(eta_touchdrv_installed_version)"
  fi

  ETA_TOUCHDRV_STATE_CANDIDATE_VERSION="$(eta_touchdrv_candidate_version)"
  ETA_TOUCHDRV_STATE_SERVICE_STATE="$(eta_touchdrv_service_state)"
  ETA_TOUCHDRV_STATE_STATUS_OUTPUT="$(eta_touchdrv_status_output)"
  ETA_TOUCHDRV_STATE_ACTIVE_LINE="$(eta_touchdrv_extract_active_line "${ETA_TOUCHDRV_STATE_STATUS_OUTPUT}" || true)"
}

log_eta_touchdrv_status_snapshot() {
  local status_output="${1:-}"
  local line

  if [[ -z "${status_output}" ]]; then
    status_output="$(eta_touchdrv_status_output)"
  fi
  [[ -n "${status_output}" ]] || return 0

  while IFS= read -r line; do
    [[ -n "${line}" ]] || continue
    log "eta-touchdrv status | ${line}"
  done <<<"${status_output}"
}

recommend_eta_touchdrv_action() {
  local recommendation line
  local first_line=1

  recommendation="$(eta_touchdrv_recommendation_text)"
  while IFS= read -r line; do
    [[ -n "${line}" ]] || continue
    if ((first_line)); then
      log "Oneri: ${line}"
      first_line=0
    else
      log "Oneri ek: ${line}"
    fi
  done <<<"${recommendation}"
}

eta_touchdrv_recommendation_text() {
  local installed_version="${ETA_TOUCHDRV_STATE_INSTALLED_VERSION}"
  local service_state="${ETA_TOUCHDRV_STATE_SERVICE_STATE}"

  if ! package_installed eta-touchdrv; then
    printf '%s\n' "Dokunmatik surucusu kurulu degil. 'Tum sistemi ve Dokunmatik Surucuyu Guncelle' secenegini kullanin."
    return 0
  fi

  if [[ -z "${installed_version}" ]]; then
    printf '%s\n' "Surum okunamadi. 'Tum sistemi degil yalnizca Dokunmatik Surucusunu Guncelle' secenegiyle paketi yenileyin."
    return 0
  fi

  if [[ "${installed_version}" == "${ETA_TOUCHDRV_TARGET_VERSION}" ]]; then
    if [[ "${service_state}" == "active" ]]; then
      printf '%s\n' "Surum guncel ve servis aktif. Su an icin ek islem gerekmiyor."
    else
      printf '%s\n' "Surum guncel ama servis aktif degil. Tahtayi yeniden baslatin ve USB cihazlarini cikarin."
      printf '%s\n' "Sorun devam ederse 'Eski Dokunmatik Surucusunu Geri Yukle' secenegini deneyin."
    fi
    return 0
  fi

  if [[ "${installed_version}" == "${ETA_TOUCHDRV_FALLBACK_VERSION}" ]]; then
    if [[ "${service_state}" == "active" ]]; then
      printf '%s\n' "Eski ama bilinen stabil surum kurulu."
      printf '%s\n' "Bolgesel sorun icin 'Tum sistemi degil yalnizca Dokunmatik Surucusunu Guncelle' secenegiyle ${ETA_TOUCHDRV_TARGET_VERSION} surumunu deneyebilirsiniz."
    else
      printf '%s\n' "Eski surum de aktif degil. Once yeniden baslatin."
      printf '%s\n' "Sorun surerse 'Tum sistemi ve Dokunmatik Surucuyu Guncelle' secenegini deneyin."
    fi
    return 0
  fi

  if dpkg --compare-versions "${installed_version}" gt "${ETA_TOUCHDRV_TARGET_VERSION}"; then
    printf '%s\n' "Kurulu surum beklenenden yeni veya beta olabilir."
    printf '%s\n' "Sorun yasaniyorsa 'Eski Dokunmatik Surucusunu Geri Yukle' secenegini kullanin."
    return 0
  fi

  printf '%s\n' "Kurulu surum hedef surumun gerisinde."
  printf '%s\n' "'Tum sistemi degil yalnizca Dokunmatik Surucusunu Guncelle' secenegini kullanin."
  if [[ "${service_state}" != "active" ]]; then
    printf '%s\n' "Guncelleme sonrasi servis yine aktif olmazsa 'Eski Dokunmatik Surucusunu Geri Yukle' secenegini deneyin."
  fi
}

write_touchdrv_user_summary() {
  local title="${1:-Dokunmatik Surucu Kontrol Ozeti}"
  local recommendation line

  [[ -n "${ETAP23_USER_SUMMARY_FILE}" ]] || return 0

  clear_user_summary
  recommendation="$(eta_touchdrv_recommendation_text)"

  append_user_summary_line "${title}"
  append_user_summary_line ""

  if package_installed eta-touchdrv; then
    append_user_summary_line "Kurulu surum: ${ETA_TOUCHDRV_STATE_INSTALLED_VERSION:-okunamadi}"
  else
    append_user_summary_line "Kurulu surum: kurulu degil"
  fi

  if [[ -n "${ETA_TOUCHDRV_STATE_CANDIDATE_VERSION}" && "${ETA_TOUCHDRV_STATE_CANDIDATE_VERSION}" != "(none)" ]]; then
    append_user_summary_line "Depo adayi: ${ETA_TOUCHDRV_STATE_CANDIDATE_VERSION}"
  fi

  if [[ "${ETA_TOUCHDRV_STATE_SERVICE_STATE}" == "active" ]]; then
    append_user_summary_line "Servis calisiyor: evet"
  else
    append_user_summary_line "Servis calisiyor: hayir"
  fi

  if [[ -n "${ETA_TOUCHDRV_STATE_ACTIVE_LINE}" ]]; then
    append_user_summary_line "systemctl status eta-touchdrv: ${ETA_TOUCHDRV_STATE_ACTIVE_LINE}"
  else
    append_user_summary_line "systemctl status eta-touchdrv: Active bilgisi okunamadi"
  fi

  append_user_summary_line ""
  append_user_summary_line "Oneri:"
  while IFS= read -r line; do
    [[ -n "${line}" ]] || continue
    append_user_summary_line "- ${line}"
  done <<<"${recommendation}"
}

report_eta_touchdrv_state() {
  local expected_version="${1:-}"
  local context="${2:-Dokunmatik surucu kontrolu}"
  local has_issue=0

  refresh_eta_touchdrv_state

  if ! package_installed eta-touchdrv; then
    log "Uyari: eta-touchdrv paketi kurulu gorunmuyor."
    log_eta_touchdrv_reinstall_hint
    return 1
  fi

  if [[ -n "${ETA_TOUCHDRV_STATE_INSTALLED_VERSION}" ]]; then
    log "eta-touchdrv surumu: ${ETA_TOUCHDRV_STATE_INSTALLED_VERSION}"
    if [[ -n "${expected_version}" ]]; then
      if [[ "${ETA_TOUCHDRV_STATE_INSTALLED_VERSION}" == "${expected_version}" ]]; then
        log "${context}: beklenen surum kurulu gorunuyor: ${ETA_TOUCHDRV_STATE_INSTALLED_VERSION}"
      else
        log "Uyari: ${context}: beklenen surum ${expected_version}, kurulu surum ${ETA_TOUCHDRV_STATE_INSTALLED_VERSION}"
        has_issue=1
      fi
    fi
  else
    log "Uyari: eta-touchdrv surumu okunamadi. 'apt-cache policy eta-touchdrv' ile kontrol edin."
    has_issue=1
  fi

  if [[ -n "${ETA_TOUCHDRV_STATE_CANDIDATE_VERSION}" && "${ETA_TOUCHDRV_STATE_CANDIDATE_VERSION}" != "(none)" ]]; then
    log "eta-touchdrv depo adayi: ${ETA_TOUCHDRV_STATE_CANDIDATE_VERSION}"
  fi

  if [[ -n "${ETA_TOUCHDRV_STATE_ACTIVE_LINE}" ]]; then
    log "systemctl status eta-touchdrv -> ${ETA_TOUCHDRV_STATE_ACTIVE_LINE}"
  fi

  if [[ "${ETA_TOUCHDRV_STATE_SERVICE_STATE}" == "active" ]]; then
    log "eta-touchdrv servisi calisiyor."
  else
    log "Uyari: eta-touchdrv servisi aktif gorunmuyor. Durum: ${ETA_TOUCHDRV_STATE_SERVICE_STATE:-bilinmiyor}"
    log "Once tahtayi yeniden baslatin ve takili diger USB cihazlarini cikarin."
    log "Durumu tekrar kontrol etmek icin: systemctl status eta-touchdrv"
    log "Surumu kontrol etmek icin: apt-cache policy eta-touchdrv"
    has_issue=1
  fi

  log_eta_touchdrv_status_snapshot "${ETA_TOUCHDRV_STATE_STATUS_OUTPUT}"

  if ((has_issue)); then
    if [[ "${expected_version}" != "${ETA_TOUCHDRV_FALLBACK_VERSION}" ]]; then
      log "Gerekirse onceki surume donus: sudo apt install eta-touchdrv=${ETA_TOUCHDRV_FALLBACK_VERSION}"
    fi
    log_eta_touchdrv_reinstall_hint
    return 1
  fi

  log "${context}: surum ve servis kontrolu basarili."
}

perform_eta_touchdrv_install_or_upgrade() {
  apt_update_once

  if package_installed eta-touchdrv; then
    log "eta-touchdrv zaten kurulu. Yalnizca surucu guncellemesi deneniyor."
    DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade eta-touchdrv
  else
    log "eta-touchdrv paketi kuruluyor."
    DEBIAN_FRONTEND=noninteractive apt-get install -y eta-touchdrv
  fi
}

perform_eta_touchdrv_only_upgrade() {
  apt_update_once

  if ! package_installed eta-touchdrv; then
    fail "eta-touchdrv kurulu degil. Bu secenek yalnizca mevcut surucuyu gunceller; yuklemek icin 'Tum sistemi ve Dokunmatik Surucuyu Guncelle' secenegini kullanin."
  fi

  log "Tum sistemi degil yalnizca eta-touchdrv paketi guncelleniyor."
  DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade eta-touchdrv
}

install_or_upgrade_eta_touchdrv() {
  perform_eta_touchdrv_install_or_upgrade
  report_eta_touchdrv_state "${ETA_TOUCHDRV_TARGET_VERSION}" "Kurulum sonrasi dokunmatik surucu kontrolu" || true
}

rollback_eta_touchdrv() {
  apt_update_once
  log "eta-touchdrv surucusu ${ETA_TOUCHDRV_FALLBACK_VERSION} surumune geri yukleniyor."
  DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades "eta-touchdrv=${ETA_TOUCHDRV_FALLBACK_VERSION}"
  report_eta_touchdrv_state "${ETA_TOUCHDRV_FALLBACK_VERSION}" "Eski dokunmatik surucusu geri yukleme kontrolu"
}

check_eta_touchdrv() {
  if report_eta_touchdrv_state "${ETA_TOUCHDRV_TARGET_VERSION}" "Dokunmatik surucu kontrolu"; then
    log "Kontrol sonucu: Dokunmatik surucusu guncel ve servis aktif."
  else
    log "Kontrol sonucu: Dokunmatik surucusunda dikkat gerektiren bir durum var."
  fi

  write_touchdrv_user_summary "Dokunmatik Surucu Kontrol Ozeti"
  recommend_eta_touchdrv_action
}

run_touchdrv_maintenance_mode() {
  require_commands_for_touchdrv_mode

  case "${ACTION_MODE}" in
    touchdrv-upgrade)
      run_step "yeni dokunmatik surucusunu kurma veya guncelleme" perform_eta_touchdrv_install_or_upgrade
      if report_eta_touchdrv_state "${ETA_TOUCHDRV_TARGET_VERSION}" "Yeni dokunmatik surucu kontrolu"; then
        log "Yeni dokunmatik surucusu kullanima hazir."
      else
        log "Yeni dokunmatik surucusu beklenen durumda degil. Eski surume geri donuluyor."
        run_step "eski dokunmatik surucusunu geri yukleme" rollback_eta_touchdrv
      fi
      ;;
    touchdrv-only-upgrade)
      run_step "yalnizca dokunmatik surucusunu guncelleme" perform_eta_touchdrv_only_upgrade
      if report_eta_touchdrv_state "${ETA_TOUCHDRV_TARGET_VERSION}" "Yalnizca dokunmatik surucusu guncelleme kontrolu"; then
        log "Dokunmatik surucusu sistem geneli guncellenmeden basariyla guncellendi."
      else
        log "Dokunmatik surucusu beklenen durumda degil. Eski surume geri donuluyor."
        run_step "eski dokunmatik surucusunu geri yukleme" rollback_eta_touchdrv
      fi
      ;;
    touchdrv-check)
      run_step "dokunmatik surucusunu kontrol etme" check_eta_touchdrv
      ;;
    touchdrv-rollback)
      run_step "eski dokunmatik surucusunu geri yukleme" rollback_eta_touchdrv
      ;;
  esac
}

normalize_touch_calibration_matrix() {
  printf '%s\n' "$1" | awk '{$1=$1; print}'
}

touch_calibration_matrix_is_valid() {
  local normalized

  normalized="$(normalize_touch_calibration_matrix "$1")"
  [[ -n "${normalized}" ]] || return 1

  printf '%s\n' "${normalized}" | awk '
    NF != 9 { exit 1 }
    {
      for (i = 1; i <= NF; ++i) {
        if ($i !~ /^[-+]?[0-9]+([.][0-9]+)?$/ && $i !~ /^[-+]?[0-9]*[.][0-9]+$/) {
          exit 1
        }
      }
    }
  '
}

touch_calibration_matrix_is_identity() {
  [[ "$(normalize_touch_calibration_matrix "$1")" == "${ETA_TOUCH_CALIBRATION_IDENTITY_MATRIX}" ]]
}

read_touch_calibration_matrix() {
  local matrix

  [[ -r "${ETA_TOUCH_CALIBRATION_FILE}" ]] || return 1
  matrix="$(head -n 1 "${ETA_TOUCH_CALIBRATION_FILE}" 2>/dev/null || true)"
  matrix="$(normalize_touch_calibration_matrix "${matrix}")"
  touch_calibration_matrix_is_valid "${matrix}" || return 1
  printf '%s\n' "${matrix}"
}

write_touch_calibration_matrix_file() {
  local matrix normalized target_dir

  matrix="$1"
  normalized="$(normalize_touch_calibration_matrix "${matrix}")"
  touch_calibration_matrix_is_valid "${normalized}" || fail "Kaydedilecek dokunmatik kalibrasyon matrisi gecersiz."

  target_dir="$(dirname "${ETA_TOUCH_CALIBRATION_FILE}")"
  install -d -m 0755 "${target_dir}"
  printf '%s\n' "${normalized}" >"${ETA_TOUCH_CALIBRATION_FILE}"
  chmod 0644 "${ETA_TOUCH_CALIBRATION_FILE}"
}

write_touch_calibration_apply_helper() {
  local helper="${ETA_TOUCH_CALIBRATION_APPLY_HELPER}"

  install -d -m 0755 "$(dirname "${helper}")"

  cat >"${helper}" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

CALIBRATION_FILE='${ETA_TOUCH_CALIBRATION_FILE}'
IDENTITY_MATRIX='${ETA_TOUCH_CALIBRATION_IDENTITY_MATRIX}'
MATRIX_OVERRIDE=""
LIST_ONLY=0

normalize_matrix() {
  printf '%s\n' "\$1" | awk '{\$1=\$1; print}'
}

matrix_is_valid() {
  local matrix
  matrix="\$(normalize_matrix "\$1")"
  [[ -n "\${matrix}" ]] || return 1

  printf '%s\n' "\${matrix}" | awk '
    NF != 9 { exit 1 }
    {
      for (i = 1; i <= NF; ++i) {
        if (\$i !~ /^[-+]?[0-9]+([.][0-9]+)?$/ && \$i !~ /^[-+]?[0-9]*[.][0-9]+$/) {
          exit 1
        }
      }
    }
  '
}

is_touch_like_name() {
  local value
  value="\${1,,}"

  [[ "\${value}" == *touch* ]] || \
    [[ "\${value}" == *digitizer* ]] || \
    [[ "\${value}" == *multitouch* ]] || \
    [[ "\${value}" == *touchscreen* ]] || \
    [[ "\${value}" == *hid* ]] || \
    [[ "\${value}" == *egalax* ]] || \
    [[ "\${value}" == *eeti* ]]
}

is_excluded_pointer_name() {
  local value
  value="\${1,,}"

  [[ "\${value}" == *mouse* ]] || \
    [[ "\${value}" == *trackpad* ]] || \
    [[ "\${value}" == *touchpad* ]] || \
    [[ "\${value}" == *virtual* ]] || \
    [[ "\${value}" == *receiver* ]] || \
    [[ "\${value}" == *keyboard* ]] || \
    [[ "\${value}" == *power* ]] || \
    [[ "\${value}" == *video* ]] || \
    [[ "\${value}" == *pen* ]] || \
    [[ "\${value}" == *stylus* ]]
}

collect_touch_devices() {
  local line id raw_name cleaned_name
  local -a preferred=()
  local -a fallback=()

  while IFS= read -r line; do
    [[ "\${line}" == *"slave  pointer"* ]] || continue
    id="\$(printf '%s\n' "\${line}" | sed -n 's/.*id=\\([0-9][0-9]*\\).*/\\1/p')"
    [[ -n "\${id}" ]] || continue
    raw_name="\${line%%id=*}"
    cleaned_name="\$(printf '%s\n' "\${raw_name}" | sed 's/[[:space:]]*↳[[:space:]]*//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
    is_excluded_pointer_name "\${cleaned_name}" && continue

    if is_touch_like_name "\${cleaned_name}"; then
      preferred+=("\${id}\t\${cleaned_name}")
    else
      fallback+=("\${id}\t\${cleaned_name}")
    fi
  done < <(xinput list --short 2>/dev/null || true)

  if (( \${#preferred[@]} > 0 )); then
    printf '%b\n' "\${preferred[@]}"
    return 0
  fi

  if (( \${#fallback[@]} > 0 )); then
    printf '%b\n' "\${fallback[@]}"
    return 0
  fi

  return 1
}

load_matrix() {
  local matrix

  if [[ -n "\${MATRIX_OVERRIDE}" ]]; then
    matrix="\${MATRIX_OVERRIDE}"
  elif [[ -r "\${CALIBRATION_FILE}" ]]; then
    matrix="\$(head -n 1 "\${CALIBRATION_FILE}" 2>/dev/null || true)"
  else
    return 1
  fi

  matrix="\$(normalize_matrix "\${matrix}")"
  matrix_is_valid "\${matrix}" || return 1
  printf '%s\n' "\${matrix}"
}

usage() {
  cat <<'USAGE'
Kullanim:
  etap-touch-apply-calibration [--list-devices] [--identity] [--matrix "a b c d e f g h i"]

Secenekler:
  --list-devices   Yalnizca algilanan dokunmatik cihazlari yaz
  --identity       Identity matris uygula
  --matrix DEG     Belirli matrisi uygula
USAGE
}

while ((\$#)); do
  case "\$1" in
    --list-devices)
      LIST_ONLY=1
      ;;
    --identity)
      MATRIX_OVERRIDE="\${IDENTITY_MATRIX}"
      ;;
    --matrix)
      shift
      [[ \$# -gt 0 ]] || { printf 'HATA: --matrix icin deger eksik.\n' >&2; exit 1; }
      MATRIX_OVERRIDE="\$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'HATA: Bilinmeyen parametre: %s\n' "\$1" >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v xinput >/dev/null 2>&1; then
  printf 'HATA: xinput bulunamadi.\n' >&2
  exit 1
fi

if [[ -z "\${DISPLAY:-}" ]]; then
  printf 'HATA: DISPLAY degiskeni bulunamadi. Kalibrasyon X11 oturumunda uygulanabilir.\n' >&2
  exit 1
fi

if ((LIST_ONLY)); then
  if collect_touch_devices; then
    exit 0
  fi

  printf 'Dokunmatik cihaz algilanamadi.\n'
  exit 2
fi

matrix="\$(load_matrix)" || {
  printf 'HATA: Uygulanacak gecerli dokunmatik kalibrasyon matrisi bulunamadi.\n' >&2
  exit 1
}

read -r -a matrix_values <<<"\${matrix}"

if ! collect_touch_devices >/tmp/etap-touch-devices.\$\$ 2>/dev/null; then
  printf 'Dokunmatik cihaz algilanamadi.\n' >&2
  rm -f /tmp/etap-touch-devices.\$\$
  exit 2
fi

applied=0
while IFS=\$'\t' read -r device_id device_name; do
  [[ -n "\${device_id}" ]] || continue

  xinput set-prop "\${device_id}" "libinput Calibration Matrix" "\${matrix_values[@]}" >/dev/null 2>&1 || true
  xinput set-prop "\${device_id}" "Coordinate Transformation Matrix" "\${matrix_values[@]}" >/dev/null 2>&1 || true
  printf 'Uygulandi: %s (id=%s)\n' "\${device_name}" "\${device_id}"
  applied=\$((applied + 1))
done </tmp/etap-touch-devices.\$\$

rm -f /tmp/etap-touch-devices.\$\$

if ((applied == 0)); then
  printf 'Dokunmatik cihaz algilanamadi.\n' >&2
  exit 2
fi

printf 'Matris: %s\n' "\${matrix}"
EOF

  chmod 0755 "${helper}"
}

write_touch_calibration_gui_helper() {
  local helper="${ETA_TOUCH_CALIBRATION_GUI_HELPER}"

  install -d -m 0755 "$(dirname "${helper}")"

  cat >"${helper}" <<'EOF'
#!/usr/bin/env python3
import sys
import tkinter as tk

IDENTITY = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]


def solve3x3(matrix, vector):
    det = (
        matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])
        - matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0])
        + matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])
    )
    if abs(det) < 1e-10:
        raise ValueError("Kalibrasyon matrisi hesaplanamadi.")

    result = [0.0, 0.0, 0.0]
    for column in range(3):
        replacement = [row[:] for row in matrix]
        for row_index in range(3):
            replacement[row_index][column] = vector[row_index]
        det_column = (
            replacement[0][0]
            * (replacement[1][1] * replacement[2][2] - replacement[1][2] * replacement[2][1])
            - replacement[0][1]
            * (replacement[1][0] * replacement[2][2] - replacement[1][2] * replacement[2][0])
            + replacement[0][2]
            * (replacement[1][0] * replacement[2][1] - replacement[1][1] * replacement[2][0])
        )
        result[column] = det_column / det
    return result


def calc_matrix(screen_points, touch_points, screen_width, screen_height):
    if len(screen_points) < 3 or len(screen_points) != len(touch_points):
        return IDENTITY

    normalized_screen = [(x / screen_width, y / screen_height) for x, y in screen_points]
    normalized_touch = [(x / screen_width, y / screen_height) for x, y in touch_points]

    count = len(normalized_touch)
    sum_xx = sum(point[0] ** 2 for point in normalized_touch)
    sum_yy = sum(point[1] ** 2 for point in normalized_touch)
    sum_xy = sum(point[0] * point[1] for point in normalized_touch)
    sum_x = sum(point[0] for point in normalized_touch)
    sum_y = sum(point[1] for point in normalized_touch)
    matrix = [[sum_xx, sum_xy, sum_x], [sum_xy, sum_yy, sum_y], [sum_x, sum_y, count]]

    abc = solve3x3(
        matrix,
        [
            sum(screen[0] * touch[0] for screen, touch in zip(normalized_screen, normalized_touch)),
            sum(screen[0] * touch[1] for screen, touch in zip(normalized_screen, normalized_touch)),
            sum(screen[0] for screen in normalized_screen),
        ],
    )
    defs = solve3x3(
        matrix,
        [
            sum(screen[1] * touch[0] for screen, touch in zip(normalized_screen, normalized_touch)),
            sum(screen[1] * touch[1] for screen, touch in zip(normalized_screen, normalized_touch)),
            sum(screen[1] for screen in normalized_screen),
        ],
    )

    values = abc + defs + [0.0, 0.0, 1.0]
    return [round(value, 6) for value in values]


def main():
    root = tk.Tk()
    root.attributes("-fullscreen", True)
    root.configure(bg="black", cursor="none")
    root.title("ETAP Dokunmatik Kalibrasyon")

    canvas = tk.Canvas(root, bg="black", highlightthickness=0)
    canvas.pack(fill="both", expand=True)
    root.update_idletasks()

    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    margin_x = int(screen_width * 0.1)
    margin_y = int(screen_height * 0.1)
    center_x = screen_width // 2
    center_y = screen_height // 2
    target_radius = max(18, min(screen_width, screen_height) // 40)

    targets = [
        (margin_x, margin_y),
        (center_x, margin_y),
        (screen_width - margin_x, margin_y),
        (margin_x, center_y),
        (center_x, center_y),
        (screen_width - margin_x, center_y),
        (margin_x, screen_height - margin_y),
        (center_x, screen_height - margin_y),
        (screen_width - margin_x, screen_height - margin_y),
    ]

    touches = []
    state = {"index": 0, "locked": False, "cancelled": False, "matrix": None}

    def draw():
        canvas.delete("all")
        index = state["index"]
        total = len(targets)

        if index >= total:
            canvas.create_text(
                center_x,
                center_y,
                text="Kalibrasyon tamamlandi",
                fill="white",
                font=("Sans", 36, "bold"),
            )
            return

        x_value, y_value = targets[index]
        canvas.create_text(
            center_x,
            90,
            text=f"Dokunmatik kalibrasyon: {index + 1}/{total}",
            fill="white",
            font=("Sans", 26, "bold"),
        )
        canvas.create_text(
            center_x,
            140,
            text="Her hedefin tam merkezine bir kez dokunun. Iptal icin ESC.",
            fill="#d8d8d8",
            font=("Sans", 18),
        )
        canvas.create_line(x_value - target_radius, y_value, x_value + target_radius, y_value, fill="#ff5a36", width=5)
        canvas.create_line(x_value, y_value - target_radius, x_value, y_value + target_radius, fill="#ff5a36", width=5)
        canvas.create_oval(
            x_value - target_radius // 2,
            y_value - target_radius // 2,
            x_value + target_radius // 2,
            y_value + target_radius // 2,
            outline="#ffd43b",
            width=4,
        )

    def cancel(_event=None):
        state["cancelled"] = True
        root.quit()

    def finish():
        try:
            state["matrix"] = calc_matrix(targets, touches, screen_width, screen_height)
        except Exception as exc:
            print(f"Kalibrasyon matrisi hesaplanamadi: {exc}", file=sys.stderr)
            root.quit()
            return
        draw()
        root.after(600, root.quit)

    def on_press(event):
        if state["locked"] or state["index"] >= len(targets):
            return

        state["locked"] = True
        touches.append((event.x_root, event.y_root))
        state["index"] += 1
        draw()

        if state["index"] >= len(targets):
            root.after(150, finish)
        else:
            root.after(180, unlock)

    def unlock():
        state["locked"] = False

    root.bind("<Escape>", cancel)
    root.bind("<Button-1>", on_press)
    root.bind("<ButtonRelease-1>", lambda _event: None)

    draw()
    root.mainloop()
    root.destroy()

    if state["cancelled"]:
        return 130

    if state["matrix"] is None:
        print("Kalibrasyon tamamlanamadi.", file=sys.stderr)
        return 1

    print("CALIBRATION_MATRIX=" + " ".join(f"{value:.6f}" for value in state["matrix"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF

  chmod 0755 "${helper}"
}

write_touch_calibration_autostart() {
  install -d -m 0755 /etc/xdg/autostart /etc/X11/Xsession.d

  cat >"${ETA_TOUCH_CALIBRATION_XSESSION}" <<EOF
#!/bin/sh
if [ -x '${ETA_TOUCH_CALIBRATION_APPLY_HELPER}' ]; then
  ( sleep 10; '${ETA_TOUCH_CALIBRATION_APPLY_HELPER}' >/dev/null 2>&1 ) &
fi
EOF

  chmod 0755 "${ETA_TOUCH_CALIBRATION_XSESSION}"

  cat >"${ETA_TOUCH_CALIBRATION_AUTOSTART}" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=ETAP Dokunmatik Kalibrasyon Uygulayicisi
Comment=Kayitli dokunmatik kalibrasyonunu grafik oturumunda uygular
Exec=${ETA_TOUCH_CALIBRATION_APPLY_HELPER}
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=15
OnlyShowIn=X-Cinnamon;GNOME;XFCE;MATE;LXQt;LXDE;
EOF

  chmod 0644 "${ETA_TOUCH_CALIBRATION_AUTOSTART}"
}

ensure_touch_calibration_runtime() {
  local missing_packages=()

  if ! command -v xinput >/dev/null 2>&1; then
    missing_packages+=(xinput)
  fi

  if ! python3 - <<'PY' >/dev/null 2>&1
import tkinter
PY
  then
    missing_packages+=(python3-tk)
  fi

  if ((${#missing_packages[@]})); then
    log "Dokunmatik kalibrasyonu icin eksik paketler bulundu: ${missing_packages[*]}"
    install_packages_if_missing "${missing_packages[@]}"
  fi

  write_touch_calibration_apply_helper
  write_touch_calibration_gui_helper
  write_touch_calibration_autostart
}

run_touch_calibration_apply_helper_as_active_user() {
  local env_args=()

  [[ -n "${ACTIVE_GUI_USER}" ]] || fail "Dokunmatik kalibrasyonu icin aktif grafik kullanicisi belirlenemedi."
  [[ -n "${ACTIVE_GUI_DISPLAY}" ]] && env_args+=("DISPLAY=${ACTIVE_GUI_DISPLAY}")
  [[ -n "${ACTIVE_GUI_XAUTHORITY}" ]] && env_args+=("XAUTHORITY=${ACTIVE_GUI_XAUTHORITY}")
  [[ -n "${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}" ]] && env_args+=("DBUS_SESSION_BUS_ADDRESS=${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}")
  [[ -n "${ACTIVE_GUI_XDG_RUNTIME_DIR}" ]] && env_args+=("XDG_RUNTIME_DIR=${ACTIVE_GUI_XDG_RUNTIME_DIR}")
  [[ -n "${ACTIVE_GUI_WAYLAND_DISPLAY}" ]] && env_args+=("WAYLAND_DISPLAY=${ACTIVE_GUI_WAYLAND_DISPLAY}")

  runuser -u "${ACTIVE_GUI_USER}" -- env \
    "${env_args[@]}" \
    "${ETA_TOUCH_CALIBRATION_APPLY_HELPER}" "$@"
}

capture_touch_calibration_matrix_from_gui() {
  local env_args=()
  local helper_output helper_log status matrix

  [[ -n "${ACTIVE_GUI_USER}" ]] || fail "Dokunmatik kalibrasyonu icin aktif grafik kullanicisi belirlenemedi."
  [[ -n "${ACTIVE_GUI_DISPLAY}" ]] && env_args+=("DISPLAY=${ACTIVE_GUI_DISPLAY}")
  [[ -n "${ACTIVE_GUI_XAUTHORITY}" ]] && env_args+=("XAUTHORITY=${ACTIVE_GUI_XAUTHORITY}")
  [[ -n "${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}" ]] && env_args+=("DBUS_SESSION_BUS_ADDRESS=${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}")
  [[ -n "${ACTIVE_GUI_XDG_RUNTIME_DIR}" ]] && env_args+=("XDG_RUNTIME_DIR=${ACTIVE_GUI_XDG_RUNTIME_DIR}")
  [[ -n "${ACTIVE_GUI_WAYLAND_DISPLAY}" ]] && env_args+=("WAYLAND_DISPLAY=${ACTIVE_GUI_WAYLAND_DISPLAY}")

  helper_log="$(create_script_log_file touch-calibration)"

  set +e
  helper_output="$(runuser -u "${ACTIVE_GUI_USER}" -- env \
    "${env_args[@]}" \
    python3 "${ETA_TOUCH_CALIBRATION_GUI_HELPER}" 2>"${helper_log}")"
  status=$?
  set -e

  case "${status}" in
    0)
      ;;
    3|130)
      log "Dokunmatik kalibrasyonu kullanici tarafindan iptal edildi."
      [[ -s "${helper_log}" ]] && log "Kalibrasyon yardimci gunlugu: ${helper_log}"
      return 130
      ;;
    *)
      log "Dokunmatik kalibrasyon yardimcisi basarisiz oldu. Cikis kodu: ${status}"
      [[ -s "${helper_log}" ]] && log "Kalibrasyon yardimci gunlugu: ${helper_log}"
      return "${status}"
      ;;
  esac

  matrix="$(printf '%s\n' "${helper_output}" | awk -F= '/^CALIBRATION_MATRIX=/ {print substr($0, index($0, "=") + 1)}' | tail -n 1)"
  matrix="$(normalize_touch_calibration_matrix "${matrix}")"
  touch_calibration_matrix_is_valid "${matrix}" || {
    log "Dokunmatik kalibrasyon yardimcisi gecersiz matris dondurdu."
    [[ -s "${helper_log}" ]] && log "Kalibrasyon yardimci gunlugu: ${helper_log}"
    return 1
  }

  [[ -s "${helper_log}" ]] && log "Kalibrasyon yardimci gunlugu: ${helper_log}"
  printf '%s\n' "${matrix}"
}

report_touch_calibration_status() {
  local saved_matrix=""
  local helper_output=""
  local helper_status=0
  local matrix_is_identity=0

  log "Dokunmatik kalibrasyon durumu kontrol ediliyor."

  if saved_matrix="$(read_touch_calibration_matrix 2>/dev/null)"; then
    log "Kayitli kalibrasyon matrisi: ${saved_matrix}"
    if touch_calibration_matrix_is_identity "${saved_matrix}"; then
      matrix_is_identity=1
      log "Kayitli matris identity degerde; ek kalibrasyon uygulanmiyor."
    fi
  else
    log "Kayitli dokunmatik kalibrasyon matrisi bulunamadi."
  fi

  if [[ -x "${ETA_TOUCH_CALIBRATION_APPLY_HELPER}" ]]; then
    log "Kalibrasyon uygulama yardimcisi hazir: ${ETA_TOUCH_CALIBRATION_APPLY_HELPER}"
  else
    log "Kalibrasyon uygulama yardimcisi henuz olusturulmamis."
  fi

  if [[ -f "${ETA_TOUCH_CALIBRATION_AUTOSTART}" ]]; then
    log "Grafik oturum otomatik uygulama dosyasi var: ${ETA_TOUCH_CALIBRATION_AUTOSTART}"
  else
    log "Grafik oturum otomatik uygulama dosyasi bulunamadi."
  fi

  if [[ -f "${ETA_TOUCH_CALIBRATION_XSESSION}" ]]; then
    log "X11 oturum geri donus betigi var: ${ETA_TOUCH_CALIBRATION_XSESSION}"
  else
    log "X11 oturum geri donus betigi bulunamadi."
  fi

  if find_active_graphical_session; then
    log "Aktif grafik oturumu: ${ACTIVE_GUI_USER} (${ACTIVE_GUI_SESSION_TYPE})"
    if [[ "${ACTIVE_GUI_SESSION_TYPE}" == "x11" && -x "${ETA_TOUCH_CALIBRATION_APPLY_HELPER}" ]]; then
      set +e
      helper_output="$(run_touch_calibration_apply_helper_as_active_user --list-devices 2>&1)"
      helper_status=$?
      set -e

      if [[ -n "${helper_output}" ]]; then
        while IFS= read -r line; do
          [[ -n "${line}" ]] || continue
          log "Dokunmatik cihaz: ${line}"
        done <<<"${helper_output}"
      fi

      if [[ "${helper_status}" -eq 0 ]]; then
        log "Dokunmatik cihaz listesi alindi."
      else
        log "Dokunmatik cihaz listesi okunamadi veya su an cihaz algilanmadi."
      fi
    elif [[ "${ACTIVE_GUI_SESSION_TYPE}" != "x11" ]]; then
      log "Dokunmatik kalibrasyon araci X11 oturumunda calisir. Bulunan oturum tipi: ${ACTIVE_GUI_SESSION_TYPE}"
    fi
  else
    log "Aktif grafik oturumu su an bulunamadi."
  fi

  if [[ -z "${saved_matrix}" || "${matrix_is_identity}" -eq 1 ]]; then
    log "Oneri: Dokunmatik hassasiyet kayiksa 'Dokunmatik Kalibrasyonunu Baslat' secenegini calistirin."
  else
    log "Oneri: Dokunmatik kayik degilse mevcut kalibrasyon korunabilir; sorun varsa yeniden kalibrasyon baslatin."
  fi
}

start_touch_calibration() {
  local previous_matrix=""
  local matrix=""
  local status=0

  ensure_touch_calibration_runtime
  find_active_graphical_session || fail "Aktif grafik oturumu bulunamadi. Dokunmatik kalibrasyonu yalnizca acik masaustu oturumunda baslatilabilir."
  [[ "${ACTIVE_GUI_SESSION_TYPE}" == "x11" ]] || \
    fail "Dokunmatik kalibrasyon araci su an yalnizca X11 oturumunu destekler. Bulunan oturum tipi: ${ACTIVE_GUI_SESSION_TYPE}"

  previous_matrix="$(read_touch_calibration_matrix 2>/dev/null || true)"

  log "Dokunmatik kalibrasyonu baslatiliyor. Kullanici: ${ACTIVE_GUI_USER}"
  log "Ekrandaki hedeflerin tam merkezine sirayla dokunun. Iptal etmek icin ESC tusuna basin."

  if ! run_touch_calibration_apply_helper_as_active_user --identity; then
    log "Uyari: Kalibrasyon oncesi identity matris uygulanamadi. Yine de kalibrasyon deneniyor."
  fi

  set +e
  matrix="$(capture_touch_calibration_matrix_from_gui)"
  status=$?
  set -e

  case "${status}" in
    0)
      ;;
    130)
      if [[ -n "${previous_matrix}" ]]; then
        log "Kalibrasyon iptal edildi. Onceki kayitli kalibrasyon geri uygulanmaya calisiliyor."
        run_touch_calibration_apply_helper_as_active_user --matrix "${previous_matrix}" >/dev/null 2>&1 || true
      else
        log "Kalibrasyon iptal edildi. Gevsek ayari sifirlamak icin identity matris geri uygulaniyor."
        run_touch_calibration_apply_helper_as_active_user --identity >/dev/null 2>&1 || true
      fi
      return 0
      ;;
    *)
      fail "Dokunmatik kalibrasyonu tamamlanamadi."
      ;;
  esac

  write_touch_calibration_matrix_file "${matrix}"
  log "Dokunmatik kalibrasyon matrisi kaydedildi: ${ETA_TOUCH_CALIBRATION_FILE}"

  if ! run_touch_calibration_apply_helper_as_active_user --matrix "${matrix}"; then
    log "Uyari: Yeni kalibrasyon matrisi aktif oturuma hemen uygulanamadi."
    log "Kayitli matris sonraki grafik oturumunda otomatik uygulanacak."
  else
    log "Yeni kalibrasyon matrisi aktif oturuma uygulandi."
  fi

  log "Grafik oturum otomatik uygulamasi etkin: ${ETA_TOUCH_CALIBRATION_AUTOSTART}"
}

reset_touch_calibration() {
  local status=0

  if [[ -f "${ETA_TOUCH_CALIBRATION_FILE}" ]]; then
    rm -f "${ETA_TOUCH_CALIBRATION_FILE}"
    log "Kayitli dokunmatik kalibrasyon dosyasi kaldirildi: ${ETA_TOUCH_CALIBRATION_FILE}"
  else
    log "Kayitli dokunmatik kalibrasyon dosyasi zaten bulunmuyordu."
  fi

  write_touch_calibration_apply_helper

  if find_active_graphical_session && [[ "${ACTIVE_GUI_SESSION_TYPE}" == "x11" ]]; then
    set +e
    run_touch_calibration_apply_helper_as_active_user --identity
    status=$?
    set -e

    if [[ "${status}" -eq 0 ]]; then
      log "Aktif oturumda identity matris uygulandi."
    else
      log "Uyari: Aktif oturumda identity matris hemen uygulanamadi."
    fi
  else
    log "Aktif X11 oturumu bulunamadigi icin matris simdi uygulanamadi."
  fi

  log "Sonraki oturumlarda varsayilan dokunmatik eslemesi kullanilacak."
}

run_touch_calibration_mode() {
  require_commands_for_touch_calibration_mode

  case "${ACTION_MODE}" in
    touch-calibration-start)
      run_step "dokunmatik kalibrasyonunu baslatma" start_touch_calibration
      ;;
    touch-calibration-status)
      run_step "dokunmatik kalibrasyon durumunu kontrol etme" report_touch_calibration_status
      ;;
    touch-calibration-reset)
      run_step "dokunmatik kalibrasyonunu sifirlama" reset_touch_calibration
      ;;
  esac
}

install_or_upgrade_eta_kayit_package() {
  apt_update_once

  if package_installed "${ETA_KAYIT_PACKAGE}"; then
    log "${ETA_KAYIT_PACKAGE} zaten kurulu. Guncelleme kontrolu yapiliyor."
    DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade "${ETA_KAYIT_PACKAGE}"
  else
    log "${ETA_KAYIT_PACKAGE} paketi kuruluyor."
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${ETA_KAYIT_PACKAGE}"
  fi
}

purge_ahenk_package() {
  if ! dpkg-query -W -f='${Status}' "${AHENK_PACKAGE}" >/dev/null 2>&1; then
    log "${AHENK_PACKAGE} paketi kurulu degil. Purge adimi atlandi."
    return 0
  fi

  log "${AHENK_PACKAGE} paketi kaldiriliyor."
  if DEBIAN_FRONTEND=noninteractive apt-get purge -y "${AHENK_PACKAGE}"; then
    return 0
  fi

  log "Uyari: ${AHENK_PACKAGE} purge adimi ilk denemede basarisiz oldu."
  log "Kalinti Ahenk klasorleri temizlenip purge islemi yeniden denenecek."
  remove_ahenk_leftover_dirs

  if DEBIAN_FRONTEND=noninteractive apt-get purge -y "${AHENK_PACKAGE}"; then
    return 0
  fi

  log "Uyari: apt-get purge ikinci denemede de basarisiz oldu. dpkg --purge denenecek."
  dpkg --purge "${AHENK_PACKAGE}"
}

remove_ahenk_db_if_present() {
  if [[ -f "${AHENK_DB_PATH}" ]]; then
    rm -f "${AHENK_DB_PATH}"
    log "${AHENK_DB_PATH} silindi."
  else
    log "${AHENK_DB_PATH} bulunamadi."
  fi
}

remove_ahenk_leftover_dirs() {
  local leftover_dir

  for leftover_dir in "${AHENK_LEFTOVER_DIRS[@]}"; do
    [[ -n "${leftover_dir}" ]] || continue

    case "${leftover_dir}" in
      /usr/share/ahenk|/var/lib/ahenk|/var/log/ahenk|/etc/ahenk)
        ;;
      *)
        log "Uyari: Beklenmeyen Ahenk kalinti yolu atlandi: ${leftover_dir}"
        continue
        ;;
    esac

    if [[ -e "${leftover_dir}" ]]; then
      log "Kalinti Ahenk yolu temizleniyor: ${leftover_dir}"
      rm -rf -- "${leftover_dir}"
    fi
  done
}

cleanup_ahenk_dependencies() {
  log "Gereksiz paketler temizleniyor."
  DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y
  DEBIAN_FRONTEND=noninteractive apt-get autoclean -y
}

reinstall_ahenk_package() {
  apt_update_once
  log "${AHENK_PACKAGE} yeniden kuruluyor."
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${AHENK_PACKAGE}"
}

upgrade_all_packages_last_resort() {
  apt_update_once
  log "Son care olarak tum sistem paketleri guncelleniyor."
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
}

repair_eta_kayit_registration() {
  run_step "eta-register paketini kurma veya guncelleme" install_or_upgrade_eta_kayit_package
  run_step "ahenk paketini kaldirma" purge_ahenk_package
  run_step "ahenk kayit verisini temizleme" remove_ahenk_db_if_present
  run_step "ahenk kalinti klasorlerini temizleme" remove_ahenk_leftover_dirs
  run_step "gereksiz paketleri temizleme" cleanup_ahenk_dependencies

  if [[ "${ACTION_MODE}" == "eta-kayit-repair-reinstall-ahenk" || "${ACTION_MODE}" == "eta-kayit-repair-full-upgrade" ]]; then
    run_step "ahenk paketini yeniden kurma" reinstall_ahenk_package
  fi

  if [[ "${ACTION_MODE}" == "eta-kayit-repair-full-upgrade" ]]; then
    run_step "tum sistem paketlerini guncelleme" upgrade_all_packages_last_resort
  fi

  log "ETA Kayit kayit onarim akisi tamamlandi."
  log "Sonraki adim: ETA Kayit uygulamasini acip kaydi tekrar deneyin."
}

run_eta_kayit_repair_mode() {
  require_commands_for_eta_kayit_mode
  repair_eta_kayit_registration
}

configure_screensaver_policy() {
  local helper=/usr/local/bin/etap-disable-screensaver
  local autostart=/etc/xdg/autostart/etap-disable-screensaver.desktop
  local xsession=/etc/X11/Xsession.d/90etap-disable-screensaver

  if ! is_enabled "${ENABLE_DISABLE_SCREENSAVER}"; then
    log "Ekran koruyucu ayari atlandi; varsa onceki ETAP ayarlari temizleniyor."
    rm -f "${helper}" "${autostart}" "${xsession}"
    return
  fi

  install -d -m 0755 /etc/xdg/autostart /etc/X11/Xsession.d /usr/local/bin

  cat >"${helper}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DISPLAY:-}" ]]; then
  exit 0
fi

if ! command -v xset >/dev/null 2>&1; then
  exit 0
fi

xset s off >/dev/null 2>&1 || true
xset -dpms >/dev/null 2>&1 || true
xset s noblank >/dev/null 2>&1 || true
EOF

  chmod 0755 "${helper}"

  cat >"${xsession}" <<'EOF'
#!/bin/sh
if [ -x /usr/local/bin/etap-disable-screensaver ]; then
  /usr/local/bin/etap-disable-screensaver
fi
EOF

  chmod 0755 "${xsession}"

  cat >"${autostart}" <<'EOF'
[Desktop Entry]
Type=Application
Name=ETAP Disable Screensaver
Comment=Disable screensaver, blanking and DPMS for ETAP boards
Exec=/usr/local/bin/etap-disable-screensaver
OnlyShowIn=GNOME;XFCE;LXDE;MATE;LXQt;KDE;Unity;X-Cinnamon;
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

  log "Ekran koruyucu, ekran karartma ve DPMS kapatma ayari uygulandi."
}

write_wine_bootstrap_script() {
  local bootstrap=/usr/local/libexec/etap-wine-bootstrap
  local quoted_prefix_name quoted_windows_version quoted_packages quoted_vulkan_packages
  local system_wine_bin system_wineboot_bin system_winecfg_bin system_winetricks_bin system_wineserver_bin

  install -d -m 0755 /usr/local/libexec
  printf -v quoted_prefix_name '%q' "${WINE_PREFIX_NAME}"
  printf -v quoted_windows_version '%q' "${WINE_WINDOWS_VERSION}"
  printf -v quoted_packages '%q' "${WINETRICKS_PACKAGES}"
  printf -v quoted_vulkan_packages '%q' "${WINETRICKS_VULKAN_PACKAGES}"
  system_wine_bin="$(resolve_system_command wine)"
  system_wineboot_bin="$(resolve_system_command wineboot)"
  system_winecfg_bin="$(resolve_system_command winecfg)"
  system_winetricks_bin="$(resolve_system_command winetricks)"
  system_wineserver_bin="$(resolve_system_command wineserver)"

  cat >"${bootstrap}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

WINE_PREFIX_NAME=${quoted_prefix_name}
WINE_WINDOWS_VERSION=${quoted_windows_version}
WINETRICKS_PACKAGES=${quoted_packages}
ENABLE_WINE_VULKAN_TRANSLATORS=${ENABLE_WINE_VULKAN_TRANSLATORS}
WINETRICKS_VULKAN_PACKAGES=${quoted_vulkan_packages}
export WINEARCH=win32
export WINEDEBUG='-all'
export WINEPREFIX="\${ETAP_WINE_PREFIX:-\${HOME}/\${WINE_PREFIX_NAME}}"
export WINETRICKS_GUI=none
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
BOOTSTRAP_SCHEMA_VERSION=2
XVFB_SERVER_ARGS="-screen 0 1024x768x24 -nolisten tcp +extension GLX +extension RANDR"
MARKER_FILE="\${WINEPREFIX}/.etap-wine-config"
MARKER_VALUE="schema=\${BOOTSTRAP_SCHEMA_VERSION};windows=\${WINE_WINDOWS_VERSION};packages=\${WINETRICKS_PACKAGES};vulkan=\${ENABLE_WINE_VULKAN_TRANSLATORS};vulkan_packages=\${WINETRICKS_VULKAN_PACKAGES};prefix=\${WINE_PREFIX_NAME}"
USER_NAME="\$(id -un)"
USER_ID="\$(id -u)"
SAFE_RUNTIME_DIR=""

mkdir -p "\${WINEPREFIX}"

if [[ -f "\${MARKER_FILE}" ]] && [[ "\$(<"\${MARKER_FILE}")" == "\${MARKER_VALUE}" ]]; then
  exit 0
fi

if [[ -d "/run/user/\${USER_ID}" ]]; then
  SAFE_RUNTIME_DIR="/run/user/\${USER_ID}"
fi

sanitize_graphical_environment() {
  unset DISPLAY XAUTHORITY WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS DESKTOP_STARTUP_ID SESSION_MANAGER
  if [[ -n "\${SAFE_RUNTIME_DIR}" ]]; then
    export XDG_RUNTIME_DIR="\${SAFE_RUNTIME_DIR}"
  else
    unset XDG_RUNTIME_DIR
  fi
}

refresh_font_cache_if_possible() {
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 || true
  fi
}

stop_wineserver_if_needed() {
  sanitize_graphical_environment
  env \
    HOME="\${HOME}" \
    USER="\${USER_NAME}" \
    LOGNAME="\${USER_NAME}" \
    PATH="\${PATH}" \
    WINEPREFIX="\${WINEPREFIX}" \
    ${system_wineserver_bin} -k >/dev/null 2>&1 || true
}

run_wine_step() {
  local description="\$1"
  local status=0
  local step_log
  local filtered_log
  local benign_xvfb_shutdown=0
  local pid=0
  local heartbeat_counter=0
  shift

  printf 'Wine adimi basliyor: %s\n' "\${description}"
  printf 'Bilgi: Bu adim sessiz calisabilir; pencere bir sure ayni gorunebilir.\n'
  step_log="\$(mktemp)"
  sanitize_graphical_environment
  xvfb-run -a -s "\${XVFB_SERVER_ARGS}" env \
    HOME="\${HOME}" \
    USER="\${USER_NAME}" \
    LOGNAME="\${USER_NAME}" \
    PATH="\${PATH}" \
    WINEARCH="\${WINEARCH}" \
    WINEPREFIX="\${WINEPREFIX}" \
    WINEDEBUG="\${WINEDEBUG}" \
    WINEDLLOVERRIDES='mscoree,mshtml=' \
    WINETRICKS_GUI="\${WINETRICKS_GUI}" \
    LIBGL_ALWAYS_SOFTWARE="\${LIBGL_ALWAYS_SOFTWARE}" \
    GALLIUM_DRIVER="\${GALLIUM_DRIVER}" \
    MESA_LOADER_DRIVER_OVERRIDE="\${MESA_LOADER_DRIVER_OVERRIDE}" \
    "\$@" >"\${step_log}" 2>&1 &
  pid=\$!
  while kill -0 "\${pid}" >/dev/null 2>&1; do
    sleep 15
    heartbeat_counter=\$((heartbeat_counter + 15))
    printf 'Bilgi: %s adimi suruyor... (%ss)\n' "\${description}" "\${heartbeat_counter}"
  done
  wait "\${pid}" || status=\$?

  if [[ "\${status}" -ne 0 ]] && \
    grep -Fq 'XIO:  fatal IO error' "\${step_log}" && \
    ! grep -Eiq '(err:|failed|failure|traceback|unhandled|hata|cannot|unable)' "\${step_log}"; then
    benign_xvfb_shutdown=1
  fi

  if [[ -s "\${step_log}" ]]; then
    filtered_log="\$(mktemp)"
    grep -Eiv \
      -e '^X connection to :[0-9]+ broken \(explicit kill or server shutdown\)\.$' \
      -e '^XIO:  fatal IO error [0-9]+ .* on X server ":[0-9]+"$' \
      -e '^[[:space:]]*after [0-9]+ requests \([0-9]+ known processed\) with [0-9]+ events remaining\.$' \
      "\${step_log}" >"\${filtered_log}" || true

    if [[ -s "\${filtered_log}" ]]; then
      cat "\${filtered_log}"
    elif [[ "\${benign_xvfb_shutdown}" -eq 0 ]]; then
      cat "\${step_log}"
    fi

    rm -f "\${filtered_log}"
  fi

  if [[ "\${benign_xvfb_shutdown}" -eq 1 ]]; then
    printf 'Bilgi: %s adiminda Xvfb kapanis uyarisi goruldu; adim tamamlanmis kabul ediliyor.\n' "\${description}"
    status=0
  fi

  stop_wineserver_if_needed
  rm -f "\${step_log}"
  if [[ "\${status}" -ne 0 ]]; then
    return "\${status}"
  fi
  printf 'Wine adimi tamamlandi: %s\n' "\${description}"
}

printf 'Wine ortami hazirlaniyor: %s\n' "\${WINEPREFIX}"
if [[ "\${ENABLE_WINE_VULKAN_TRANSLATORS}" == "1" ]]; then
  printf 'Bilgi: dxvk ve vkd3d icin Vulkan gerekir. Eski Intel iGPU sistemlerde sorun olusabilir.\n'
fi

refresh_font_cache_if_possible
run_wine_step "wineboot baslatma" ${system_wineboot_bin} --init
run_wine_step "Windows surumu ayarlama" ${system_winecfg_bin} -v "\${WINE_WINDOWS_VERSION}"

if [[ -n "\${WINETRICKS_PACKAGES}" ]]; then
  read -r -a tricks <<<"\${WINETRICKS_PACKAGES}"
  run_wine_step "Winetricks temel paketleri kurma" ${system_winetricks_bin} -q "\${tricks[@]}"
fi

if [[ "\${ENABLE_WINE_VULKAN_TRANSLATORS}" == "1" ]] && [[ -n "\${WINETRICKS_VULKAN_PACKAGES}" ]]; then
  read -r -a vulkan_tricks <<<"\${WINETRICKS_VULKAN_PACKAGES}"
  run_wine_step "Winetricks Vulkan paketleri kurma" ${system_winetricks_bin} -q "\${vulkan_tricks[@]}"
fi

refresh_font_cache_if_possible
run_wine_step "Wine prefix guncelleme" ${system_wineboot_bin} -u
run_wine_step "Wine grafik kayit ayarlari" ${system_wine_bin} reg add 'HKCU\Software\Wine\Direct3D' /v DirectDrawRenderer /t REG_SZ /d opengl /f
run_wine_step "Wine video bellegi ayari" ${system_wine_bin} reg add 'HKCU\Software\Wine\Direct3D' /v VideoMemorySize /t REG_SZ /d 512 /f
run_wine_step "Wine coklu ornekleme ayari" ${system_wine_bin} reg add 'HKCU\Software\Wine\Direct3D' /v Multisampling /t REG_SZ /d disabled /f

printf '%s\n' "\${MARKER_VALUE}" >"\${MARKER_FILE}"
printf 'Wine ortami hazir.\n'
EOF

  chmod 0755 "${bootstrap}"
}

write_wine_shortcut_sync_script() {
  local helper=/usr/local/libexec/etap-wine-sync-shortcuts
  local opener=/usr/local/libexec/etap-wine-open-shortcut
  local quoted_prefix_name

  printf -v quoted_prefix_name '%q' "${WINE_PREFIX_NAME}"
  install -d -m 0755 /usr/local/libexec

  cat >"${opener}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

shortcut_path="${1:-}"
[[ -n "${shortcut_path}" && -e "${shortcut_path}" ]] || exit 1

exec /usr/local/bin/etap-wine start /unix "${shortcut_path}"
EOF

  chmod 0755 "${opener}"

  cat >"${helper}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

WINE_PREFIX_NAME=${quoted_prefix_name}
export WINEPREFIX="\${ETAP_WINE_PREFIX:-\${HOME}/\${WINE_PREFIX_NAME}}"
LINUX_SOURCE_DIR="\${XDG_DATA_HOME:-\${HOME}/.local/share}/applications/wine"
PROFILE_BASE_DIR="\${WINEPREFIX}/drive_c/users/\${USER}"
PROFILE_DESKTOP_DIR="\${PROFILE_BASE_DIR}/Desktop"
PROFILE_START_MENU_DIR="\${PROFILE_BASE_DIR}/Start Menu"
TARGET_PREFIX="etap-wine-"

resolve_desktop_dir() {
  local config_file value candidate

  if command -v xdg-user-dir >/dev/null 2>&1; then
    candidate="\$(xdg-user-dir DESKTOP 2>/dev/null || true)"
    if [[ -n "\${candidate}" && "\${candidate}" != "\${HOME}" ]]; then
      printf '%s\n' "\${candidate}"
      return 0
    fi
  fi

  config_file="\${XDG_CONFIG_HOME:-\${HOME}/.config}/user-dirs.dirs"
  if [[ -r "\${config_file}" ]]; then
    value="\$(sed -n 's/^XDG_DESKTOP_DIR=\"\\(.*\\)\"$/\\1/p' "\${config_file}" | head -n 1)"
    if [[ -n "\${value}" ]]; then
      value="\${value//\\\$HOME/\${HOME}}"
      printf '%s\n' "\${value}"
      return 0
    fi
  fi

  for candidate in "\${HOME}/Desktop" "\${HOME}/Masaustu"; do
    if [[ -d "\${candidate}" ]]; then
      printf '%s\n' "\${candidate}"
      return 0
    fi
  done

  printf '%s\n' "\${HOME}/Desktop"
}

desktop_dir="\$(resolve_desktop_dir)"
mkdir -p "\${desktop_dir}"

declare -A expected_targets=()
declare -A synced_names=()

normalize_name() {
  local value="\$1"
  value="\${value,,}"
  value="\${value//[^a-z0-9]/}"
  printf '%s\n' "\${value}"
}

mark_trusted_if_possible() {
  local target_file="\$1"

  chmod 0755 "\${target_file}" 2>/dev/null || true
  if command -v gio >/dev/null 2>&1; then
    gio set "\${target_file}" metadata::trusted true >/dev/null 2>&1 || true
  fi
}

sync_linux_desktop_entry() {
  local source_file="\$1"
  local relative_path safe_name target_file display_name normalized_name

  relative_path="\${source_file#\${LINUX_SOURCE_DIR}/}"
  safe_name="\${relative_path//\//__}"
  target_file="\${desktop_dir}/\${TARGET_PREFIX}app-\${safe_name}"
  expected_targets["\${target_file}"]=1

  display_name="\$(basename "\${source_file}" .desktop)"
  normalized_name="\$(normalize_name "\${display_name}")"
  if [[ -n "\${normalized_name}" ]]; then
    synced_names["\${normalized_name}"]=1
  fi

  if [[ ! -f "\${target_file}" ]] || ! cmp -s "\${source_file}" "\${target_file}"; then
    install -m 0755 "\${source_file}" "\${target_file}"
    mark_trusted_if_possible "\${target_file}"
  fi
}

sync_lnk_shortcut() {
  local source_file="\$1"
  local source_tag="\$2"
  local relative_path safe_name target_file display_name normalized_name
  local escaped_name escaped_path

  display_name="\$(basename "\${source_file}" .lnk)"
  normalized_name="\$(normalize_name "\${display_name}")"
  if [[ -n "\${normalized_name}" && -n "\${synced_names[\${normalized_name}]+x}" ]]; then
    return 0
  fi

  relative_path="\${source_file#\${PROFILE_BASE_DIR}/}"
  safe_name="\${relative_path//\//__}"
  target_file="\${desktop_dir}/\${TARGET_PREFIX}\${source_tag}-\${safe_name%.lnk}.desktop"
  expected_targets["\${target_file}"]=1

  escaped_name="\${display_name//\\/\\\\}"
  escaped_name="\${escaped_name//\"/\\\"}"
  escaped_path="\${source_file//\\/\\\\}"
  escaped_path="\${escaped_path//\"/\\\"}"

  cat >"\${target_file}" <<DESKTOP_EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=\${escaped_name}
Comment=Wine kisayolu
Exec=/usr/local/libexec/etap-wine-open-shortcut "\${escaped_path}"
Icon=wine
Terminal=false
StartupNotify=true
Categories=Wine;
DESKTOP_EOF

  mark_trusted_if_possible "\${target_file}"
  if [[ -n "\${normalized_name}" ]]; then
    synced_names["\${normalized_name}"]=1
  fi
}

if [[ -d "\${LINUX_SOURCE_DIR}" ]]; then
  while IFS= read -r -d '' source_file; do
    sync_linux_desktop_entry "\${source_file}"
  done < <(find "\${LINUX_SOURCE_DIR}" -type f -name '*.desktop' -print0 2>/dev/null)
fi

if [[ -d "\${PROFILE_DESKTOP_DIR}" ]]; then
  while IFS= read -r -d '' source_file; do
    sync_lnk_shortcut "\${source_file}" "profile-desktop"
  done < <(find "\${PROFILE_DESKTOP_DIR}" -type f -name '*.lnk' -print0 2>/dev/null)
fi

if [[ -d "\${PROFILE_START_MENU_DIR}" ]]; then
  while IFS= read -r -d '' source_file; do
    sync_lnk_shortcut "\${source_file}" "profile-start-menu"
  done < <(find "\${PROFILE_START_MENU_DIR}" -type f -name '*.lnk' -print0 2>/dev/null)
fi

while IFS= read -r -d '' existing_target; do
  if [[ -z "\${expected_targets[\${existing_target}]+x}" ]]; then
    rm -f "\${existing_target}"
  fi
done < <(find "\${desktop_dir}" -maxdepth 1 -type f -name "\${TARGET_PREFIX}*.desktop" -print0 2>/dev/null)
EOF

  chmod 0755 "${helper}"
}

write_wine_session_bootstrap_files() {
  local helper=/usr/local/libexec/etap-wine-session-bootstrap
  local autostart=/etc/xdg/autostart/etap-wine-session-bootstrap.desktop
  local quoted_prefix_name

  printf -v quoted_prefix_name '%q' "${WINE_PREFIX_NAME}"

  install -d -m 0755 /usr/local/libexec
  install -d -m 0755 /etc/xdg/autostart

  cat >"${helper}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

WINE_PREFIX_NAME=${quoted_prefix_name}
export WINEPREFIX="\${ETAP_WINE_PREFIX:-\${HOME}/\${WINE_PREFIX_NAME}}"
MARKER_FILE="\${WINEPREFIX}/.etap-wine-config"
LOCK_DIR="\${XDG_RUNTIME_DIR:-/tmp}/etap-wine-bootstrap.\$(id -u).lock"
LOG_DIR="\${XDG_STATE_HOME:-\${HOME}/.local/state}"
LOG_FILE="\${LOG_DIR}/etap-wine-bootstrap.log"

if [[ -f "\${MARKER_FILE}" ]]; then
  exit 0
fi

mkdir -p "\${LOG_DIR}"

if ! mkdir "\${LOCK_DIR}" 2>/dev/null; then
  exit 0
fi

cleanup() {
  rmdir "\${LOCK_DIR}" 2>/dev/null || true
}

trap cleanup EXIT

{
  printf '[%s] Wine otomatik hazirlama basladi. Kullanici: %s Prefix: %s\n' "\$(date '+%Y-%m-%d %H:%M:%S')" "\$(id -un)" "\${WINEPREFIX}"
  /usr/local/libexec/etap-wine-bootstrap
  /usr/local/libexec/etap-wine-sync-shortcuts
  printf '[%s] Wine otomatik hazirlama tamamlandi.\n' "\$(date '+%Y-%m-%d %H:%M:%S')"
} >>"\${LOG_FILE}" 2>&1 || true
EOF

  chmod 0755 "${helper}"

  cat >"${autostart}" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=ETAP Wine Otomatik Hazirlama
Comment=Yeni kullanicilar icin Wine ortamini ilk oturumda hazirlar
Exec=/usr/local/libexec/etap-wine-session-bootstrap
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=15
OnlyShowIn=X-Cinnamon;GNOME;XFCE;MATE;LXQt;LXDE;
EOF

  chmod 0644 "${autostart}"
}

create_wine_launchers() {
  local launcher=/usr/local/bin/etap-wine
  local winetricks_launcher=/usr/local/bin/etap-winetricks
  local compat_wine_launcher=/usr/local/bin/wine
  local compat_winetricks_launcher=/usr/local/bin/winetricks
  local quoted_prefix_name
  local system_wine_bin system_winetricks_bin

  printf -v quoted_prefix_name '%q' "${WINE_PREFIX_NAME}"
  system_wine_bin="$(resolve_system_command wine)"
  system_winetricks_bin="$(resolve_system_command winetricks)"

  cat >"${launcher}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export WINEARCH=win32
WINE_PREFIX_NAME=${quoted_prefix_name}
export WINEPREFIX="\${ETAP_WINE_PREFIX:-\${HOME}/\${WINE_PREFIX_NAME}}"
export WINEDEBUG='-all'
/usr/local/libexec/etap-wine-bootstrap
status=0
${system_wine_bin} "\$@" || status=\$?
/usr/local/libexec/etap-wine-sync-shortcuts >/dev/null 2>&1 || true
exit "\${status}"
EOF

  chmod 0755 "${launcher}"

  cat >"${winetricks_launcher}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export WINEARCH=win32
WINE_PREFIX_NAME=${quoted_prefix_name}
export WINEPREFIX="\${ETAP_WINE_PREFIX:-\${HOME}/\${WINE_PREFIX_NAME}}"
export WINEDEBUG='-all'
/usr/local/libexec/etap-wine-bootstrap
status=0
${system_winetricks_bin} "\$@" || status=\$?
/usr/local/libexec/etap-wine-sync-shortcuts >/dev/null 2>&1 || true
exit "\${status}"
EOF

  chmod 0755 "${winetricks_launcher}"

  cat >"${compat_wine_launcher}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec /usr/local/bin/etap-wine "\$@"
EOF

  chmod 0755 "${compat_wine_launcher}"

  cat >"${compat_winetricks_launcher}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec /usr/local/bin/etap-winetricks "\$@"
EOF

  chmod 0755 "${compat_winetricks_launcher}"
}

bootstrap_existing_wine_prefixes() {
  local username home_dir

  while IFS=: read -r username home_dir; do
    [[ -n "${username}" && -d "${home_dir}" ]] || continue
    log "${username} icin Wine ortami hazirlaniyor."
    if runuser -u "${username}" -- env HOME="${home_dir}" /usr/local/libexec/etap-wine-bootstrap; then
      log "${username} icin Wine ortami hazirlandi."
    else
      log "Uyari: ${username} icin Wine ortami hazirlanamadi. Kullanici daha sonra wine komutunu ilk calistirdiginda yeniden denenecek."
    fi
  done < <(list_home_users)
}

require_existing_user_home() {
  local username="$1"
  local home_dir=""

  user_exists "${username}" || fail "Kullanici bulunamadi: ${username}"
  home_dir="$(get_user_home "${username}")"
  [[ -n "${home_dir}" && -d "${home_dir}" ]] || fail "Kullanici ev dizini bulunamadi: ${username}"
  printf '%s\n' "${home_dir}"
}

prepare_wine_helpers_if_possible() {
  local system_wine_bin system_winetricks_bin

  if [[ -x /usr/local/libexec/etap-wine-bootstrap ]] && \
     [[ -x /usr/local/libexec/etap-wine-open-shortcut ]] && \
     [[ -x /usr/local/libexec/etap-wine-sync-shortcuts ]] && \
     [[ -x /usr/local/libexec/etap-wine-session-bootstrap ]] && \
     [[ -f /etc/xdg/autostart/etap-wine-session-bootstrap.desktop ]] && \
     [[ -x /usr/local/bin/etap-wine ]] && \
     [[ -x /usr/local/bin/etap-winetricks ]]; then
    return 0
  fi

  system_wine_bin="$(resolve_system_command_if_present wine)"
  system_winetricks_bin="$(resolve_system_command_if_present winetricks)"
  [[ -n "${system_wine_bin}" && -n "${system_winetricks_bin}" ]] || \
    fail "Wine yardimci baslaticilari olusturulamiyor; once Wine ve winetricks kurulu olmali."

  log "Wine yardimci baslaticilari eksikti; yeniden olusturuluyor."
  write_wine_bootstrap_script
  write_wine_shortcut_sync_script
  write_wine_session_bootstrap_files
  create_wine_launchers
}

resolve_wine_target_user() {
  local user_name=""

  if [[ -n "${WINE_TARGET_USER}" ]]; then
    user_exists "${WINE_TARGET_USER}" || fail "Wine hedef kullanicisi bulunamadi: ${WINE_TARGET_USER}"
    printf '%s\n' "${WINE_TARGET_USER}"
    return 0
  fi

  if find_active_graphical_session && [[ -n "${ACTIVE_GUI_USER}" ]]; then
    printf '%s\n' "${ACTIVE_GUI_USER}"
    return 0
  fi

  user_name="$(resolve_gui_user_from_environment || true)"
  if [[ -n "${user_name}" ]] && user_exists "${user_name}"; then
    printf '%s\n' "${user_name}"
    return 0
  fi

  if user_exists "${ETAPADMIN_USER}"; then
    printf '%s\n' "${ETAPADMIN_USER}"
    return 0
  fi

  fail "Wine icin hedef kullanici belirlenemedi. --wine-user kullanin."
}

bootstrap_wine_prefix_for_user() {
  local username="$1"
  local home_dir="$2"

  prepare_wine_helpers_if_possible
  log "${username} icin Wine prefix hazirlaniyor."
  runuser -u "${username}" -- env HOME="${home_dir}" /usr/local/libexec/etap-wine-bootstrap
}

remove_wine_prefix_for_user() {
  local username="$1"
  local home_dir="$2"
  local prefix_dir="${home_dir}/${WINE_PREFIX_NAME}"

  if [[ ! -e "${prefix_dir}" ]]; then
    log "${username} icin Wine prefix klasoru yok, atlaniyor: ${prefix_dir}"
    return 0
  fi

  rm -rf "${prefix_dir}"
  log "${username} icin Wine prefix klasoru silindi: ${prefix_dir}"
}

show_wine_versions() {
  local system_wine_bin system_winetricks_bin wine_version winetricks_version

  system_wine_bin="$(resolve_system_command_if_present wine)"
  system_winetricks_bin="$(resolve_system_command_if_present winetricks)"

  if [[ -n "${system_wine_bin}" && -x "${system_wine_bin}" ]]; then
    wine_version="$("${system_wine_bin}" --version 2>/dev/null || true)"
    log "Wine sistem komutu: ${wine_version:-surum okunamadi}"
  else
    log "Wine sistem komutu bulunamadi."
  fi

  if [[ -n "${system_winetricks_bin}" && -x "${system_winetricks_bin}" ]]; then
    winetricks_version="$("${system_winetricks_bin}" --version 2>/dev/null | head -n 1 || true)"
    log "Winetricks sistem komutu: ${winetricks_version:-surum okunamadi}"
  else
    log "Winetricks sistem komutu bulunamadi."
  fi

  for helper in /usr/local/libexec/etap-wine-bootstrap /usr/local/bin/etap-wine /usr/local/bin/etap-winetricks /usr/local/bin/wine /usr/local/bin/winetricks; do
    if [[ -x "${helper}" ]]; then
      log "Wine yardimcisi mevcut: ${helper}"
    else
      log "Wine yardimcisi bulunamadi: ${helper}"
    fi
  done
}

run_wine_verification_check() {
  local previous_enable_wine="${ENABLE_WINE}"
  ENABLE_WINE=1
  verify_wine_state post
  ENABLE_WINE="${previous_enable_wine}"
}

launch_winecfg_for_target_user() {
  local target_user home_dir env_args=()

  prepare_wine_helpers_if_possible
  find_active_graphical_session || fail "Aktif grafik oturumu bulunamadi. winecfg yalnizca grafik oturumunda acilabilir."

  target_user="${WINE_TARGET_USER:-${ACTIVE_GUI_USER}}"
  [[ -n "${target_user}" ]] || fail "winecfg icin hedef kullanici belirlenemedi."
  [[ "${target_user}" == "${ACTIVE_GUI_USER}" ]] || \
    fail "winecfg yalnizca aktif grafik oturumundaki kullanici icin acilabilir. Bulunan: ${ACTIVE_GUI_USER}, istenen: ${target_user}"

  home_dir="$(require_existing_user_home "${target_user}")"
  [[ -n "${ACTIVE_GUI_DISPLAY}" ]] && env_args+=("DISPLAY=${ACTIVE_GUI_DISPLAY}")
  [[ -n "${ACTIVE_GUI_XAUTHORITY}" ]] && env_args+=("XAUTHORITY=${ACTIVE_GUI_XAUTHORITY}")
  [[ -n "${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}" ]] && env_args+=("DBUS_SESSION_BUS_ADDRESS=${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}")
  [[ -n "${ACTIVE_GUI_XDG_RUNTIME_DIR}" ]] && env_args+=("XDG_RUNTIME_DIR=${ACTIVE_GUI_XDG_RUNTIME_DIR}")
  [[ -n "${ACTIVE_GUI_WAYLAND_DISPLAY}" ]] && env_args+=("WAYLAND_DISPLAY=${ACTIVE_GUI_WAYLAND_DISPLAY}")

  log "winecfg ${target_user} kullanicisi icin aciliyor."
  runuser -u "${target_user}" -- env \
    HOME="${home_dir}" \
    "${env_args[@]}" \
    /usr/local/bin/etap-wine winecfg
}

rebuild_wine_prefix_for_target_user() {
  local target_user home_dir

  target_user="$(resolve_wine_target_user)"
  home_dir="$(require_existing_user_home "${target_user}")"
  remove_wine_prefix_for_user "${target_user}" "${home_dir}"
  bootstrap_wine_prefix_for_user "${target_user}" "${home_dir}"
  log "${target_user} icin Wine prefix yeniden olusturuldu."
}

purge_selected_wine_prefixes() {
  local username home_dir

  if [[ -n "${WINE_TARGET_USER}" ]]; then
    home_dir="$(require_existing_user_home "${WINE_TARGET_USER}")"
    remove_wine_prefix_for_user "${WINE_TARGET_USER}" "${home_dir}"
    return 0
  fi

  while IFS=: read -r username home_dir; do
    [[ -n "${username}" && -d "${home_dir}" ]] || continue
    remove_wine_prefix_for_user "${username}" "${home_dir}"
  done < <(list_home_users)
}

remove_wine_launchers() {
  rm -f \
    /usr/local/libexec/etap-wine-bootstrap \
    /usr/local/libexec/etap-wine-open-shortcut \
    /usr/local/libexec/etap-wine-sync-shortcuts \
    /usr/local/libexec/etap-wine-session-bootstrap \
    /usr/local/bin/etap-wine \
    /usr/local/bin/etap-winetricks \
    /usr/local/bin/wine \
    /usr/local/bin/winetricks \
    /etc/xdg/autostart/etap-wine-session-bootstrap.desktop
  log "Wine yardimci baslaticilari kaldirildi."
}

remove_wine_packages() {
  local packages=()
  local package_name

  for package_name in wine wine64 wine32:i386 winetricks; do
    if package_installed "${package_name}"; then
      packages+=("${package_name}")
    fi
  done

  if ((${#packages[@]} == 0)); then
    log "Kaldirilacak Wine paketi bulunamadi."
    return 0
  fi

  log "Kaldirilacak Wine paketleri: ${packages[*]}"
  DEBIAN_FRONTEND=noninteractive apt-get purge -y "${packages[@]}"
  DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y
  DEBIAN_FRONTEND=noninteractive apt-get autoclean -y
}

remove_wine_installation() {
  remove_wine_packages
  remove_wine_launchers

  if [[ "${ACTION_MODE}" == "wine-remove-purge-prefixes" ]]; then
    purge_selected_wine_prefixes
  fi

  log "Wine kaldirma akisi tamamlandi."
}

run_wine_install_mode() {
  local previous_enable_wine="${ENABLE_WINE}"
  local previous_vulkan="${ENABLE_WINE_VULKAN_TRANSLATORS}"

  ENABLE_WINE=1
  run_step "Wine oncesi kontrolleri calistirma" verify_wine_state pre
  run_step "Wine ve winetricks kurulumunu yapma" install_and_configure_wine
  run_step "Wine sonu kontrolleri calistirma" verify_wine_state post
  log "Wine klasor adi: ${WINE_PREFIX_NAME}"
  log "Wine Windows surumu: ${WINE_WINDOWS_VERSION}"
  log "Baslaticilar: /usr/local/bin/etap-wine ve /usr/local/bin/etap-winetricks"
  log "Wine uygulama kisayollari masaustune senkronlanacak: /usr/local/libexec/etap-wine-sync-shortcuts"
  log "Yeni kullanicilarin ilk grafik oturumunda Wine otomatik hazirlanacak: /etc/xdg/autostart/etap-wine-session-bootstrap.desktop"

  ENABLE_WINE="${previous_enable_wine}"
  ENABLE_WINE_VULKAN_TRANSLATORS="${previous_vulkan}"
}

run_wine_maintenance_mode() {
  require_commands_for_wine_mode

  case "${ACTION_MODE}" in
    wine-install)
      run_wine_install_mode
      ;;
    wine-check)
      run_step "Wine durumunu kontrol etme" run_wine_verification_check
      ;;
    wine-version)
      run_step "Wine surum bilgisini gosterme" show_wine_versions
      ;;
    winecfg)
      run_step "Wine ayarlarini acma" launch_winecfg_for_target_user
      ;;
    wine-remove|wine-remove-purge-prefixes)
      run_step "Wine kurulumunu kaldirma" remove_wine_installation
      ;;
    wine-rebuild-prefix)
      run_step "Wine prefix klasorunu yeniden olusturma" rebuild_wine_prefix_for_target_user
      ;;
  esac
}

write_idle_shutdown_session_files() {
  local helper=/usr/local/libexec/etap-idle-session-monitor
  local autostart=/etc/xdg/autostart/etap-idle-session-monitor.desktop
  local xsession=/etc/X11/Xsession.d/91etap-idle-session-monitor
  local threshold_ms=$((IDLE_SHUTDOWN_MINUTES * 60 * 1000))

  install -d -m 0755 /usr/local/libexec
  install -d -m 0755 /etc/xdg/autostart /etc/X11/Xsession.d

  cat >"${helper}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD_MS=${threshold_ms}
USER_ID="\$(id -u)"
USER_NAME="\$(id -un)"
STATE_FILE=""
LOCK_DIR=""

if [[ -n "\${XDG_RUNTIME_DIR:-}" && -d "\${XDG_RUNTIME_DIR}" ]]; then
  STATE_FILE="\${XDG_RUNTIME_DIR}/etap-idle-state.env"
  LOCK_DIR="\${XDG_RUNTIME_DIR}/etap-idle-monitor.lock"
else
  STATE_FILE="/tmp/etap-idle-state.\${USER_ID}.env"
  LOCK_DIR="/tmp/etap-idle-monitor.\${USER_ID}.lock"
fi

[[ -n "\${DISPLAY:-}" ]] || exit 0
command -v xprintidle >/dev/null 2>&1 || exit 0

if ! mkdir "\${LOCK_DIR}" 2>/dev/null; then
  exit 0
fi

cleanup() {
  rm -f "\${STATE_FILE}" "\${STATE_FILE}.tmp"
  rmdir "\${LOCK_DIR}" 2>/dev/null || true
}

write_state() {
  local idle_ms now tmp_file

  idle_ms="\$(xprintidle 2>/dev/null || true)"
  [[ "\${idle_ms}" =~ ^[0-9]+$ ]] || return 0

  now="\$(date +%s)"
  tmp_file="\${STATE_FILE}.tmp"
  umask 022
  cat >"\${tmp_file}" <<STATE
USER_NAME=\${USER_NAME}
USER_ID=\${USER_ID}
DISPLAY=\${DISPLAY}
THRESHOLD_MS=\${THRESHOLD_MS}
LAST_IDLE_MS=\${idle_ms}
LAST_SEEN_EPOCH=\${now}
STATE
  mv -f "\${tmp_file}" "\${STATE_FILE}"
}

trap cleanup EXIT INT TERM

write_state

while true; do
  sleep 60
  write_state
done
EOF

  chmod 0755 "${helper}"

  cat >"${xsession}" <<'EOF'
#!/bin/sh
if [ -x /usr/local/libexec/etap-idle-session-monitor ]; then
  /usr/local/libexec/etap-idle-session-monitor >/dev/null 2>&1 &
fi
EOF

  chmod 0755 "${xsession}"

  cat >"${autostart}" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=ETAP Bosda Kapanma Izleyicisi
Comment=Bosda kalma suresini grafik oturumunda takip eder
Exec=/usr/local/libexec/etap-idle-session-monitor
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=20
OnlyShowIn=X-Cinnamon;GNOME;XFCE;MATE;LXQt;LXDE;
EOF

  chmod 0644 "${autostart}"
}

write_idle_shutdown_checker() {
  local checker=/usr/local/sbin/etap-idle-shutdown-check
  local threshold_ms=$((IDLE_SHUTDOWN_MINUTES * 60 * 1000))

  cat >"${checker}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD_MS=${threshold_ms}
STATE_TIMEOUT_SECONDS=180
AKTIF_OTURUM_GORULDU=0

read_state_field() {
  local state_file="\$1"
  local key="\$2"

  awk -F= -v key="\${key}" '
    \$1 == key {
      print substr(\$0, index(\$0, "=") + 1)
      exit
    }
  ' "\${state_file}" 2>/dev/null || true
}

collect_state_files() {
  local candidate

  for candidate in /run/user/*/etap-idle-state.env /tmp/etap-idle-state.*.env; do
    [[ -f "\${candidate}" ]] || continue
    printf '%s\n' "\${candidate}"
  done
}

now_epoch="\$(date +%s)"

while IFS= read -r state_file; do
  [[ -n "\${state_file}" ]] || continue

  last_seen="\$(read_state_field "\${state_file}" LAST_SEEN_EPOCH)"
  idle_ms="\$(read_state_field "\${state_file}" LAST_IDLE_MS)"
  user_name="\$(read_state_field "\${state_file}" USER_NAME)"

  [[ "\${last_seen}" =~ ^[0-9]+$ ]] || continue
  [[ "\${idle_ms}" =~ ^[0-9]+$ ]] || continue

  if (( now_epoch - last_seen > STATE_TIMEOUT_SECONDS )); then
    continue
  fi

  AKTIF_OTURUM_GORULDU=1
  if (( idle_ms < THRESHOLD_MS )); then
    exit 0
  fi
done < <(collect_state_files)

if (( AKTIF_OTURUM_GORULDU == 1 )); then
  logger -t etap-idle-shutdown "${IDLE_SHUTDOWN_MINUTES} dakika bosta kalindigi icin kapatma baslatildi"
  systemctl poweroff
fi
EOF

  chmod 0755 "${checker}"
}

start_idle_shutdown_monitor_for_active_session() {
  local helper=/usr/local/libexec/etap-idle-session-monitor
  local env_args=()

  [[ -x "${helper}" ]] || return 0

  if ! command -v xprintidle >/dev/null 2>&1; then
    log "xprintidle su an bulunamadigi icin bosda kapanma izleyicisi bu oturumda hemen baslatilamadi."
    return 0
  fi

  if ! find_active_graphical_session; then
    log "Aktif grafik oturumu bulunamadigi icin bosda kapanma izleyicisi simdi baslatilamadi. Sonraki oturumda otomatik devreye girecek."
    return 0
  fi

  [[ -n "${ACTIVE_GUI_USER}" ]] || return 0
  [[ -n "${ACTIVE_GUI_DISPLAY}" ]] && env_args+=("DISPLAY=${ACTIVE_GUI_DISPLAY}")
  [[ -n "${ACTIVE_GUI_XAUTHORITY}" ]] && env_args+=("XAUTHORITY=${ACTIVE_GUI_XAUTHORITY}")
  [[ -n "${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}" ]] && env_args+=("DBUS_SESSION_BUS_ADDRESS=${ACTIVE_GUI_DBUS_SESSION_BUS_ADDRESS}")
  [[ -n "${ACTIVE_GUI_XDG_RUNTIME_DIR}" ]] && env_args+=("XDG_RUNTIME_DIR=${ACTIVE_GUI_XDG_RUNTIME_DIR}")
  [[ -n "${ACTIVE_GUI_WAYLAND_DISPLAY}" ]] && env_args+=("WAYLAND_DISPLAY=${ACTIVE_GUI_WAYLAND_DISPLAY}")

  log "Bosda kapanma izleyicisi aktif oturum icin baslatiliyor: ${ACTIVE_GUI_USER}"
  runuser -u "${ACTIVE_GUI_USER}" -- env \
    "${env_args[@]}" \
    "${helper}" >/dev/null 2>&1 &
}

disable_and_remove_unit() {
  local unit_name="$1"
  local unit_path="$2"

  systemctl disable --now "${unit_name}" >/dev/null 2>&1 || true
  rm -f "${unit_path}"
}

configure_power_management() {
  local idle_service=/etc/systemd/system/etap-idle-shutdown.service
  local idle_timer=/etc/systemd/system/etap-idle-shutdown.timer
  local scheduled_service=/etc/systemd/system/etap-scheduled-poweroff.service
  local scheduled_timer=/etc/systemd/system/etap-scheduled-poweroff.timer
  local idle_checker=/usr/local/sbin/etap-idle-shutdown-check
  local idle_session_helper=/usr/local/libexec/etap-idle-session-monitor
  local idle_session_autostart=/etc/xdg/autostart/etap-idle-session-monitor.desktop
  local idle_session_xsession=/etc/X11/Xsession.d/91etap-idle-session-monitor

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    write_idle_shutdown_session_files
    write_idle_shutdown_checker

    cat >"${idle_service}" <<EOF
[Unit]
Description=ETAP tahtasi bosta kalinca kapatma kontrolu

[Service]
Type=oneshot
ExecStart=${idle_checker}
EOF

    cat >"${idle_timer}" <<EOF
[Unit]
Description=ETAP bosta kapanma kontrolunu her dakika calistir

[Timer]
OnBootSec=5min
OnUnitActiveSec=1min
Unit=etap-idle-shutdown.service

[Install]
WantedBy=timers.target
EOF
  else
    disable_and_remove_unit etap-idle-shutdown.timer "${idle_timer}"
    pkill -f '/usr/local/libexec/etap-idle-session-monitor' >/dev/null 2>&1 || true
    rm -f \
      "${idle_service}" \
      "${idle_checker}" \
      "${idle_session_helper}" \
      "${idle_session_autostart}" \
      "${idle_session_xsession}"
  fi

  if is_enabled "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    cat >"${scheduled_service}" <<EOF
[Unit]
Description=ETAP tahtasini planli saatinde kapat

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl poweroff
EOF

    cat >"${scheduled_timer}" <<EOF
[Unit]
Description=ETAP tahtasini her gun ${SCHEDULED_SHUTDOWN_TIME} saatinde kapat

[Timer]
OnCalendar=*-*-* ${SCHEDULED_SHUTDOWN_TIME}:00
Persistent=true
AccuracySec=1min
Unit=etap-scheduled-poweroff.service

[Install]
WantedBy=timers.target
EOF
  else
    disable_and_remove_unit etap-scheduled-poweroff.timer "${scheduled_timer}"
    rm -f "${scheduled_service}"
  fi

  log "Guc yonetimi birimleri guncelleniyor."
  systemctl daemon-reload

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    systemctl enable --now etap-idle-shutdown.timer
  fi

  if is_enabled "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    systemctl enable --now etap-scheduled-poweroff.timer
  fi
}

verify_removed_user_state() {
  local username="$1"
  local removal_enabled="$2"
  local phase="${3:-post}"

  if [[ "${phase}" == "pre" ]]; then
    if id "${username}" >/dev/null 2>&1; then
      if is_enabled "${removal_enabled}"; then
        postcheck_info "${username} kullanicisi mevcut; kurulumda silinmesi planlaniyor."
      else
        postcheck_info "${username} kullanicisi mevcut; silme adimi kapali."
      fi
    else
      postcheck_info "${username} kullanicisi sistemde bulunmuyor."
    fi
    return 0
  fi

  if id "${username}" >/dev/null 2>&1; then
    if is_enabled "${removal_enabled}"; then
      postcheck_warn "${username} kullanicisi hala mevcut."
    else
      postcheck_info "${username} kullanicisi mevcut; silme adimi kapaliydi."
    fi
  else
    if is_enabled "${removal_enabled}"; then
      postcheck_ok "${username} kullanicisi sistemde bulunmuyor."
    else
      postcheck_info "${username} kullanicisi zaten mevcut degil."
    fi
  fi
}

verify_eta_touchdrv_state() {
  local phase="${1:-post}"
  local installed_version candidate_version service_state

  if ! command -v apt-cache >/dev/null 2>&1 || ! command -v systemctl >/dev/null 2>&1; then
    postcheck_info "eta-touchdrv kontrolu icin gerekli komutlar bulunamadigi icin bu kontrol atlandi."
    return 0
  fi

  if ! package_installed eta-touchdrv; then
    if [[ "${phase}" == "pre" ]]; then
      if is_enabled "${ENABLE_ETA_TOUCHDRV}"; then
        postcheck_info "eta-touchdrv paketi su an kurulu degil; kurulum bu adimi uygulayacak."
      else
        postcheck_info "eta-touchdrv adimi kapali ve paket kurulu degil."
      fi
    else
      if is_enabled "${ENABLE_ETA_TOUCHDRV}"; then
        postcheck_warn "eta-touchdrv paketi kurulu gorunmuyor."
        postcheck_eta_touchdrv_reinstall_hint
      else
        postcheck_info "eta-touchdrv adimi kapaliydi; paket kurulu degil."
      fi
    fi
    return 0
  fi

  installed_version="$(dpkg-query -W -f='${Version}' eta-touchdrv 2>/dev/null || true)"
  candidate_version="$(apt-cache policy eta-touchdrv 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
  service_state="$(systemctl is-active eta-touchdrv 2>/dev/null || true)"

  if [[ -n "${installed_version}" ]]; then
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "eta-touchdrv mevcut surumu: ${installed_version}"
    elif [[ "${installed_version}" == "${ETA_TOUCHDRV_TARGET_VERSION}" ]]; then
      postcheck_ok "eta-touchdrv surumu beklenen degerde: ${installed_version}"
    else
      postcheck_warn "eta-touchdrv surumu ${installed_version}; beklenen surum ${ETA_TOUCHDRV_TARGET_VERSION}"
      postcheck_eta_touchdrv_reinstall_hint
    fi
  else
    postcheck_warn "eta-touchdrv kurulu ama surum bilgisi okunamadi."
    postcheck_eta_touchdrv_reinstall_hint
  fi

  if [[ -n "${candidate_version}" && "${candidate_version}" != "(none)" ]]; then
    postcheck_info "eta-touchdrv depo adayi: ${candidate_version}"
  fi

  if [[ "${service_state}" == "active" ]]; then
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "eta-touchdrv servisi aktif."
    else
      postcheck_ok "eta-touchdrv servisi aktif."
    fi
  else
    postcheck_warn "eta-touchdrv servisi aktif degil. Durum: ${service_state:-bilinmiyor}"
    postcheck_eta_touchdrv_reinstall_hint
  fi
}

verify_idle_shutdown_state() {
  local phase="${1:-post}"
  local checker=/usr/local/sbin/etap-idle-shutdown-check
  local timer_unit=etap-idle-shutdown.timer
  local timer_path=/etc/systemd/system/etap-idle-shutdown.timer
  local session_helper=/usr/local/libexec/etap-idle-session-monitor
  local session_autostart=/etc/xdg/autostart/etap-idle-session-monitor.desktop
  local session_xsession=/etc/X11/Xsession.d/91etap-idle-session-monitor
  local state_file=""
  local last_seen=""
  local last_idle=""
  local now_epoch=""
  local expected_threshold actual_threshold enabled_state active_state

  expected_threshold=$((IDLE_SHUTDOWN_MINUTES * 60 * 1000))

  if ! command -v systemctl >/dev/null 2>&1; then
    postcheck_info "Bosda kapanma kontrolu icin systemctl bulunamadi."
    return 0
  fi

  if ! is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    if [[ ! -e "${checker}" && ! -e "${timer_path}" ]]; then
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "Bosda kapanma adimi kapali."
      else
        postcheck_info "Bosda kapanma adimi kapali."
      fi
    else
      postcheck_warn "Bosda kapanma kapali gorunuyor ama ilgili dosyalar sistemde duruyor."
    fi
    return 0
  fi

  if [[ ! -x "${checker}" ]]; then
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "Bosda kapanma kontrol betigi su an yok; kurulum olusturacak."
    else
      postcheck_warn "Bosda kapanma kontrol betigi bulunamadi: ${checker}"
    fi
  else
    actual_threshold="$(awk -F= '/^THRESHOLD_MS=/{print $2; exit}' "${checker}" 2>/dev/null || true)"
    if [[ "${phase}" == "pre" ]]; then
      if [[ "${actual_threshold}" == "${expected_threshold}" ]]; then
        postcheck_info "Bosda kapanma suresi su an ${IDLE_SHUTDOWN_MINUTES} dakika ile uyumlu."
      else
        postcheck_info "Bosda kapanma suresi su an farkli veya ayarsiz. Beklenen ${expected_threshold} ms, bulunan ${actual_threshold:-yok}"
      fi
    elif [[ "${actual_threshold}" == "${expected_threshold}" ]]; then
      postcheck_ok "Bosda kapanma suresi ${IDLE_SHUTDOWN_MINUTES} dakika olarak ayarli."
    else
      postcheck_warn "Bosda kapanma suresi beklenenden farkli. Beklenen ${expected_threshold} ms, bulunan ${actual_threshold:-yok}"
    fi
  fi

  if [[ ! -x "${session_helper}" || ! -f "${session_autostart}" || ! -x "${session_xsession}" ]]; then
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "Bosda kapanma oturum izleyicisi su an tam degil; kurulum olusturacak."
    else
      postcheck_warn "Bosda kapanma oturum izleyicisi dosyalari eksik."
    fi
  elif [[ "${phase}" == "pre" ]]; then
    postcheck_info "Bosda kapanma oturum izleyicisi dosyalari hazir."
  else
    postcheck_ok "Bosda kapanma oturum izleyicisi dosyalari hazir."
  fi

  for state_file in /run/user/*/etap-idle-state.env /tmp/etap-idle-state.*.env; do
    [[ -f "${state_file}" ]] || continue
    break
  done

  if [[ -f "${state_file}" ]]; then
    last_seen="$(awk -F= '/^LAST_SEEN_EPOCH=/{print $2; exit}' "${state_file}" 2>/dev/null || true)"
    last_idle="$(awk -F= '/^LAST_IDLE_MS=/{print $2; exit}' "${state_file}" 2>/dev/null || true)"
    now_epoch="$(date +%s)"

    if [[ "${last_seen}" =~ ^[0-9]+$ ]] && [[ "${last_idle}" =~ ^[0-9]+$ ]] && (( now_epoch - last_seen <= 180 )); then
      postcheck_info "Bosda kapanma oturum izleyicisi veri uretiyor. Son bos kalma suresi: ${last_idle} ms"
    else
      postcheck_info "Bosda kapanma oturum izleyicisi dosyasi bulundu ama veri henuz taze gorunmuyor."
    fi
  elif [[ "${phase}" == "pre" ]]; then
    postcheck_info "Bosda kapanma oturum verisi henuz olusmamis; kurulum sonrasi veya sonraki oturumda gorunur."
  else
    postcheck_info "Bosda kapanma oturum verisi henuz gorulmedi. Gerekirse oturumu kapatip yeniden acin."
  fi

  enabled_state="$(systemctl is-enabled "${timer_unit}" 2>/dev/null || true)"
  active_state="$(systemctl is-active "${timer_unit}" 2>/dev/null || true)"
  if [[ "${phase}" == "pre" ]]; then
    postcheck_info "${timer_unit} mevcut durumu: enabled=${enabled_state:-bilinmiyor}, active=${active_state:-bilinmiyor}"
  elif [[ "${enabled_state}" == "enabled" && "${active_state}" == "active" ]]; then
    postcheck_ok "${timer_unit} etkin ve calisiyor."
  else
    postcheck_warn "${timer_unit} beklenen durumda degil. enabled=${enabled_state:-bilinmiyor}, active=${active_state:-bilinmiyor}"
  fi
}

verify_scheduled_shutdown_state() {
  local phase="${1:-post}"
  local timer_unit=etap-scheduled-poweroff.timer
  local timer_path=/etc/systemd/system/etap-scheduled-poweroff.timer
  local expected_calendar enabled_state active_state

  if ! command -v systemctl >/dev/null 2>&1; then
    postcheck_info "Planli kapanma kontrolu icin systemctl bulunamadi."
    return 0
  fi

  if ! is_enabled "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    if [[ ! -e "${timer_path}" ]]; then
      postcheck_info "Planli kapanma adimi kapali."
    else
      postcheck_warn "Planli kapanma kapali gorunuyor ama timer dosyasi sistemde duruyor."
    fi
    return 0
  fi

  expected_calendar="OnCalendar=*-*-* ${SCHEDULED_SHUTDOWN_TIME}:00"
  if [[ "${phase}" == "pre" ]]; then
    if [[ -f "${timer_path}" ]] && grep -Fxq "${expected_calendar}" "${timer_path}"; then
      postcheck_info "Planli kapanma saati su an ${SCHEDULED_SHUTDOWN_TIME} ile uyumlu."
    else
      postcheck_info "Planli kapanma saati su an farkli veya ayarsiz. Hedef saat: ${SCHEDULED_SHUTDOWN_TIME}"
    fi
  elif [[ -f "${timer_path}" ]] && grep -Fxq "${expected_calendar}" "${timer_path}"; then
    postcheck_ok "Planli kapanma saati ${SCHEDULED_SHUTDOWN_TIME} olarak kayitli."
  else
    postcheck_warn "Planli kapanma timer dosyasinda beklenen saat bulunamadi: ${SCHEDULED_SHUTDOWN_TIME}"
  fi

  enabled_state="$(systemctl is-enabled "${timer_unit}" 2>/dev/null || true)"
  active_state="$(systemctl is-active "${timer_unit}" 2>/dev/null || true)"
  if [[ "${phase}" == "pre" ]]; then
    postcheck_info "${timer_unit} mevcut durumu: enabled=${enabled_state:-bilinmiyor}, active=${active_state:-bilinmiyor}"
  elif [[ "${enabled_state}" == "enabled" && "${active_state}" == "active" ]]; then
    postcheck_ok "${timer_unit} etkin ve calisiyor."
  else
    postcheck_warn "${timer_unit} beklenen durumda degil. enabled=${enabled_state:-bilinmiyor}, active=${active_state:-bilinmiyor}"
  fi
}

verify_wine_state() {
  local phase="${1:-post}"
  local wine_version winetricks_version bootstrap marker_file username home_dir
  local system_wine_bin system_winetricks_bin font_package
  local user_count=0

  if ! is_enabled "${ENABLE_WINE}"; then
    postcheck_info "Wine adimi kapali."
    return 0
  fi

  system_wine_bin="$(resolve_system_command_if_present wine)"
  system_winetricks_bin="$(resolve_system_command_if_present winetricks)"

  if [[ -x "${system_wine_bin}" ]]; then
    wine_version="$("${system_wine_bin}" --version 2>/dev/null || true)"
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "Wine sistem komutu mevcut: ${wine_version:-surum okunamadi}"
    else
      postcheck_ok "Wine sistem komutu hazir: ${wine_version:-surum okunamadi}"
    fi
  else
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "wine komutu su an yok; kurulum bu adimi uygulayacak."
    else
      postcheck_warn "wine komutu bulunamadi."
    fi
  fi

  if [[ -x "${system_winetricks_bin}" ]]; then
    winetricks_version="$("${system_winetricks_bin}" --version 2>/dev/null | head -n 1 || true)"
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "winetricks sistem komutu mevcut: ${winetricks_version:-surum okunamadi}"
    else
      postcheck_ok "winetricks sistem komutu hazir: ${winetricks_version:-surum okunamadi}"
    fi
  else
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "winetricks komutu su an yok; kurulum bu adimi uygulayacak."
    else
      postcheck_warn "winetricks komutu bulunamadi."
    fi
  fi

  if command -v xvfb-run >/dev/null 2>&1; then
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "xvfb-run komutu mevcut."
    else
      postcheck_ok "xvfb-run komutu hazir."
    fi
  else
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "xvfb-run komutu su an yok; Wine kurulumu bu araci yukleyecek."
    else
      postcheck_warn "xvfb-run komutu bulunamadi. xvfb paketi eksik olabilir."
    fi
  fi

  if command -v xauth >/dev/null 2>&1; then
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "xauth komutu mevcut."
    else
      postcheck_ok "xauth komutu hazir."
    fi
  else
    if [[ "${phase}" == "pre" ]]; then
      postcheck_info "xauth komutu su an yok; Wine kurulumu bu araci yukleyecek."
    else
      postcheck_warn "xauth komutu bulunamadi. xauth paketi eksik olabilir."
    fi
  fi

  for font_package in fonts-wine fonts-liberation2 fonts-dejavu-core; do
    if package_installed "${font_package}"; then
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "Wine temel font paketi mevcut: ${font_package}"
      else
        postcheck_ok "Wine temel font paketi hazir: ${font_package}"
      fi
    else
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "Wine temel font paketi su an yok; kurulum bu paketi yukleyecek: ${font_package}"
      else
        postcheck_warn "Wine temel font paketi bulunamadi: ${font_package}"
      fi
    fi
  done

  for bootstrap in \
    /usr/local/libexec/etap-wine-bootstrap \
    /usr/local/libexec/etap-wine-open-shortcut \
    /usr/local/libexec/etap-wine-sync-shortcuts \
    /usr/local/libexec/etap-wine-session-bootstrap \
    /etc/xdg/autostart/etap-wine-session-bootstrap.desktop \
    /usr/local/bin/etap-wine \
    /usr/local/bin/etap-winetricks \
    /usr/local/bin/wine \
    /usr/local/bin/winetricks; do
    if [[ ( "${bootstrap}" == *.desktop && -f "${bootstrap}" ) || -x "${bootstrap}" ]]; then
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "Wine baslaticisi mevcut: ${bootstrap}"
      else
        postcheck_ok "Wine baslaticisi hazir: ${bootstrap}"
      fi
    else
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "Wine baslaticisi su an hazir degil: ${bootstrap}"
      else
        postcheck_warn "Wine baslaticisi eksik veya calistirilabilir degil: ${bootstrap}"
      fi
    fi
  done

  while IFS=: read -r username home_dir; do
    [[ -n "${username}" && -d "${home_dir}" ]] || continue
    user_count=$((user_count + 1))
    marker_file="${home_dir}/${WINE_PREFIX_NAME}/.etap-wine-config"
    if [[ -f "${marker_file}" ]]; then
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "${username} icin Wine prefix mevcut: ${marker_file}"
      else
        postcheck_ok "${username} icin Wine prefix hazir: ${marker_file}"
      fi
    else
      if [[ "${phase}" == "pre" ]]; then
        postcheck_info "${username} icin Wine prefix henuz hazir degil: ${marker_file}"
      else
        postcheck_warn "${username} icin Wine prefix isareti bulunamadi: ${marker_file}"
      fi
    fi
  done < <(list_home_users)

  if (( user_count == 0 )); then
    postcheck_info "Wine prefix kontrolu icin /home altinda etkin kullanici bulunamadi."
  fi
}

run_pre_install_checks() {
  CHECK_WARNINGS=0
  log "Kurulum oncesi kontrolleri basliyor."

  verify_removed_user_state ogrenci "${ENABLE_REMOVE_OGRENCI}" pre
  verify_removed_user_state ogretmen "${ENABLE_REMOVE_OGRETMEN}" pre
  verify_eta_touchdrv_state pre
  verify_idle_shutdown_state pre
  verify_scheduled_shutdown_state pre
  verify_wine_state pre

  if (( CHECK_WARNINGS > 0 )); then
    log "Kurulum oncesi kontrolleri ${CHECK_WARNINGS} uyari ile tamamlandi."
  else
    log "Kurulum oncesi kontrolleri tamamlandi."
  fi
}

run_post_install_checks() {
  CHECK_WARNINGS=0
  log "Kurulum sonu kontrolleri basliyor."

  verify_removed_user_state ogrenci "${ENABLE_REMOVE_OGRENCI}" post
  verify_removed_user_state ogretmen "${ENABLE_REMOVE_OGRETMEN}" post
  verify_eta_touchdrv_state post
  verify_idle_shutdown_state post
  verify_scheduled_shutdown_state post
  verify_wine_state post

  if (( CHECK_WARNINGS > 0 )); then
    log "Kurulum sonu kontrolleri ${CHECK_WARNINGS} uyari ile tamamlandi."
  else
    log "Kurulum sonu kontrollerinin tamami basarili."
  fi
}

install_and_configure_wine() {
  ensure_i386_architecture
  install_packages_if_missing \
    wine \
    wine64 \
    wine32:i386 \
    winetricks \
    cabextract \
    p7zip-full \
    fontconfig \
    fonts-wine \
    fonts-liberation2 \
    fonts-dejavu-core \
    mono-complete \
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-dri:i386 \
    libasound2-plugins:i386 \
    libpulse0:i386 \
    xvfb \
    xauth

  ensure_wine_headless_runtime_tools

  if is_enabled "${ENABLE_WINE_VULKAN_TRANSLATORS}"; then
    install_packages_if_missing \
      mesa-vulkan-drivers \
      mesa-vulkan-drivers:i386 \
      vulkan-tools
  fi

  log "Ortak Wine baslaticilari kuruluyor."
  write_wine_bootstrap_script
  write_wine_shortcut_sync_script
  write_wine_session_bootstrap_files
  create_wine_launchers
  bootstrap_existing_wine_prefixes
}

install_deferred_runtime_packages() {
  local packages=()

  packages+=(zenity)

  if is_enabled "${ENABLE_DISABLE_SCREENSAVER}"; then
    packages+=(x11-xserver-utils)
  fi

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    packages+=(xprintidle)
  fi

  if is_enabled "${ENABLE_OPEN_ETA_KAYIT}"; then
    packages+=(python3-pyatspi)
  fi

  if ((${#packages[@]})); then
    log "Paket indirme ve kurulum adimlari basliyor. Bu asama zaman alabilir."
    install_packages_if_missing "${packages[@]}"
  fi
}

require_commands_for_selected_steps() {
  local need_apt=0

  if is_enabled "${ENABLE_REMOVE_OGRENCI}" || is_enabled "${ENABLE_REMOVE_OGRETMEN}"; then
    require_command id
    require_command userdel
    require_command loginctl
    require_command pkill
  fi

  if is_enabled "${ENABLE_HOSTNAME_CHANGE}"; then
    require_command hostnamectl
  fi

  if is_enabled "${ENABLE_EAG_CLIENT}"; then
    require_command python3
  fi

  if is_enabled "${ENABLE_PACKAGE_UPGRADE}"; then
    require_command apt-mark
    need_apt=1
  fi

  if is_enabled "${ENABLE_ETA_TOUCHDRV}"; then
    require_command apt-cache
    require_command systemctl
  fi

  if is_enabled "${ENABLE_DISABLE_SCREENSAVER}"; then
    require_command install
  fi

  if is_enabled "${ENABLE_ETAPADMIN_PASSWORD}"; then
    require_command chpasswd
    require_command passwd
    require_command usermod
    require_command openssl
    require_command python3
  fi

  if is_enabled "${ENABLE_WINE}" || is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    require_command runuser
  fi

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    require_command getent
    require_command id
  fi

  if is_enabled "${ENABLE_OPEN_ETA_KAYIT}"; then
    require_command install
    require_command runuser
    require_command python3
    require_command dpkg-query
    need_apt=1
  fi

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}" || is_enabled "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    require_command systemctl
  fi

  if is_enabled "${ENABLE_EAG_CLIENT}" || \
     is_enabled "${ENABLE_PACKAGE_UPGRADE}" || \
     is_enabled "${ENABLE_ETA_QR_LOGIN}" || \
     is_enabled "${ENABLE_ETA_TOUCHDRV}" || \
     is_enabled "${ENABLE_DISABLE_SCREENSAVER}" || \
     is_enabled "${ENABLE_WINE}" || \
     is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    need_apt=1
  fi

  if ((need_apt)); then
    require_command apt-get
    require_command dpkg
    require_command dpkg-query
  fi

  if [[ ! -x "${SCRIPT_DIR}/setup_etap23_launcher.sh" ]]; then
    require_command install
  fi
}

require_commands_for_touchdrv_mode() {
  require_command apt-cache
  require_command apt-get
  require_command awk
  require_command dpkg
  require_command dpkg-query
  require_command systemctl
}

require_commands_for_touch_calibration_mode() {
  require_command awk
  require_command python3

  case "${ACTION_MODE}" in
    touch-calibration-start)
      require_command apt-get
      require_command dpkg-query
      require_command install
      require_command rm
      require_command runuser
      ;;
    touch-calibration-status)
      ;;
    touch-calibration-reset)
      require_command install
      require_command rm
      require_command runuser
      ;;
  esac
}

require_commands_for_eta_kayit_mode() {
  require_command dpkg
  require_command apt-get
  require_command dpkg-query
  require_command rm
}

require_commands_for_wine_mode() {
  require_command dpkg-query

  case "${ACTION_MODE}" in
    wine-check|wine-version)
      ;;
    wine-install)
      require_command apt-get
      require_command dpkg
      require_command runuser
      require_command install
      ;;
    winecfg)
      require_command getent
      require_command id
      require_command runuser
      ;;
    wine-remove|wine-remove-purge-prefixes)
      require_command apt-get
      require_command getent
      require_command rm
      ;;
    wine-rebuild-prefix)
      require_command getent
      require_command rm
      require_command runuser
      ;;
  esac
}

install_launcher_dependencies() {
  if is_enabled "${ENABLE_OPEN_ETA_KAYIT}"; then
    write_eta_kayit_register_helper
  fi
}

main() {
  parse_args "$@"
  require_root
  assert_supported_os
  validate_settings
  disable_legacy_etap_deneysel_repo_entries || true

  if action_mode_is_touchdrv; then
    run_touchdrv_maintenance_mode
    return
  fi

  if action_mode_is_touch_calibration; then
    run_touch_calibration_mode
    return
  fi

  if action_mode_is_wine_maintenance; then
    run_wine_maintenance_mode
    return
  fi

  if action_mode_is_eta_kayit_repair; then
    run_eta_kayit_repair_mode
    return
  fi

  if ! is_enabled "${ENABLE_WINE}"; then
    ENABLE_WINE_VULKAN_TRANSLATORS=0
  fi

  configure_interactive_choices
  prepare_board_name
  resolve_eta_kayit_sinif
  ensure_etapadmin_password_step_has_value
  require_commands_for_selected_steps
  run_step "kurulum oncesi kontrolleri calistirma" run_pre_install_checks

  if is_enabled "${ENABLE_REMOVE_OGRENCI}"; then
    run_step "ogrenci kullanicisini silme" remove_user_if_present ogrenci
  fi

  if is_enabled "${ENABLE_REMOVE_OGRETMEN}"; then
    run_step "ogretmen kullanicisini silme" remove_user_if_present ogretmen
  fi

  if is_enabled "${ENABLE_HOSTNAME_CHANGE}"; then
    run_step "tahta adini degistirme" set_board_hostname
  fi

  run_step "ekran koruyucu ayarlarini uygulama" configure_screensaver_policy

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}" || is_enabled "${ENABLE_SCHEDULED_SHUTDOWN}"; then
    run_step "guc yonetimi ayarlarini uygulama" configure_power_management
  else
    log "Otomatik kapanma secenekleri kapali, guc yonetimi birimleri kaldiriliyor."
    if command -v systemctl >/dev/null 2>&1; then
      disable_and_remove_unit etap-idle-shutdown.timer /etc/systemd/system/etap-idle-shutdown.timer
      disable_and_remove_unit etap-scheduled-poweroff.timer /etc/systemd/system/etap-scheduled-poweroff.timer
      pkill -f '/usr/local/libexec/etap-idle-session-monitor' >/dev/null 2>&1 || true
      rm -f /etc/systemd/system/etap-idle-shutdown.service
      rm -f /etc/systemd/system/etap-scheduled-poweroff.service
      rm -f /usr/local/sbin/etap-idle-shutdown-check
      rm -f /usr/local/libexec/etap-idle-session-monitor
      rm -f /etc/xdg/autostart/etap-idle-session-monitor.desktop
      rm -f /etc/X11/Xsession.d/91etap-idle-session-monitor
      systemctl daemon-reload || true
    fi
  fi

  run_step "yardimci dosyalari hazirlama" install_launcher_dependencies
  run_step "gerekli paket onkosullarini kurma" install_deferred_runtime_packages

  if is_enabled "${ENABLE_PACKAGE_UPGRADE}"; then
    run_step "kurulu paketleri guncelleme" upgrade_installed_packages
  fi

  if is_enabled "${ENABLE_IDLE_SHUTDOWN}"; then
    run_step "bosda kapanma oturum izleyicisini baslatma" start_idle_shutdown_monitor_for_active_session
  fi

  if is_enabled "${ENABLE_EAG_CLIENT}"; then
    run_step "e-ag-client paketini kurma" install_eag_client
  fi

  if is_enabled "${ENABLE_ETA_QR_LOGIN}"; then
    run_step "eta-qr-login paketini kurma" install_eta_qr_login_if_needed
  fi

  if is_enabled "${ENABLE_ETA_TOUCHDRV}"; then
    run_step "eta-touchdrv paketini kurma veya guncelleme" install_or_upgrade_eta_touchdrv
  fi

  if is_enabled "${ENABLE_ETAPADMIN_PASSWORD}"; then
    run_step "${ETAPADMIN_USER} parolasini degistirme" set_etapadmin_password
  fi

  if is_enabled "${ENABLE_WINE}"; then
    run_step "Wine ve winetricks kurulumunu yapma" install_and_configure_wine
  fi

  run_step "kurulum sonu kontrollerini calistirma" run_post_install_checks

  CURRENT_STEP=""
  log "Kurulum tamamlandi."

  if is_enabled "${ENABLE_OPEN_ETA_KAYIT}"; then
    run_step "eta-register paketini kurma veya guncelleme" ensure_eta_kayit_package_ready_for_launch
    run_step "ETA Kayit uygulamasini acma" open_eta_kayit_if_available
  fi

  if is_enabled "${ENABLE_WINE}"; then
    log "Wine klasor adi: ${WINE_PREFIX_NAME}"
    log "Baslaticilar: /usr/local/bin/etap-wine ve /usr/local/bin/etap-winetricks"
  fi
}

main "$@"
