#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
TTY_DEVICE="${TTY_DEVICE:-/dev/tty}"

GUI_MODE=0
SHOW_GUI_RESULT=0
ACTION=""
ACTION_VALUE=""
REPORT_FILE=""

KYOCERA_ETAP_GUIDE_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/b-kyocera-yazici-kurulumu-nasil-yapilir"
KYOCERA_VENDOR_URL="https://kyoceradocumentsolutions.com.tr/"
ETAP_PRINTER_INDEX_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar"
ETAP_PRINTER_READY_UI_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/b-arayuz-ile-surucusu-hazir-yazici-kurulumu"
ETAP_PRINTER_CUPS_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/c-cups-baglantisi-ile-surucusu-hazir-yazici-kurulumu"
ETAP_PRINTER_DOWNLOAD_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu"
BROTHER_ETAP_GUIDE_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/c-brother-marka-yazici-kurulumu-nasil-yapilir"
BROTHER_PARDUS_DOC_URL="https://belge.pardus.org.tr/display/PYMBB/Brother"
BROTHER_INSTALLER_URL="https://belge.pardus.org.tr/download/attachments/117997644/linux-brprinter-installer-2.2.3-1?version=1&modificationDate=1704839652130&api=v2"
EPSON_ETAP_GUIDE_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/d-epson-marka-yazici-kurulumu-nasil-yapilir"
EPSON_PARDUS_DOC_URL="https://belge.pardus.org.tr/display/PYMBB/Epson"
HP_ETAP_GUIDE_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/e-hp-yazici-kurulumu-nasil-yapilir"
HP_VIDEO_URL="https://www.youtube.com/watch?v=iNE1IR-0jDc"
CANON_ETAP_GUIDE_URL="https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/f-canon-yazici-kurulumu-nasil-yapilir"
CANON_VIDEO_URL="https://www.youtube.com/watch?v=qD2JuAcD-aA"
KYOCERA_BUNDLE_ROOT="${SCRIPT_DIR}/private/kyocera/fs-1120mfp"
KYOCERA_DOWNLOAD_DIR="${KYOCERA_BUNDLE_ROOT}/downloads"
KYOCERA_WORK_DIR="${KYOCERA_BUNDLE_ROOT}/work"
KYOCERA_UNIVERSAL_ZIP="${KYOCERA_DOWNLOAD_DIR}/Linux_Universal_Driver.zip"
KYOCERA_MODEL_ZIP="${KYOCERA_DOWNLOAD_DIR}/LinuxDrv_1.1203_FS-1x2xMFP.zip"

usage() {
  cat <<'EOF'
Kullanim:
  ./sss_destek_araci.sh --gui
  ./sss_destek_araci.sh --printer-report
  sudo ./sss_destek_araci.sh --printer-restart
  ./sss_destek_araci.sh --file-share-report
  ./sss_destek_araci.sh --driver-check PAKET
  ./sss_destek_araci.sh --printer-guides
  ./sss_destek_araci.sh --kyocera-guide
  ./sss_destek_araci.sh --kyocera-local-status
  ./sss_destek_araci.sh --kyocera-local-prepare
  sudo ./sss_destek_araci.sh --kyocera-local-install

Bu arac, ETAP/Pardus tarafinda sik karsilasilan yazici, dosya paylasim ve paket/surucu
sorunlarinda hizli kontrol ve yonlendirme saglar.

Secenekler:
  --gui                 Grafik ya da terminal menusu ac
  --printer-report      CUPS ve tanimli yazicilar icin durum raporu olustur
  --printer-restart     cups.service birimini yeniden baslatmayi dene
  --file-share-report   SMB/CIFS ve NFS istemci hazirligini raporla
  --driver-check PAKET  Paket/surucu icin dpkg ve apt-cache ozetini goster
  --printer-guides      ETAP yazici alt rehberlerinin toplu ozetini goster
  --kyocera-guide       ETAP rehberindeki Kyocera yazici kurulum adimlarini ozetle
  --kyocera-local-status
                        Yerel Kyocera bundle durumunu ve bulunan dosyalari goster
  --kyocera-local-prepare
                        Yerel Kyocera bundle dosyalarini work dizinine cikart
  --kyocera-local-install
                        Yerel bundle icinden kyodialog ve model surucusunu kurmayi dene
  --report-file DOSYA   Ciktiyi belirtilen dosyaya da yaz
  -h, --help            Bu yardimi goster
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

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

set_action() {
  local new_action="$1"

  if [[ -n "${ACTION}" && "${ACTION}" != "${new_action}" ]]; then
    fail "Yalnizca tek bir ana islem secilebilir."
  fi

  ACTION="${new_action}"
}

normalize_report_path() {
  local report_path="$1"

  [[ "${report_path}" == /* ]] || report_path="$(pwd -P)/${report_path}"
  printf '%s\n' "${report_path}"
}

ensure_report_output_dir() {
  local target_dir="${ETAP23_RUNTIME_DIR}"

  if [[ ! -d "${target_dir}" ]]; then
    mkdir -p "${target_dir}" 2>/dev/null || true
  fi

  if [[ -d "${target_dir}" && -w "${target_dir}" ]]; then
    printf '%s\n' "${target_dir}"
    return 0
  fi

  target_dir="/tmp/etap23-reports"
  mkdir -p "${target_dir}" || fail "Rapor klasoru olusturulamadi: ${target_dir}"
  chmod 700 "${target_dir}" 2>/dev/null || true
  printf '%s\n' "${target_dir}"
}

create_report_file() {
  local report_dir=""
  local temp_path=""
  local log_path=""

  report_dir="$(ensure_report_output_dir)"
  temp_path="$(mktemp "${report_dir}/rapor-sss-destek.XXXXXX" 2>/dev/null || true)"
  [[ -n "${temp_path}" ]] || fail "Rapor dosyasi olusturulamadi: ${report_dir}"
  log_path="${temp_path}.log"
  mv "${temp_path}" "${log_path}" || fail "Rapor dosyasi hazirlanamadi: ${log_path}"
  printf '%s\n' "${log_path}"
}

action_generates_report_by_default() {
  case "${ACTION}" in
    printer-report|file-share-report|driver-check|printer-guides|kyocera-guide|kyocera-local-status|kyocera-local-prepare)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

prepare_report_destination() {
  local report_dir=""

  if [[ -n "${REPORT_FILE}" ]]; then
    REPORT_FILE="$(normalize_report_path "${REPORT_FILE}")"
    report_dir="$(dirname "${REPORT_FILE}")"
    mkdir -p "${report_dir}" 2>/dev/null || fail "Rapor klasoru olusturulamadi: ${report_dir}"
    : >"${REPORT_FILE}" || fail "Rapor dosyasi hazirlanamadi: ${REPORT_FILE}"
    chmod 600 "${REPORT_FILE}" 2>/dev/null || true
    printf '%s\n' "${REPORT_FILE}"
    return 0
  fi

  action_generates_report_by_default || return 0
  REPORT_FILE="$(create_report_file)"
  chmod 600 "${REPORT_FILE}" 2>/dev/null || true
  printf '%s\n' "${REPORT_FILE}"
}

action_dialog_title() {
  case "${ACTION}" in
    printer-report)
      printf 'Yazici Durum Raporu\n'
      ;;
    printer-restart)
      printf 'Yazici Servisi Yeniden Baslatma\n'
      ;;
    file-share-report)
      printf 'Dosya Paylasim Hazirlik Raporu\n'
      ;;
    driver-check)
      printf 'Paket ve Surucu Kontrolu\n'
      ;;
    printer-guides)
      printf 'ETAP Yazici Rehberleri\n'
      ;;
    kyocera-guide)
      printf 'Kyocera Kurulum Ozeti\n'
      ;;
    kyocera-local-status)
      printf 'Kyocera Yerel Bundle Durumu\n'
      ;;
    kyocera-local-prepare)
      printf 'Kyocera Yerel Bundle Hazirligi\n'
      ;;
    kyocera-local-install)
      printf 'Kyocera Yerel Kurulum\n'
      ;;
    *)
      printf 'ETAP SSS ve Destek Araci\n'
      ;;
  esac
}

show_gui_output_dialog() {
  local status="$1"
  local output_file="$2"
  local report_path="$3"
  local body=""
  local temp_view=""

  temp_view="$(mktemp)"

  if [[ "${status}" -eq 0 ]]; then
    body="Islem tamamlandi. Ayrintilar asagida."
  else
    body="Islem hata veya uyari ile sonlandi. Ayrintilar asagida."
  fi

  {
    printf '%s\n\n' "${body}"
    if [[ -n "${report_path}" ]]; then
      printf 'Rapor dosyasi: %s\n\n' "${report_path}"
    fi
    if [[ -s "${output_file}" ]]; then
      cat "${output_file}"
    else
      printf 'Cikti uretilemedi.\n'
    fi
  } >"${temp_view}"

  zenity --text-info \
    --title="$(action_dialog_title)" \
    --width=920 \
    --height=680 \
    --filename="${temp_view}" || true

  rm -f "${temp_view}"
}

report_heading() {
  printf '=== %s ===\n' "$1"
}

report_section() {
  printf '\n--- %s ---\n' "$1"
}

report_info() {
  printf '[BILGI] %s\n' "$1"
}

report_ok() {
  printf '[OK] %s\n' "$1"
}

report_warn() {
  printf '[UYARI] %s\n' "$1"
}

report_command_presence() {
  local command_name="$1"
  local label="$2"
  local path=""

  if path="$(command -v "${command_name}" 2>/dev/null || true)" && [[ -n "${path}" ]]; then
    report_ok "${label}: bulundu (${path})"
  else
    report_warn "${label}: bulunamadi (${command_name})"
  fi
}

report_systemd_unit() {
  local unit="$1"
  local label="$2"
  local optional="${3:-0}"
  local load_state=""
  local active_state=""
  local sub_state=""
  local unit_file_state=""

  if ! command_exists systemctl; then
    report_info "systemctl bulunamadigi icin ${label} kontrolu atlandi."
    return 0
  fi

  load_state="$(systemctl show "${unit}" -p LoadState --value 2>/dev/null || true)"
  if [[ -z "${load_state}" || "${load_state}" == "not-found" ]]; then
    if [[ "${optional}" == "1" ]]; then
      report_info "${label}: bu sistemde kurulu degil."
    else
      report_warn "${label}: sistemd birimi bulunamadi (${unit})"
    fi
    return 0
  fi

  active_state="$(systemctl show "${unit}" -p ActiveState --value 2>/dev/null || true)"
  sub_state="$(systemctl show "${unit}" -p SubState --value 2>/dev/null || true)"
  unit_file_state="$(systemctl show "${unit}" -p UnitFileState --value 2>/dev/null || true)"

  report_info "${label}: active=${active_state:-bilinmiyor}, sub=${sub_state:-bilinmiyor}, enabled=${unit_file_state:-bilinmiyor}"

  if [[ "${active_state}" == "active" ]]; then
    report_ok "${label} aktif."
  elif [[ "${optional}" == "1" ]]; then
    report_info "${label} aktif degil."
  else
    report_warn "${label} aktif degil."
  fi
}

report_mounted_shares() {
  local source=""
  local mount_point=""
  local fs_type=""
  local rest=""
  local found=0

  if [[ ! -r /proc/mounts ]]; then
    report_info "/proc/mounts okunamadigi icin aktif paylasim baglari listelenemedi."
    return 0
  fi

  while read -r source mount_point fs_type rest; do
    case "${fs_type}" in
      cifs|smb3|nfs|nfs4|fuse.gvfsd-fuse)
        found=1
        printf '%s -> %s (%s)\n' "${source}" "${mount_point}" "${fs_type}"
        ;;
    esac
  done </proc/mounts

  if (( found == 0 )); then
    report_info "Aktif CIFS/SMB/NFS baglantisi tespit edilmedi."
  fi
}

run_as_root_if_needed() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
    return "$?"
  fi

  command_exists sudo || fail "Bu islem yonetici yetkisi gerektirir; sudo bulunamadi."
  sudo "$@"
}

file_size_human() {
  local file_path="$1"

  if [[ ! -e "${file_path}" ]]; then
    printf 'yok\n'
    return 0
  fi

  if stat -c '%s' "${file_path}" >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$(stat -c '%s' "${file_path}")" 2>/dev/null || stat -c '%s' "${file_path}"
    return 0
  fi

  if stat -f '%z' "${file_path}" >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$(stat -f '%z' "${file_path}")" 2>/dev/null || stat -f '%z' "${file_path}"
    return 0
  fi

  printf 'okunamadi\n'
}

first_matching_path() {
  local base_dir="$1"
  shift

  find "${base_dir}" "$@" 2>/dev/null | head -n 1
}

kyocera_bundle_universal_tar_path() {
  first_matching_path "${KYOCERA_WORK_DIR}/universal_zip" -type f -name 'KyoceraLinuxPackages-*.tar.gz'
}

kyocera_bundle_kyodialog_deb_path() {
  local deb_path=""

  deb_path="$(first_matching_path "${KYOCERA_WORK_DIR}/universal_extract" -type f -path '*/Debian/Global/kyodialog_amd64/kyodialog_*_amd64.deb')"
  if [[ -n "${deb_path}" ]]; then
    printf '%s\n' "${deb_path}"
    return 0
  fi

  deb_path="$(first_matching_path "${KYOCERA_WORK_DIR}/universal_extract" -type f -path '*/Ubuntu/Global/kyodialog_amd64/kyodialog_*_amd64.deb')"
  if [[ -n "${deb_path}" ]]; then
    printf '%s\n' "${deb_path}"
    return 0
  fi

  first_matching_path "${KYOCERA_WORK_DIR}/universal_extract" -type f -name 'kyodialog_*_amd64.deb'
}

kyocera_bundle_model_turkish_tar_path() {
  first_matching_path "${KYOCERA_WORK_DIR}/model_zip" -type f -path '*/64bit/Global/turkish.tar.gz'
}

kyocera_bundle_install_script_path() {
  local install_path=""

  install_path="$(first_matching_path "${KYOCERA_WORK_DIR}/model_extract" -type f -name 'install.sh')"
  if [[ -n "${install_path}" ]]; then
    printf '%s\n' "${install_path}"
    return 0
  fi

  first_matching_path "${KYOCERA_WORK_DIR}/model_extract" -type f -name 'install'
}

kyocera_bundle_ppd_dir_path() {
  first_matching_path "${KYOCERA_WORK_DIR}/model_extract" -type d -name 'turkish'
}

ensure_kyocera_local_downloads_present() {
  [[ -f "${KYOCERA_UNIVERSAL_ZIP}" ]] || fail "Yerel universal driver bulunamadi: ${KYOCERA_UNIVERSAL_ZIP}"
  [[ -f "${KYOCERA_MODEL_ZIP}" ]] || fail "Yerel model driver bulunamadi: ${KYOCERA_MODEL_ZIP}"
}

prepare_kyocera_bundle_directories() {
  mkdir -p \
    "${KYOCERA_DOWNLOAD_DIR}" \
    "${KYOCERA_WORK_DIR}/universal_zip" \
    "${KYOCERA_WORK_DIR}/universal_extract" \
    "${KYOCERA_WORK_DIR}/model_zip" \
    "${KYOCERA_WORK_DIR}/model_extract"
}

extract_kyocera_local_bundle() {
  local universal_tar=""
  local model_tar=""

  ensure_kyocera_local_downloads_present
  command_exists unzip || fail "unzip bulunamadi."
  command_exists tar || fail "tar bulunamadi."
  prepare_kyocera_bundle_directories

  unzip -oq "${KYOCERA_UNIVERSAL_ZIP}" -d "${KYOCERA_WORK_DIR}/universal_zip"
  universal_tar="$(kyocera_bundle_universal_tar_path)"
  [[ -n "${universal_tar}" ]] || fail "Universal bundle icinden tar.gz bulunamadi."
  tar -xzf "${universal_tar}" -C "${KYOCERA_WORK_DIR}/universal_extract"

  unzip -oq "${KYOCERA_MODEL_ZIP}" -d "${KYOCERA_WORK_DIR}/model_zip"
  model_tar="$(kyocera_bundle_model_turkish_tar_path)"
  [[ -n "${model_tar}" ]] || fail "Model bundle icinden turkish.tar.gz bulunamadi."
  tar -xzf "${model_tar}" -C "${KYOCERA_WORK_DIR}/model_extract"
}

run_kyocera_local_status() {
  local universal_tar=""
  local kyodialog_deb=""
  local model_tar=""
  local install_script=""
  local ppd_dir=""

  report_heading "Kyocera yerel bundle durumu"
  report_info "Bundle kok dizini: ${KYOCERA_BUNDLE_ROOT}"

  report_section "Indirilen dosyalar"
  if [[ -f "${KYOCERA_UNIVERSAL_ZIP}" ]]; then
    report_ok "Universal driver bulundu: ${KYOCERA_UNIVERSAL_ZIP} ($(file_size_human "${KYOCERA_UNIVERSAL_ZIP}"))"
  else
    report_warn "Universal driver bulunamadi: ${KYOCERA_UNIVERSAL_ZIP}"
  fi

  if [[ -f "${KYOCERA_MODEL_ZIP}" ]]; then
    report_ok "Model driver bulundu: ${KYOCERA_MODEL_ZIP} ($(file_size_human "${KYOCERA_MODEL_ZIP}"))"
  else
    report_warn "Model driver bulunamadi: ${KYOCERA_MODEL_ZIP}"
  fi

  report_section "Hazirlanan yerel yollar"
  universal_tar="$(kyocera_bundle_universal_tar_path)"
  [[ -n "${universal_tar}" ]] && report_ok "Universal tar bulundu: ${universal_tar}" || report_info "Universal tar henuz hazir degil."

  kyodialog_deb="$(kyocera_bundle_kyodialog_deb_path)"
  [[ -n "${kyodialog_deb}" ]] && report_ok "kyodialog deb bulundu: ${kyodialog_deb}" || report_info "kyodialog deb henuz hazir degil."

  model_tar="$(kyocera_bundle_model_turkish_tar_path)"
  [[ -n "${model_tar}" ]] && report_ok "Model turkish tar bulundu: ${model_tar}" || report_info "Model turkish tar henuz hazir degil."

  install_script="$(kyocera_bundle_install_script_path)"
  [[ -n "${install_script}" ]] && report_ok "Install betigi bulundu: ${install_script}" || report_info "Install betigi henuz hazir degil."

  ppd_dir="$(kyocera_bundle_ppd_dir_path)"
  if [[ -n "${ppd_dir}" ]]; then
    report_ok "PPD dizini bulundu: ${ppd_dir}"
    find "${ppd_dir}" -maxdepth 1 -type f -name 'Kyocera_*.ppd' 2>/dev/null | sed -n '1,20p'
  else
    report_info "PPD dizini henuz hazir degil."
  fi

  report_section "Onerilen sonraki adimlar"
  printf '1. Bundle dosyalari hazir degilse once --kyocera-local-prepare calistirin.\n'
  printf '2. Linux/Pardus cihazda yerel kurulum icin --kyocera-local-install kullanin.\n'
  printf '3. Kurulumdan sonra Yazici Ayarlari icinde uygun PPD dosyasini secin.\n'
}

run_kyocera_local_prepare() {
  report_heading "Kyocera yerel bundle hazirlama"
  extract_kyocera_local_bundle
  run_kyocera_local_status
}

run_kyocera_local_install() {
  local kyodialog_deb=""
  local install_script=""
  local install_dir=""

  [[ "$(uname -s)" == "Linux" ]] || fail "Yerel Kyocera kurulum kipi yalnizca Linux/Pardus uzerinde calistirilabilir."
  extract_kyocera_local_bundle

  kyodialog_deb="$(kyocera_bundle_kyodialog_deb_path)"
  install_script="$(kyocera_bundle_install_script_path)"
  [[ -n "${kyodialog_deb}" ]] || fail "kyodialog deb bulunamadi."
  [[ -n "${install_script}" ]] || fail "Model install betigi bulunamadi."
  install_dir="$(dirname "${install_script}")"

  report_heading "Kyocera yerel kurulum"
  report_info "kyodialog paketi: ${kyodialog_deb}"
  report_info "Model installer: ${install_script}"

  run_as_root_if_needed apt-get update
  run_as_root_if_needed apt-get install -f -y
  run_as_root_if_needed dpkg -i "${kyodialog_deb}"
  run_as_root_if_needed sh -c "cd \"${install_dir}\" && sh \"./$(basename "${install_script}")\""

  report_section "PPD sonrasi secim yolu"
  printf '/usr/share/cups/model/Kyocera/\n'
  if [[ -d /usr/share/cups/model/Kyocera ]]; then
    find /usr/share/cups/model/Kyocera -maxdepth 1 -type f -name 'Kyocera_*.ppd' 2>/dev/null | sed -n '1,20p'
  else
    report_info "Sistem PPD dizini henuz olusmamis olabilir."
  fi
}

run_printer_report() {
  report_heading "Yazici durum raporu"
  report_systemd_unit "cups.service" "CUPS"
  report_systemd_unit "cups-browsed.service" "cups-browsed" 1

  report_section "Yazici araclari"
  report_command_presence lpstat "CUPS istemcisi"
  report_command_presence lpinfo "Yazici aygit tarayicisi"
  report_command_presence lpadmin "Yazici tanimlama araci"

  report_section "CUPS zamanlayicisi"
  if command_exists lpstat; then
    lpstat -r 2>&1 || true
  else
    report_info "lpstat bulunamadigi icin yazici zamanlayicisi ozeti atlandi."
  fi

  report_section "Tanimli yazicilar ve kuyruklar"
  if command_exists lpstat; then
    lpstat -t 2>&1 || true
  else
    report_info "lpstat bulunamadigi icin tanimli yazicilar listelenemedi."
  fi

  report_section "Gorulen yazici baglanti arka uclari"
  if command_exists lpinfo; then
    lpinfo -v 2>&1 || true
  else
    report_info "lpinfo bulunamadigi icin aygit arka uclari listelenemedi."
  fi

  report_section "Onerilen sonraki adimlar"
  printf '1. Yazici listede yoksa once ag/IP bilgisini ve kablo baglantisini kontrol edin.\n'
  printf '2. Gerekirse CUPS web arayuzunu kullanin: http://localhost:631/admin\n'
  printf '3. Kyocera ise bu aracta --kyocera-guide ciktisini izleyin.\n'
}

run_printer_restart() {
  report_heading "Yazici servisi yeniden baslatma"

  if ! command_exists systemctl; then
    fail "systemctl bulunamadi; bu islem yalnizca systemd sistemlerde desteklenir."
  fi

  run_as_root_if_needed systemctl restart cups.service

  if systemctl show cups-browsed.service -p LoadState --value 2>/dev/null | grep -qv '^not-found$'; then
    run_as_root_if_needed systemctl restart cups-browsed.service || true
  fi

  report_systemd_unit "cups.service" "CUPS"
  report_systemd_unit "cups-browsed.service" "cups-browsed" 1
}

run_file_share_report() {
  report_heading "Dosya paylasim hazirlik raporu"
  report_systemd_unit "NetworkManager.service" "Ag yoneticisi"
  report_systemd_unit "avahi-daemon.service" "Avahi" 1
  report_systemd_unit "wsdd.service" "WSDD" 1
  report_systemd_unit "smbd.service" "Samba sunucusu" 1
  report_systemd_unit "nmbd.service" "NetBIOS" 1

  report_section "Istemci araclari"
  report_command_presence gio "GIO/GVFS istemcisi"
  report_command_presence smbclient "SMB istemcisi"
  report_command_presence mount.cifs "CIFS baglama araci"
  report_command_presence mount.nfs "NFS baglama araci"

  report_section "Aktif ag paylasimi baglari"
  report_mounted_shares

  report_section "Onerilen sonraki adimlar"
  printf '1. SMB paylasimi taramak icin: smbclient -L //SUNUCU -U KULLANICI\n'
  printf '2. Grafik oturumda ag konumunu acmak icin: gio open smb://SUNUCU/PAYLASIM\n'
  printf '3. Kyocera tarama-klasor akisi icin ETAP rehberindeki dosya paylasma basligini ve yazicinin SMB ayarlarini birlikte kontrol edin.\n'
}

run_driver_check() {
  local package_name="${ACTION_VALUE}"
  local dpkg_status=""

  [[ -n "${package_name}" ]] || fail "Kontrol edilecek paket adi belirtilmedi."

  report_heading "Paket ve surucu kontrolu: ${package_name}"

  report_section "Kurulum durumu"
  if command_exists dpkg-query; then
    dpkg_status="$(dpkg-query -W -f='${Status} ${Version}\n' "${package_name}" 2>/dev/null || true)"
    if [[ -n "${dpkg_status}" ]]; then
      report_ok "${dpkg_status}"
    else
      report_warn "${package_name} paketi kurulu gorunmuyor."
    fi
  else
    report_info "dpkg-query bulunamadigi icin kurulum durumu okunamadi."
  fi

  report_section "Depo bilgisi"
  if command_exists apt-cache; then
    apt-cache policy "${package_name}" 2>&1 || true
  else
    report_info "apt-cache bulunamadigi icin depo bilgisi okunamadi."
  fi

  report_section "Onerilen sonraki adimlar"
  printf '1. Paket bozuksa yeniden kurmayi deneyin: sudo apt install --reinstall %s\n' "${package_name}"
  printf '2. Kyocera tarafinda once kyodialog paketini, sonra model surucusunu kontrol edin.\n'
}

run_printer_guides() {
  report_heading "ETAP yazici rehberleri ozeti"

  report_section "Genel yazici yonetimi"
  report_info "Kaynak: ${ETAP_PRINTER_INDEX_URL}"
  printf '1. Sistem Ayarlari > Yazicilar ekraninda yazicilar, baglanti turleri ve kuyruk durumu gorulur.\n'
  printf '2. Yazici ekleme veya degistirme icin once \"Kilidi Ac...\" ile yetkili kullanici parolasi girilir.\n'
  printf '3. lpadmin grubu uyeleri yazici yonetebilir.\n'

  report_section "Arayuz ile surucusu hazir yazici kurulumu"
  report_info "Kaynak: ${ETAP_PRINTER_READY_UI_URL}"
  printf 'On hazirlik komutlari:\n'
  printf '  sudo dpkg --add-architecture i386\n'
  printf '  sudo apt-get update\n'
  printf '  sudo apt install --reinstall printer-driver-* cups* tix groff dc make gcc jbigkit-bin hpijs-ppds\n'
  printf '  sudo /etc/init.d/cups restart\n'
  printf 'Ardindan sistemi yeniden baslatin.\n'
  printf 'Ayarlar > Yazicilar > Yazici Ekle adiminda ag yazicisi listede yoksa IP girilebilir.\n'
  printf 'Marka listede yoksa CUPS-BRF-Printer secilerek devam edilebilir.\n'
  printf 'Kurulum sihirbazinda surucu arama, veri tabanindan marka-model secme veya PPD dosyasi saglama yollarindan biri kullanilir.\n'
  printf 'CUPS web arayuzu icin: http://localhost:631\n'

  report_section "CUPS baglantisi ile surucusu hazir yazici kurulumu"
  report_info "Kaynak: ${ETAP_PRINTER_CUPS_URL}"
  printf 'On hazirlik komutlari arayuz kurulumundaki ile aynidir.\n'
  printf 'Tarayicida http://localhost:631 acilir ve Administration menusu uzerinden yazici yonetilir.\n'
  printf 'CUPS tarafinda Add Printer, Find New Printers ve Manage Printers islemleri kullanilir.\n'
  printf 'Local Printers listesinden CUPS-BRF secilerek marka-model veya PPD secimine ilerlenebilir.\n'
  printf 'Paylasima acilan yazicilar diger cihazlar tarafindan da kullanilabilir.\n'

  report_section "Internetten surucu indirilmesi gereken yazicilar"
  report_info "Kaynak: ${ETAP_PRINTER_DOWNLOAD_URL}"
  printf 'Arayuz ve CUPS yontemleri calismiyorsa modelinizin surucusu Pardus icinde hazir gelmiyor olabilir.\n'
  printf 'Bu durumda markanin resmi sitesinden Linux surucusu indirilip uretici adimlari izlenir.\n'
  printf 'ETAP rehberi marka bazli alt basliklar sunar; tum denemelere ragmen kurulum olmazsa 444 5 773 destek hattina yonlendirme verilir.\n'

  report_section "Brother"
  report_info "ETAP kaynagi: ${BROTHER_ETAP_GUIDE_URL}"
  report_info "Pardus belge: ${BROTHER_PARDUS_DOC_URL}"
  report_info "Dogrudan installer: ${BROTHER_INSTALLER_URL}"
  printf 'Brother icin once resmi siteden Debian (.deb) ya da genel Linux surucusu aranir.\n'
  printf 'Pardus belge uzerinden linux-brprinter-installer-2.2.3-1 dosyasi da indirilebilir.\n'
  printf 'Komut sirasi:\n'
  printf '  sudo dpkg --add-architecture i386 && sudo apt update\n'
  printf '  sudo chmod u+x linux-brprinter-installer-2.2.3-1\n'
  printf '  sudo ./linux-brprinter-installer-2.2.3-1\n'
  printf 'Installer calisirken yazici modeli girilerek sihirbaz takip edilir.\n'

  report_section "Epson"
  report_info "ETAP kaynagi: ${EPSON_ETAP_GUIDE_URL}"
  report_info "Pardus belge: ${EPSON_PARDUS_DOC_URL}"
  printf 'ETAP rehberindeki ilk yol ESC/P-R surucusunu kurmaktir.\n'
  printf 'Komut sirasi:\n'
  printf '  sudo apt-get -f install\n'
  printf '  sudo dpkg --configure -a\n'
  printf '  sudo apt update\n'
  printf '  sudo apt install printer-driver-escpr\n'
  printf 'Alternatif yol olarak rehber, guncelleme sonrasi lsb-compat_9.20161125_amd64.deb paketinin elle indirilip sudo dpkg -i ile kurulmasini da not eder.\n'

  report_section "HP"
  report_info "ETAP kaynagi: ${HP_ETAP_GUIDE_URL}"
  report_info "Kurulum videosu: ${HP_VIDEO_URL}"
  printf 'Bu sayfada metin yerine HP yazicilar icin video yonlendirmesi bulunur.\n'
  printf 'HP icin ilk kontrol, sistemde hplip/hp-setup araclari ve CUPS durumudur.\n'

  report_section "Canon"
  report_info "ETAP kaynagi: ${CANON_ETAP_GUIDE_URL}"
  report_info "Kurulum videosu: ${CANON_VIDEO_URL}"
  printf 'Bu sayfada metin yerine Canon yazicilar icin video yonlendirmesi bulunur.\n'
  printf 'Canon tarafinda model bazli Linux surucusu ve uygun PPD secimi gerekip gerekmedigi uretici sayfasindan dogrulanmalidir.\n'

  report_section "Kyocera"
  report_info "ETAP kaynagi: ${KYOCERA_ETAP_GUIDE_URL}"
  printf 'Kyocera ozeti icin: --kyocera-guide\n'
  printf 'Bu repoda indirilen yerel bundle durumu icin: --kyocera-local-status\n'
  printf 'Yerel bundle dosyalarini cikartmak icin: --kyocera-local-prepare\n'
  printf 'Linux/Pardus cihazda yerel bundle ile kurulum icin: sudo ./sss_destek_araci.sh --kyocera-local-install\n'
}

run_kyocera_guide() {
  report_heading "Kyocera yazici kurulum ozeti"

  report_info "Kaynak ETAP rehberi: ${KYOCERA_ETAP_GUIDE_URL}"
  report_info "Uretici ana sitesi: ${KYOCERA_VENDOR_URL}"

  report_section "ETAP rehberine gore ozet akis"
  printf '1. Kyocera destek/indirme merkezinde yazici modelinizi secin.\n'
  printf '2. Modelinize uygun \"Linux Universal Driver\" ve \"Linux Driver\" dosyalarini indirin.\n'
  printf '3. Universal driver arsivini cikartin; olusan paket icindeki Debian/Global/kyodialog_amd64/ dizinine girin.\n'
  printf '4. Bu dizinde terminal acip sirasiyla su komutlari calistirin:\n'
  printf '   sudo apt update\n'
  printf '   sudo apt -f install\n'
  printf '   sudo dpkg -i kyodialog_*.deb\n'
  printf '5. Model driver arsivini cikartin; 64bit/Global/turkish.tar.gz arsivini da acin.\n'
  printf '6. Olusan turkish dizininde terminal acip su komutu calistirin:\n'
  printf '   sudo ./install\n'
  printf '7. Yazici ekleme sirasinda \"PPD Dosyasini saglayin\" secenegini kullanin.\n'
  printf '8. /usr/share/cups/model/Kyocera/ altindaki modelinize uygun .ppd dosyasini secerek kurulumu tamamlayin.\n'

  report_section "Rehberde gecen ornek dosya ve yol adlari"
  printf '%s\n' '- Linux_Universal_Driver.zip'
  printf '%s\n' '- KyoceraLinuxPackages-20220928.tar.gz'
  printf '%s\n' '- Debian/Global/kyodialog_amd64/'
  printf '%s\n' '- LinuxDrv_1.1203_FS-1x2xMFP.zip'
  printf '%s\n' '- /usr/share/cups/model/Kyocera/Kyocera_FS-1120MFPGDI.ppd'

  report_section "Onemli not"
  printf 'Rehberdeki dosya adlari ve .ppd ornegi model/surum bazli degisebilir.\n'
  printf 'Ayni dizin yapisini takip edin, ancak en sonda modelinize uygun .deb ve .ppd dosyasini secin.\n'
  printf 'Bu repoda yerel bundle kok dizini su sekilde beklenir: %s\n' "${KYOCERA_BUNDLE_ROOT}"
}

run_selected_action() {
  case "${ACTION}" in
    printer-report)
      run_printer_report
      ;;
    printer-restart)
      run_printer_restart
      ;;
    file-share-report)
      run_file_share_report
      ;;
    driver-check)
      run_driver_check
      ;;
    printer-guides)
      run_printer_guides
      ;;
    kyocera-guide)
      run_kyocera_guide
      ;;
    kyocera-local-status)
      run_kyocera_local_status
      ;;
    kyocera-local-prepare)
      run_kyocera_local_prepare
      ;;
    kyocera-local-install)
      run_kyocera_local_install
      ;;
    *)
      fail "Desteklenmeyen islem: ${ACTION}"
      ;;
  esac
}

execute_selected_action() {
  local report_path=""
  local output_file=""
  local status=0

  report_path="$(prepare_report_destination)"

  if (( SHOW_GUI_RESULT )) && can_use_zenity; then
    output_file="$(mktemp)"
    set +e
    if [[ -n "${report_path}" ]]; then
      run_selected_action 2>&1 | tee "${report_path}" >"${output_file}"
      status="${PIPESTATUS[0]}"
    else
      run_selected_action >"${output_file}" 2>&1
      status=$?
    fi
    set -e

    show_gui_output_dialog "${status}" "${output_file}" "${report_path}"
    rm -f "${output_file}"
    return "${status}"
  fi

  if [[ -n "${report_path}" ]]; then
    set +e
    run_selected_action 2>&1 | tee "${report_path}"
    status="${PIPESTATUS[0]}"
    set -e
    printf '\nRapor dosyasi: %s\n' "${report_path}"
    return "${status}"
  fi

  run_selected_action
}

prompt_driver_package_gui() {
  local reply=""

  reply="$(zenity --entry \
    --title="Paket veya Surucu Kontrolu" \
    --width=480 \
    --text="Kontrol edilecek paket adini girin" \
    --entry-text="kyodialog")" || return 1

  [[ -n "${reply}" ]] || return 1
  ACTION_VALUE="${reply}"
}

collect_gui_action() {
  local selection=""

  selection="$(zenity --list \
    --radiolist \
    --title="ETAP SSS ve Destek Araci" \
    --text="Yapmak istediginiz islemi secin" \
    --width=920 \
    --height=500 \
    --column="Sec" \
    --column="Kod" \
    --column="Aciklama" \
    FALSE printer_report "Yazici durum raporu olustur" \
    FALSE printer_restart "Yazici servisini yeniden baslat" \
    FALSE file_share_report "Dosya paylasim hazirligini raporla" \
    FALSE driver_check "Paket veya surucu kontrolu yap" \
    FALSE printer_guides "ETAP yazici rehberlerinin toplu ozetini goster" \
    FALSE kyocera_guide "Kyocera kurulum adimlarini ozetle" \
    FALSE kyocera_local_status "Yerel Kyocera bundle durumunu goster" \
    FALSE kyocera_local_prepare "Yerel Kyocera bundle dosyalarini cikart" \
    FALSE kyocera_local_install "Yerel Kyocera bundle ile kurulumu baslat")" || return 1

  case "${selection}" in
    printer_report)
      ACTION="printer-report"
      ;;
    printer_restart)
      ACTION="printer-restart"
      ;;
    file_share_report)
      ACTION="file-share-report"
      ;;
    driver_check)
      ACTION="driver-check"
      prompt_driver_package_gui || return 1
      ;;
    printer_guides)
      ACTION="printer-guides"
      ;;
    kyocera_guide)
      ACTION="kyocera-guide"
      ;;
    kyocera_local_status)
      ACTION="kyocera-local-status"
      ;;
    kyocera_local_prepare)
      ACTION="kyocera-local-prepare"
      ;;
    kyocera_local_install)
      ACTION="kyocera-local-install"
      ;;
    *)
      return 1
      ;;
  esac

  SHOW_GUI_RESULT=1
}

collect_cli_action() {
  local choice=""

  while true; do
    print_line 'ETAP SSS ve Destek Araci\n'
    print_line '  1) Yazici durum raporu olustur\n'
    print_line '  2) Yazici servisini yeniden baslat\n'
    print_line '  3) Dosya paylasim hazirligini raporla\n'
    print_line '  4) Paket veya surucu kontrolu yap\n'
    print_line '  5) ETAP yazici rehberlerinin toplu ozetini goster\n'
    print_line '  6) Kyocera kurulum adimlarini ozetle\n'
    print_line '  7) Yerel Kyocera bundle durumunu goster\n'
    print_line '  8) Yerel Kyocera bundle dosyalarini cikart\n'
    print_line '  9) Yerel Kyocera bundle ile kurulumu baslat\n'
    print_line 'Seciminiz: '
    choice="$(read_line_from_user || true)"

    case "${choice}" in
      1)
        ACTION="printer-report"
        return 0
        ;;
      2)
        ACTION="printer-restart"
        return 0
        ;;
      3)
        ACTION="file-share-report"
        return 0
        ;;
      4)
        ACTION="driver-check"
        print_line 'Paket adi: '
        ACTION_VALUE="$(read_line_from_user || true)"
        [[ -n "${ACTION_VALUE}" ]] || print_line 'Paket adi bos birakilamaz.\n\n'
        [[ -n "${ACTION_VALUE}" ]] && return 0
        ;;
      5)
        ACTION="printer-guides"
        return 0
        ;;
      6)
        ACTION="kyocera-guide"
        return 0
        ;;
      7)
        ACTION="kyocera-local-status"
        return 0
        ;;
      8)
        ACTION="kyocera-local-prepare"
        return 0
        ;;
      9)
        ACTION="kyocera-local-install"
        return 0
        ;;
      *)
        print_line 'Gecersiz secim. Lutfen 1 ile 9 arasinda bir deger girin.\n\n'
        ;;
    esac
  done
}

parse_args() {
  while (($#)); do
    case "$1" in
      --gui)
        GUI_MODE=1
        ;;
      --printer-report)
        set_action printer-report
        ;;
      --printer-restart)
        set_action printer-restart
        ;;
      --file-share-report)
        set_action file-share-report
        ;;
      --driver-check)
        set_action driver-check
        shift
        [[ $# -gt 0 ]] || fail "--driver-check icin paket adi eksik."
        ACTION_VALUE="$1"
        ;;
      --printer-guides)
        set_action printer-guides
        ;;
      --kyocera-guide)
        set_action kyocera-guide
        ;;
      --kyocera-local-status)
        set_action kyocera-local-status
        ;;
      --kyocera-local-prepare)
        set_action kyocera-local-prepare
        ;;
      --kyocera-local-install)
        set_action kyocera-local-install
        ;;
      --report-file)
        shift
        [[ $# -gt 0 ]] || fail "--report-file icin dosya yolu eksik."
        REPORT_FILE="$1"
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

  if (( GUI_MODE )); then
    if can_use_zenity; then
      collect_gui_action || exit 1
    else
      collect_cli_action || exit 1
    fi
  elif [[ -z "${ACTION}" ]]; then
    if can_use_zenity; then
      collect_gui_action || exit 1
    else
      usage
      exit 1
    fi
  fi

  [[ -n "${ACTION}" ]] || fail "Bir islem secin."

  if ! execute_selected_action; then
    if (( SHOW_GUI_RESULT )); then
      exit 1
    fi
    pause_before_exit
    exit 1
  fi
}

main "$@"
