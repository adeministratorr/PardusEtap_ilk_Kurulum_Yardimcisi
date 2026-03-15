#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/setup_etap23.sh"
ETAP23_RUNTIME_DIR="${ETAP23_RUNTIME_DIR:-${SCRIPT_DIR}}"
export ETAP23_RUNTIME_DIR
STATE_BASE_DIR="${XDG_CONFIG_HOME:-${HOME:-${SCRIPT_DIR}}/.config}"
ETAP23_STATE_DIR="${ETAP23_STATE_DIR:-${STATE_BASE_DIR}/etap23-ilk-kurulum}"
ETAP23_STATE_FILE="${ETAP23_STATE_FILE:-${ETAP23_STATE_DIR}/launcher.conf}"
LAUNCHER_MODE="${LAUNCHER_MODE:-setup}"
BOOTSTRAP_SUDO_PASSWORD_DEFAULT="etap+pardus!"
# Kurulum basinda sudo almak icin kullanilan mevcut parola.
BOOTSTRAP_SUDO_PASSWORD="${BOOTSTRAP_SUDO_PASSWORD:-${BOOTSTRAP_SUDO_PASSWORD_DEFAULT}}"
# setup_etap23.sh ile uyumlu, calisma aninda disaridan verilebilen opsiyonel yeni yonetici parolasi.
ETAPADMIN_PASSWORD_DEFAULT="${ETAPADMIN_PASSWORD_DEFAULT-}"
ETA_TOUCHDRV_FALLBACK_VERSION="${ETA_TOUCHDRV_FALLBACK_VERSION:-0.3.5}"
REMEMBERED_SUDO_PASSWORD="${REMEMBERED_SUDO_PASSWORD:-}"
REMEMBERED_ETAPADMIN_PASSWORD="${REMEMBERED_ETAPADMIN_PASSWORD:-}"
TTY_DEVICE="${TTY_DEVICE:-/dev/tty}"
PAUSE_ON_ERROR_REQUESTED=0
TOUCHDRV_SUMMARY_FILE=""
RUN_REPORT_FILE=""

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

run_with_status() {
  local status

  set +e
  "$@"
  status=$?
  set -e

  return "${status}"
}

prepare_run_report_file() {
  launcher_can_use_zenity || return 0
  [[ -n "${RUN_REPORT_FILE}" ]] && return 0

  RUN_REPORT_FILE="$(mktemp /tmp/etap23-launcher-report.XXXXXX.log)"
  chmod 600 "${RUN_REPORT_FILE}" 2>/dev/null || true
}

cleanup_run_report_file() {
  [[ -n "${RUN_REPORT_FILE}" ]] || return 0
  rm -f "${RUN_REPORT_FILE}" 2>/dev/null || true
  RUN_REPORT_FILE=""
}

show_error_report_if_available() {
  local status="$1"
  local temp_view

  [[ "${status}" -ne 0 ]] || return 0
  [[ -n "${RUN_REPORT_FILE}" && -s "${RUN_REPORT_FILE}" ]] || return 0
  launcher_can_use_zenity || return 0

  temp_view="$(mktemp)"
  {
    printf 'Islem hata ile sonlandi.\n'
    printf 'Arac: %s\n' "$(launcher_mode_label)"
    printf 'Cikis kodu: %s\n\n' "${status}"
    cat "${RUN_REPORT_FILE}"
  } >"${temp_view}"

  zenity --text-info \
    --title="$(launcher_mode_label) Hata Raporu" \
    --width=920 \
    --height=680 \
    --filename="${temp_view}" || true

  rm -f "${temp_view}"
}

finish_with_status() {
  local status="$1"

  if [[ "${status}" -eq 0 ]]; then
    print_line '\nIslem tamamlandi.\n'
  else
    if has_tty; then
      printf '\nHATA: Islem %s cikis kodu ile sonlandi.\n' "${status}" >"${TTY_DEVICE}"
      printf 'Detaylari yukaridaki HATA ve basarisiz adim mesajlarinda kontrol edin.\n' >"${TTY_DEVICE}"
    else
      printf '\nHATA: Islem %s cikis kodu ile sonlandi.\n' "${status}" >&2
      printf 'Detaylari yukaridaki HATA ve basarisiz adim mesajlarinda kontrol edin.\n' >&2
    fi
  fi

  show_error_report_if_available "${status}"

  if [[ "${status}" -ne 0 && "${PAUSE_ON_ERROR_REQUESTED}" == "1" ]]; then
    show_touchdrv_summary_if_available
    cleanup_touchdrv_summary_file
    cleanup_run_report_file
    exit "${status}"
  fi

  show_touchdrv_summary_if_available
  cleanup_touchdrv_summary_file
  cleanup_run_report_file
  pause_before_exit
  exit "${status}"
}

run_main() {
  local status

  if [[ -n "${RUN_REPORT_FILE}" ]]; then
    set +e
    "${MAIN_SCRIPT}" "$@" 2>&1 | tee -a "${RUN_REPORT_FILE}"
    status="${PIPESTATUS[0]}"
    set -e
    return "${status}"
  fi

  run_with_status "${MAIN_SCRIPT}" "$@"
}

# shellcheck disable=SC2329
run_command_with_tty_input() {
  local status

  exec 3<"${TTY_DEVICE}"
  set +e
  "$@" <&3
  status=$?
  set -e
  exec 3<&-

  return "${status}"
}

# shellcheck disable=SC2329
run_command_with_tty_io() {
  local status

  exec 3<>"${TTY_DEVICE}"
  set +e
  "$@" <&3 >&3 2>&1
  status=$?
  set -e
  exec 3>&-

  return "${status}"
}

load_launcher_state() {
  [[ -r "${ETAP23_STATE_FILE}" ]] || return 0

  # shellcheck disable=SC1090
  source "${ETAP23_STATE_FILE}" || true
}

save_launcher_state() {
  local temp_file

  mkdir -p "${ETAP23_STATE_DIR}" || {
    printf 'UYARI: Kayıtlı parola dosyası oluşturulamadı: %s\n' "${ETAP23_STATE_DIR}" >&2
    return 0
  }

  temp_file="$(mktemp "${ETAP23_STATE_FILE}.XXXXXX")"
  cat >"${temp_file}" <<EOF
# ETAP23 ilk kurulum başlatıcısının hatırladığı ayarlar.
REMEMBERED_SUDO_PASSWORD=$(printf '%q' "${REMEMBERED_SUDO_PASSWORD}")
REMEMBERED_ETAPADMIN_PASSWORD=$(printf '%q' "${REMEMBERED_ETAPADMIN_PASSWORD}")
EOF

  mv "${temp_file}" "${ETAP23_STATE_FILE}"
  chmod 600 "${ETAP23_STATE_FILE}" 2>/dev/null || true
}

# shellcheck disable=SC2329
run_main_with_sudo_password() {
  local candidate="$1"
  local status

  [[ -n "${candidate}" ]] || return 1
  if [[ -n "${RUN_REPORT_FILE}" ]]; then
    set +e
    printf '%s\n' "${candidate}" | sudo -S -k -p '' env \
      "${GUI_ENV_ARGS[@]}" \
      "${MAIN_SCRIPT}" "${GUI_ARGS[@]}" 2>&1 | tee -a "${RUN_REPORT_FILE}"
    status="${PIPESTATUS[1]}"
    set -e
    return "${status}"
  fi

  if has_tty; then
    printf '%s\n' "${candidate}" | run_command_with_tty_io sudo -S -k -p '' env \
      "${GUI_ENV_ARGS[@]}" \
      "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
  else
    printf '%s\n' "${candidate}" | sudo -S -k -p '' env \
      "${GUI_ENV_ARGS[@]}" \
      "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
  fi
}

# shellcheck disable=SC2329
run_main_with_sudo_password_capture() {
  local candidate="$1"
  local output_file="$2"

  [[ -n "${candidate}" ]] || return 1
  {
    printf '%s\n' "${candidate}" | sudo -S -k -p '' env \
    "${GUI_ENV_ARGS[@]}" \
      "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
  } >"${output_file}" 2>&1
}

get_gui_session_type() {
  if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
    printf '%s\n' "${XDG_SESSION_TYPE}"
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    printf 'wayland\n'
  else
    printf 'x11\n'
  fi
}

launcher_mode_label() {
  case "${LAUNCHER_MODE}" in
    wine)
      printf 'ETAP Wine Araci'
      ;;
    touchdrv)
      printf 'ETA Dokunmatik Surucu Araci'
      ;;
    touch-calibration)
      printf 'ETA Dokunmatik Kalibrasyon Araci'
      ;;
    eta-kayit-repair)
      printf 'ETA Kayit Duzelt/Sifirla Araci'
      ;;
    *)
      printf 'ETAP23 Ilk Kurulum'
      ;;
  esac
}

build_gui_env_args() {
  local gui_user gui_xauthority

  GUI_ENV_ARGS=()
  gui_user="${USER:-$(id -un 2>/dev/null || true)}"

  GUI_ENV_ARGS+=("ETAP23_GUI_USER=${gui_user}")
  GUI_ENV_ARGS+=("ETAP23_GUI_SESSION_TYPE=$(get_gui_session_type)")
  GUI_ENV_ARGS+=("ETAP23_RUNTIME_DIR=${ETAP23_RUNTIME_DIR}")

  if [[ -n "${DISPLAY:-}" ]]; then
    GUI_ENV_ARGS+=("ETAP23_GUI_DISPLAY=${DISPLAY}")
  fi

  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    GUI_ENV_ARGS+=("ETAP23_GUI_WAYLAND_DISPLAY=${WAYLAND_DISPLAY}")
  fi

  gui_xauthority="${XAUTHORITY:-}"
  if [[ -z "${gui_xauthority}" && -n "${HOME:-}" && -r "${HOME}/.Xauthority" ]]; then
    gui_xauthority="${HOME}/.Xauthority"
  fi
  if [[ -n "${gui_xauthority}" ]]; then
    GUI_ENV_ARGS+=("ETAP23_GUI_XAUTHORITY=${gui_xauthority}")
  fi

  if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    GUI_ENV_ARGS+=("ETAP23_GUI_DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}")
  fi

  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    GUI_ENV_ARGS+=("ETAP23_GUI_XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}")
  fi
}

# shellcheck disable=SC2329
run_main_with_sudo_prompt() {
  local status

  if [[ -n "${RUN_REPORT_FILE}" ]]; then
    set +e
    if has_tty; then
      run_command_with_tty_input sudo -k -p '[sudo] Yonetici parolasi: ' env \
        "${GUI_ENV_ARGS[@]}" \
        "${MAIN_SCRIPT}" "${GUI_ARGS[@]}" 2>&1 | tee -a "${RUN_REPORT_FILE}"
    else
      sudo -k -p '[sudo] Yonetici parolasi: ' env \
        "${GUI_ENV_ARGS[@]}" \
        "${MAIN_SCRIPT}" "${GUI_ARGS[@]}" 2>&1 | tee -a "${RUN_REPORT_FILE}"
    fi
    status="${PIPESTATUS[0]}"
    set -e
    return "${status}"
  fi

  if has_tty; then
    run_command_with_tty_io sudo -k -p '[sudo] Yonetici parolasi: ' env \
      "${GUI_ENV_ARGS[@]}" \
      "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
  else
    sudo -k -p '[sudo] Yonetici parolasi: ' env \
      "${GUI_ENV_ARGS[@]}" \
      "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
  fi
}

try_bootstrap_sudo() {
  command -v sudo >/dev/null 2>&1 || return 1

  if run_with_status run_main_with_sudo_password "${REMEMBERED_SUDO_PASSWORD}"; then
    printf 'Bilgi: Hatirlanan yonetici parolasi ile yetki alindi.\n'
    return 0
  fi

  if [[ "${BOOTSTRAP_SUDO_PASSWORD}" != "${REMEMBERED_SUDO_PASSWORD}" ]] && \
    run_with_status run_main_with_sudo_password "${BOOTSTRAP_SUDO_PASSWORD}"; then
    printf 'Bilgi: Varsayilan baslangic parolasi ile yetki alindi.\n'
    return 0
  fi

  return 1
}

launcher_can_use_zenity() {
  command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

wine_action_is_informational() {
  local arg

  for arg in "${GUI_ARGS[@]:-}"; do
    case "${arg}" in
      --wine-check|--wine-version)
        return 0
        ;;
    esac
  done

  return 1
}

wine_action_dialog_title() {
  local arg

  for arg in "${GUI_ARGS[@]:-}"; do
    case "${arg}" in
      --wine-check)
        printf 'ETAP Wine Durum Kontrolu\n'
        return 0
        ;;
      --wine-version)
        printf 'ETAP Wine Surum Bilgisi\n'
        return 0
        ;;
    esac
  done

  printf 'ETAP Wine Bilgisi\n'
}

run_main_capture_output() {
  local output_file="$1"
  run_with_status "${MAIN_SCRIPT}" "${GUI_ARGS[@]}" >"${output_file}" 2>&1
}

# shellcheck disable=SC2329
run_main_with_sudo_prompt_capture() {
  local output_file="$1"

  if has_tty; then
    {
      run_command_with_tty_input sudo -k -p '[sudo] Yonetici parolasi: ' env \
        "${GUI_ENV_ARGS[@]}" \
        "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
    } >"${output_file}" 2>&1
  else
    {
      sudo -k -p '[sudo] Yonetici parolasi: ' env \
        "${GUI_ENV_ARGS[@]}" \
        "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
    } >"${output_file}" 2>&1
  fi
}

try_bootstrap_sudo_capture() {
  local output_file="$1"

  command -v sudo >/dev/null 2>&1 || return 1

  if run_with_status run_main_with_sudo_password_capture "${REMEMBERED_SUDO_PASSWORD}" "${output_file}"; then
    return 0
  fi

  if [[ "${BOOTSTRAP_SUDO_PASSWORD}" != "${REMEMBERED_SUDO_PASSWORD}" ]] && \
    run_with_status run_main_with_sudo_password_capture "${BOOTSTRAP_SUDO_PASSWORD}" "${output_file}"; then
    return 0
  fi

  return 1
}

run_main_capture_with_privileges() {
  local output_file="$1"

  if [[ "${EUID}" -eq 0 ]]; then
    run_main_capture_output "${output_file}"
    return "$?"
  fi

  if command -v sudo >/dev/null 2>&1; then
    if try_bootstrap_sudo_capture "${output_file}"; then
      return "$?"
    fi

    run_with_status run_main_with_sudo_prompt_capture "${output_file}"
    return "$?"
  fi

  if command -v pkexec >/dev/null 2>&1; then
    run_with_status pkexec env "${GUI_ENV_ARGS[@]}" "${MAIN_SCRIPT}" "${GUI_ARGS[@]}" >"${output_file}" 2>&1
    return "$?"
  fi

  printf 'HATA: Bu sistemde ne sudo ne de pkexec bulundu.\n' >"${output_file}"
  return 1
}

show_wine_informational_dialog() {
  local status="$1"
  local output_file="$2"
  local title body temp_view

  title="$(wine_action_dialog_title)"
  temp_view="$(mktemp)"

  if [[ "${status}" -eq 0 ]]; then
    body="Islem tamamlandi. Ayrintilar asagida."
  else
    body="Islem hata veya uyari ile sonlandi. Ayrintilar asagida."
  fi

  {
    printf '%s\n\n' "${body}"
    if [[ -s "${output_file}" ]]; then
      cat "${output_file}"
    else
      printf 'Cikti uretilemedi.\n'
    fi
  } >"${temp_view}"

  zenity --text-info \
    --title="${title}" \
    --width=900 \
    --height=640 \
    --filename="${temp_view}" || true

  rm -f "${temp_view}"
}

handle_wine_informational_loop() {
  local status output_file

  [[ "${LAUNCHER_MODE}" == "wine" ]] || return 1
  launcher_can_use_zenity || return 1

  while true; do
    if [[ "${#GUI_ARGS[@]}" -eq 1 && "${GUI_ARGS[0]}" == "--pause-on-error" ]]; then
      if ! collect_wine_gui_args; then
        print_line 'Islem iptal edildi.\n'
        pause_before_exit
        exit 0
      fi
    fi

    if ! wine_action_is_informational; then
      return 1
    fi

    output_file="$(mktemp)"
    run_main_capture_with_privileges "${output_file}"
    status="$?"
    show_wine_informational_dialog "${status}" "${output_file}"
    rm -f "${output_file}"

    GUI_ARGS=(--pause-on-error)
  done
}

has_choice() {
  local needle="$1"
  local item

  for item in "${CHOICES[@]:-}"; do
    [[ "${item}" == "${needle}" ]] && return 0
  done
  return 1
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

touchdrv_check_requested() {
  local arg

  for arg in "${GUI_ARGS[@]:-}"; do
    [[ "${arg}" == "--touchdrv-check" ]] && return 0
  done
  return 1
}

prepare_touchdrv_summary_file() {
  if ! touchdrv_check_requested; then
    return 0
  fi

  TOUCHDRV_SUMMARY_FILE="$(mktemp /tmp/etap23-touchdrv-summary.XXXXXX)"
  chmod 600 "${TOUCHDRV_SUMMARY_FILE}" 2>/dev/null || true
  GUI_ENV_ARGS+=("ETAP23_USER_SUMMARY_FILE=${TOUCHDRV_SUMMARY_FILE}")
}

show_touchdrv_summary_if_available() {
  [[ -n "${TOUCHDRV_SUMMARY_FILE}" && -s "${TOUCHDRV_SUMMARY_FILE}" ]] || return 0

  if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    zenity --text-info \
      --title="Dokunmatik Surucu Kontrol Ozeti" \
      --width=720 \
      --height=420 \
      --filename="${TOUCHDRV_SUMMARY_FILE}" || true
    return 0
  fi

  print_line '\nDokunmatik Surucu Kontrol Ozeti\n'
  print_line '--------------------------------\n'
  while IFS= read -r line; do
    print_line "${line}\n"
  done <"${TOUCHDRV_SUMMARY_FILE}"
}

cleanup_touchdrv_summary_file() {
  [[ -n "${TOUCHDRV_SUMMARY_FILE}" ]] || return 0
  rm -f "${TOUCHDRV_SUMMARY_FILE}" 2>/dev/null || true
  TOUCHDRV_SUMMARY_FILE=""
}

FIRST_INSTALL_CHECKLIST_SELECT_ALL_LABEL="Tumunu Sec"
FIRST_INSTALL_CHECKLIST_CLEAR_ALL_LABEL="Tumunu Kaldir"
FIRST_INSTALL_CHECKLIST_CODES=()
FIRST_INSTALL_CHECKLIST_LABELS=()
FIRST_INSTALL_CHECKLIST_STATES=()

init_first_install_checklist() {
  FIRST_INSTALL_CHECKLIST_CODES=(
    hostname
    remove_ogrenci
    remove_ogretmen
    eag
    eta_qr
    eta_touch
    wine
    wine_vulkan
    screensaver
    idle_shutdown
    scheduled_shutdown
    admin_password
    eta_kayit
  )

  FIRST_INSTALL_CHECKLIST_LABELS=(
    "Tahta adini degistir"
    "ogrenci kullanicisini sil"
    "ogretmen kullanicisini sil"
    "e-ag-client paketini kur"
    "eta-qr-login paketini kur"
    "eta-touchdrv paketini kur veya guncelle"
    "Wine ve winetricks kur"
    "dxvk ve vkd3d kur (Vulkan gerektirir)"
    "Ekran koruyucu ve DPMS'i kapat"
    "Bosta kalinca otomatik kapat"
    "Her gun belirli saatte kapat"
    "etapadmin parolasini degistir"
    "Kurulum sonunda ETA Kayit uygulamasini ac"
  )

  FIRST_INSTALL_CHECKLIST_STATES=(
    TRUE
    TRUE
    TRUE
    TRUE
    TRUE
    TRUE
    TRUE
    FALSE
    TRUE
    TRUE
    TRUE
    TRUE
    TRUE
  )
}

set_first_install_checklist_states() {
  local state="$1"
  local index

  for index in "${!FIRST_INSTALL_CHECKLIST_STATES[@]}"; do
    FIRST_INSTALL_CHECKLIST_STATES[index]="${state}"
  done
}

sync_first_install_checklist_states_from_choices() {
  local index selected code

  for index in "${!FIRST_INSTALL_CHECKLIST_CODES[@]}"; do
    code="${FIRST_INSTALL_CHECKLIST_CODES[$index]}"
    FIRST_INSTALL_CHECKLIST_STATES[index]="FALSE"

    for selected in "${CHOICES[@]:-}"; do
      if [[ "${selected}" == "${code}" ]]; then
        FIRST_INSTALL_CHECKLIST_STATES[index]="TRUE"
        break
      fi
    done
  done
}

prompt_first_install_checklist() {
  local -a checklist_args
  local index

  checklist_args=(
    --list
    --checklist
    --title="ETAP23 İlk Kurulum"
    --text="Kurulacak adimlari secin"
    --width=820
    --height=520
    "--separator=|"
    --ok-label="Devam Et"
    --cancel-label="Iptal"
    --extra-button="${FIRST_INSTALL_CHECKLIST_SELECT_ALL_LABEL}"
    --extra-button="${FIRST_INSTALL_CHECKLIST_CLEAR_ALL_LABEL}"
    --column="Sec"
    --column="Kod"
    --column="Aciklama"
  )

  for index in "${!FIRST_INSTALL_CHECKLIST_CODES[@]}"; do
    checklist_args+=(
      "${FIRST_INSTALL_CHECKLIST_STATES[$index]}"
      "${FIRST_INSTALL_CHECKLIST_CODES[$index]}"
      "${FIRST_INSTALL_CHECKLIST_LABELS[$index]}"
    )
  done

  zenity "${checklist_args[@]}"
}

collect_gui_args() {
  local checklist board_name idle_minutes shutdown_time sudo_password password1 password2 eta_kayit_kurum_kodu eta_kayit_sinif form_values
  local current_board_name default_idle_minutes default_shutdown_time default_eta_kurum_kodu default_eta_sinif
  local effective_etapadmin_password skip_etapadmin_password_step
  local form_text form_separator checklist_status state_dirty

  GUI_ARGS=(--non-interactive --pause-on-error)
  current_board_name="${BOARD_NAME:-$(hostnamectl --static 2>/dev/null || hostname)}"
  default_idle_minutes="${IDLE_SHUTDOWN_MINUTES:-90}"
  default_shutdown_time="${SCHEDULED_SHUTDOWN_TIME:-17:20}"
  default_eta_kurum_kodu="${ETA_KAYIT_KURUM_KODU:-216183}"
  default_eta_sinif="${ETA_KAYIT_SINIF:-${current_board_name}}"
  form_separator=$'\x1f'
  state_dirty=0
  init_first_install_checklist

  while true; do
    set +e
    checklist="$(prompt_first_install_checklist)"
    checklist_status=$?
    set -e

    if [[ "${checklist}" == "${FIRST_INSTALL_CHECKLIST_SELECT_ALL_LABEL}" ]]; then
      set_first_install_checklist_states TRUE
      continue
    fi

    if [[ "${checklist}" == "${FIRST_INSTALL_CHECKLIST_CLEAR_ALL_LABEL}" ]]; then
      set_first_install_checklist_states FALSE
      continue
    fi

    if [[ "${checklist_status}" -ne 0 ]]; then
      return 1
    fi

    CHOICES=()
    if [[ -n "${checklist}" ]]; then
      IFS='|' read -r -a CHOICES <<<"${checklist}"
    fi
    sync_first_install_checklist_states_from_choices
    break
  done

  while true; do
    if [[ -n "${REMEMBERED_SUDO_PASSWORD}" ]]; then
      form_text="Secili adimlar icin degerleri duzenleyin.\nMevcut yonetici parolasi alani bos birakilirsa kayitli sudo parolasi kullanilacaktir."
    else
      form_text="Secili adimlar icin degerleri duzenleyin.\nMevcut yonetici parolasi alani bos birakilirsa varsayilan sudo parolasi (${BOOTSTRAP_SUDO_PASSWORD}) kullanilacaktir."
    fi
    if [[ -n "${REMEMBERED_ETAPADMIN_PASSWORD}" ]]; then
      form_text="${form_text}\nYeni etapadmin parolasi alanlari bossa kayitli parola kullanilacaktir."
    elif [[ -n "${ETAPADMIN_PASSWORD_DEFAULT}" ]]; then
      form_text="${form_text}\nYeni etapadmin parolasi alanlari bossa varsayilan parola kullanilacaktir."
    else
      form_text="${form_text}\nYeni etapadmin parolasi alanlari bos birakilirsa uyari gosterilip parola degistirme adimi atlanacaktir."
    fi

    form_values="$(zenity --forms \
      --title="ETAP23 Ayarlar" \
      --text="${form_text}" \
      --width=720 \
      --separator="${form_separator}" \
      --add-entry="Tahta Adı (boşsa: ${current_board_name})" \
      --add-entry="Boşta Kapanma (dk) (boşsa: ${default_idle_minutes})" \
      --add-entry="Günlük Kapanma (SS:DD) (boşsa: ${default_shutdown_time})" \
      --add-entry="ETA Kayıt Kurum Kodu (boşsa: ${default_eta_kurum_kodu})" \
      --add-entry="ETA Kayıt Sınıf (boşsa: ${board_name:-${current_board_name}})" \
      --add-password="Mevcut Yönetici Parolası" \
      --add-password="Yeni etapadmin Parolası" \
      --add-password="Parola Tekrar")" || return 1

    IFS="${form_separator}" read -r board_name idle_minutes shutdown_time eta_kayit_kurum_kodu eta_kayit_sinif sudo_password password1 password2 <<<"${form_values}"
    board_name="${board_name:-${current_board_name}}"
    idle_minutes="${idle_minutes:-${default_idle_minutes}}"
    shutdown_time="${shutdown_time:-${default_shutdown_time}}"
    eta_kayit_kurum_kodu="${eta_kayit_kurum_kodu:-${default_eta_kurum_kodu}}"
    eta_kayit_sinif="${eta_kayit_sinif:-${default_eta_sinif}}"
    effective_etapadmin_password=""
    skip_etapadmin_password_step=0

    if [[ -n "${sudo_password}" ]]; then
      REMEMBERED_SUDO_PASSWORD="${sudo_password}"
      state_dirty=1
    fi

    if has_choice hostname && [[ -z "${board_name}" ]]; then
      zenity --error --title="Tahta Adı Hatası" --text="Tahta adı boş bırakılamaz." || true
      continue
    fi

    if has_choice idle_shutdown && [[ ! "${idle_minutes}" =~ ^[0-9]+$ || "${idle_minutes}" -le 0 ]]; then
      zenity --error --title="Boşta Kapanma Hatası" --text="Boşta kapanma süresi sıfırdan büyük bir sayı olmalıdır." || true
      continue
    fi

    if has_choice scheduled_shutdown && [[ ! "${shutdown_time}" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
      zenity --error --title="Kapanma Saati Hatası" --text="Günlük kapanma saati SS:DD biçiminde olmalıdır." || true
      continue
    fi

    if has_choice eta_kayit && [[ ! "${eta_kayit_kurum_kodu}" =~ ^[0-9]+$ ]]; then
      zenity --error --title="Kurum Kodu Hatası" --text="Lütfen yalnızca rakamlardan oluşan bir kurum kodu girin." || true
      continue
    fi

    if has_choice admin_password; then
      if [[ -z "${password1}" && -z "${password2}" ]]; then
        if [[ -n "${REMEMBERED_ETAPADMIN_PASSWORD}" ]]; then
          effective_etapadmin_password="${REMEMBERED_ETAPADMIN_PASSWORD}"
        elif [[ -n "${ETAPADMIN_PASSWORD_DEFAULT}" ]]; then
          effective_etapadmin_password="${ETAPADMIN_PASSWORD_DEFAULT}"
        else
          skip_etapadmin_password_step=1
          zenity --warning \
            --title="Parola Adimi Atlaniyor" \
            --text="Yeni etapadmin parolasi kayitli olmadigi icin parola degistirme adimi atlanacak." || true
        fi
      elif [[ -z "${password1}" || -z "${password2}" ]]; then
        zenity --error --title="Parola Hatası" --text="Yeni parola giriyorsanız iki alanı da doldurun." || true
        continue
      elif [[ "${password1}" != "${password2}" ]]; then
        zenity --error --title="Parola Hatası" --text="Girilen parolalar eşleşmiyor." || true
        continue
      else
        effective_etapadmin_password="${password1}"
        REMEMBERED_ETAPADMIN_PASSWORD="${effective_etapadmin_password}"
        state_dirty=1
      fi
    fi

    break
  done

  if has_choice hostname; then
    GUI_ARGS+=(--change-hostname --board-name "${board_name}")
  else
    GUI_ARGS+=(--skip-hostname)
  fi

  if has_choice remove_ogrenci; then
    GUI_ARGS+=(--remove-ogrenci)
  else
    GUI_ARGS+=(--keep-ogrenci)
  fi

  if has_choice remove_ogretmen; then
    GUI_ARGS+=(--remove-ogretmen)
  else
    GUI_ARGS+=(--keep-ogretmen)
  fi

  if has_choice eag; then
    GUI_ARGS+=(--install-eag-client)
  else
    GUI_ARGS+=(--skip-eag-client)
  fi

  if has_choice eta_qr; then
    GUI_ARGS+=(--install-eta-qr-login)
  else
    GUI_ARGS+=(--skip-eta-qr-login)
  fi

  if has_choice eta_touch; then
    GUI_ARGS+=(--install-eta-touchdrv)
  else
    GUI_ARGS+=(--skip-eta-touchdrv)
  fi

  if has_choice wine; then
    GUI_ARGS+=(--install-wine)
    if has_choice wine_vulkan; then
      zenity --info \
        --title="Vulkan Bilgilendirmesi" \
        --width=420 \
        --text="dxvk ve vkd3d, Vulkan gerektirir.\nEski Intel grafiklerde sorun yaşarsanız bu seçeneği kapatın." || true
      GUI_ARGS+=(--enable-wine-vulkan)
    else
      GUI_ARGS+=(--disable-wine-vulkan)
    fi
  else
    GUI_ARGS+=(--skip-wine --disable-wine-vulkan)
  fi

  if has_choice screensaver; then
    GUI_ARGS+=(--disable-screensaver)
  else
    GUI_ARGS+=(--keep-screensaver)
  fi

  if has_choice idle_shutdown; then
    GUI_ARGS+=(--enable-idle-shutdown --idle-shutdown-minutes "${idle_minutes}")
  else
    GUI_ARGS+=(--disable-idle-shutdown)
  fi

  if has_choice scheduled_shutdown; then
    GUI_ARGS+=(--enable-scheduled-shutdown --scheduled-shutdown "${shutdown_time}")
  else
    GUI_ARGS+=(--disable-scheduled-shutdown)
  fi

  if has_choice admin_password && [[ "${skip_etapadmin_password_step}" -eq 0 ]]; then
    GUI_ARGS+=(
      --change-etapadmin-password
      --etapadmin-password "${effective_etapadmin_password}"
    )
  else
    GUI_ARGS+=(--skip-etapadmin-password)
  fi

  if has_choice eta_kayit; then
    if [[ -z "${eta_kayit_sinif//[[:space:]]/}" ]]; then
      eta_kayit_sinif="${board_name}"
    fi
    GUI_ARGS+=(--open-eta-kayit --eta-kayit-kurum-kodu "${eta_kayit_kurum_kodu}" --eta-kayit-sinif "${eta_kayit_sinif}")
  else
    GUI_ARGS+=(--skip-eta-kayit)
  fi

  if [[ "${state_dirty}" -eq 1 ]]; then
    save_launcher_state
  fi
}

collect_touchdrv_gui_args() {
  local selection

  selection="$(zenity --list \
    --radiolist \
    --title="Dokunmatik Surucu Araci" \
    --text="Yapmak istediginiz islemi secin" \
    --width=760 \
    --height=360 \
    --column="Sec" \
    --column="Kod" \
    --column="Aciklama" \
    TRUE touchdrv_upgrade "Tum sistemi ve Dokunmatik Surucuyu Guncelle" \
    FALSE touchdrv_only_upgrade "Tum sistemi degil yalnizca Dokunmatik Surucusunu Guncelle" \
    FALSE touchdrv_check "Dokunmatik Surucusunu Kontrol Et" \
    FALSE touchdrv_rollback "Eski Dokunmatik Surucusunu Geri Yukle (${ETA_TOUCHDRV_FALLBACK_VERSION})")" || return 1

  GUI_ARGS=(--non-interactive --pause-on-error)

  case "${selection}" in
    touchdrv_upgrade)
      GUI_ARGS+=(--touchdrv-upgrade)
      ;;
    touchdrv_only_upgrade)
      GUI_ARGS+=(--touchdrv-only-upgrade)
      ;;
    touchdrv_check)
      GUI_ARGS+=(--touchdrv-check)
      ;;
    touchdrv_rollback)
      GUI_ARGS+=(--touchdrv-rollback)
      ;;
    *)
      return 1
      ;;
  esac
}

collect_touchdrv_cli_args() {
  local choice

  while true; do
    print_line 'Dokunmatik Surucu Araci\n'
    print_line '  1) Tum sistemi ve Dokunmatik Surucuyu Guncelle\n'
    print_line '  2) Tum sistemi degil yalnizca Dokunmatik Surucusunu Guncelle\n'
    print_line '  3) Dokunmatik Surucusunu Kontrol Et\n'
    print_line "  4) Eski Dokunmatik Surucusunu Geri Yukle (${ETA_TOUCHDRV_FALLBACK_VERSION})\n"
    print_line 'Seciminiz [1]: '
    choice="$(read_line_from_user || true)"
    choice="${choice:-1}"

    GUI_ARGS=(--non-interactive --pause-on-error)

    case "${choice}" in
      1)
        GUI_ARGS+=(--touchdrv-upgrade)
        return 0
        ;;
      2)
        GUI_ARGS+=(--touchdrv-only-upgrade)
        return 0
        ;;
      3)
        GUI_ARGS+=(--touchdrv-check)
        return 0
        ;;
      4)
        GUI_ARGS+=(--touchdrv-rollback)
        return 0
        ;;
      *)
        print_line 'Gecersiz secim. Lutfen 1, 2, 3 veya 4 girin.\n\n'
        ;;
    esac
  done
}

collect_touch_calibration_gui_args() {
  local selection

  selection="$(zenity --list \
    --radiolist \
    --title="Dokunmatik Kalibrasyon Araci" \
    --text="Yapmak istediginiz islemi secin" \
    --width=760 \
    --height=320 \
    --column="Sec" \
    --column="Kod" \
    --column="Aciklama" \
    TRUE touch_calibration_start "Dokunmatik Kalibrasyonunu Baslat" \
    FALSE touch_calibration_status "Kalibrasyon Durumunu Goster" \
    FALSE touch_calibration_reset "Kayitli Kalibrasyonu Sifirla")" || return 1

  GUI_ARGS=(--non-interactive --pause-on-error)

  case "${selection}" in
    touch_calibration_start)
      GUI_ARGS+=(--touch-calibration-start)
      ;;
    touch_calibration_status)
      GUI_ARGS+=(--touch-calibration-status)
      ;;
    touch_calibration_reset)
      GUI_ARGS+=(--touch-calibration-reset)
      ;;
    *)
      return 1
      ;;
  esac
}

collect_touch_calibration_cli_args() {
  local choice

  while true; do
    print_line 'Dokunmatik Kalibrasyon Araci\n'
    print_line '  1) Dokunmatik Kalibrasyonunu Baslat\n'
    print_line '  2) Kalibrasyon Durumunu Goster\n'
    print_line '  3) Kayitli Kalibrasyonu Sifirla\n'
    print_line 'Seciminiz [1]: '
    choice="$(read_line_from_user || true)"
    choice="${choice:-1}"

    GUI_ARGS=(--non-interactive --pause-on-error)

    case "${choice}" in
      1)
        GUI_ARGS+=(--touch-calibration-start)
        return 0
        ;;
      2)
        GUI_ARGS+=(--touch-calibration-status)
        return 0
        ;;
      3)
        GUI_ARGS+=(--touch-calibration-reset)
        return 0
        ;;
      *)
        print_line 'Gecersiz secim. Lutfen 1, 2 veya 3 girin.\n\n'
        ;;
    esac
  done
}

collect_eta_kayit_repair_gui_args() {
  local selection

  selection="$(zenity --list \
    --radiolist \
    --title="ETA Kayit duzelt/sifirla" \
    --text="Ahenk kaydini temizlemek veya temizleyip yeniden kurmak icin islemi secin" \
    --width=780 \
    --height=320 \
    --column="Sec" \
    --column="Kod" \
    --column="Aciklama" \
    TRUE eta_kayit_repair "eta-register kur/guncelle, ahenk kaydini temizle" \
    FALSE eta_kayit_repair_reinstall "Ayni islemi yap ve sonunda ahenk paketini yeniden kur")" || return 1

  GUI_ARGS=(--non-interactive --pause-on-error)

  case "${selection}" in
    eta_kayit_repair)
      GUI_ARGS+=(--eta-kayit-repair)
      ;;
    eta_kayit_repair_reinstall)
      GUI_ARGS+=(--eta-kayit-repair-reinstall-ahenk)
      ;;
    *)
      return 1
      ;;
  esac
}

collect_eta_kayit_repair_cli_args() {
  local choice

  while true; do
    print_line "$(launcher_mode_label)\n"
    print_line '  1) eta-register kur/guncelle, ahenk kaydini temizle\n'
    print_line '  2) Ayni islemi yap ve sonunda ahenk paketini yeniden kur\n'
    print_line 'Seciminiz [1]: '
    choice="$(read_line_from_user || true)"
    choice="${choice:-1}"

    GUI_ARGS=(--non-interactive --pause-on-error)

    case "${choice}" in
      1)
        GUI_ARGS+=(--eta-kayit-repair)
        return 0
        ;;
      2)
        GUI_ARGS+=(--eta-kayit-repair-reinstall-ahenk)
        return 0
        ;;
      *)
        print_line 'Gecersiz secim. Lutfen 1 veya 2 girin.\n\n'
        ;;
    esac
  done
}

validate_wine_prefix_name() {
  [[ "$1" =~ ^[^/]+$ ]]
}

validate_wine_target_user() {
  [[ -z "$1" || "$1" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]
}

trim_surrounding_whitespace() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "${value}"
}

prompt_wine_gui_form() {
  local title="$1"
  local text="$2"
  local default_user="$3"
  local default_prefix="$4"
  local default_windows="$5"
  local form_separator=$'\x1f'
  local form_values target_user prefix_name windows_version

  while true; do
    form_values="$(zenity --forms \
      --title="${title}" \
      --text="${text}" \
      --width=680 \
      --separator="${form_separator}" \
      --add-entry="Hedef Kullanici (bossa: otomatik)" \
      --add-entry="Wine Prefix Adi (bossa: ${default_prefix})" \
      --add-entry="Windows Surumu (bossa: ${default_windows})")" || return 1

    IFS="${form_separator}" read -r target_user prefix_name windows_version <<<"${form_values}"
    target_user="$(trim_surrounding_whitespace "${target_user}")"
    prefix_name="$(trim_surrounding_whitespace "${prefix_name}")"
    windows_version="$(trim_surrounding_whitespace "${windows_version}")"

    WINE_GUI_TARGET_USER="${target_user}"
    WINE_GUI_PREFIX_NAME="${prefix_name:-${default_prefix}}"
    WINE_GUI_WINDOWS_VERSION="${windows_version:-${default_windows}}"

    if ! validate_wine_target_user "${WINE_GUI_TARGET_USER}"; then
      zenity --error --title="Kullanici Hatasi" --text="Kullanici adi bos olabilir veya yalnizca harf, rakam, tire ve alt cizgi icerebilir." || true
      continue
    fi

    if ! validate_wine_prefix_name "${WINE_GUI_PREFIX_NAME}"; then
      zenity --error --title="Wine Prefix Hatasi" --text="Wine prefix adi tek bir klasor adi olmalidir." || true
      continue
    fi

    if [[ -z "${WINE_GUI_WINDOWS_VERSION}" ]]; then
      zenity --error --title="Windows Surumu Hatasi" --text="Windows surumu bos birakilamaz." || true
      continue
    fi

    return 0
  done
}

prompt_wine_cli_values() {
  local prompt_user="$1"
  local prompt_windows="$2"
  local default_user="$3"
  local default_prefix="$4"
  local default_windows="$5"
  local target_user prefix_name windows_version

  while true; do
    if [[ "${prompt_user}" == "1" ]]; then
      print_line "Hedef kullanici (bossa otomatik${default_user:+: ${default_user}}): "
      target_user="$(read_line_from_user || true)"
      target_user="$(trim_surrounding_whitespace "${target_user}")"
    else
      target_user=""
    fi

    print_line "Wine prefix adi [${default_prefix}]: "
    prefix_name="$(read_line_from_user || true)"
    prefix_name="$(trim_surrounding_whitespace "${prefix_name}")"
    prefix_name="${prefix_name:-${default_prefix}}"

    if [[ "${prompt_windows}" == "1" ]]; then
      print_line "Windows surumu [${default_windows}]: "
      windows_version="$(read_line_from_user || true)"
      windows_version="$(trim_surrounding_whitespace "${windows_version}")"
      windows_version="${windows_version:-${default_windows}}"
    else
      windows_version="${default_windows}"
    fi

    if ! validate_wine_target_user "${target_user}"; then
      print_line 'Gecersiz kullanici adi.\n\n'
      continue
    fi

    if ! validate_wine_prefix_name "${prefix_name}"; then
      print_line 'Wine prefix adi tek bir klasor adi olmalidir.\n\n'
      continue
    fi

    if [[ -z "${windows_version}" ]]; then
      print_line 'Windows surumu bos birakilamaz.\n\n'
      continue
    fi

    WINE_GUI_TARGET_USER="${target_user}"
    WINE_GUI_PREFIX_NAME="${prefix_name}"
    WINE_GUI_WINDOWS_VERSION="${windows_version}"
    return 0
  done
}

append_wine_common_args() {
  GUI_ARGS+=(--wine-prefix-name "${WINE_GUI_PREFIX_NAME}")

  if [[ -n "${WINE_GUI_TARGET_USER}" ]]; then
    GUI_ARGS+=(--wine-user "${WINE_GUI_TARGET_USER}")
  fi
}

collect_wine_gui_args() {
  local selection
  local default_user="${USER:-}"
  local default_prefix="${WINE_PREFIX_NAME:-.wine-etap}"
  local default_windows="${WINE_WINDOWS_VERSION:-win10}"

  selection="$(zenity --list \
    --radiolist \
    --title="ETAP Wine Araci" \
    --text="Yapmak istediginiz Wine islemini secin" \
    --width=820 \
    --height=430 \
    --column="Sec" \
    --column="Kod" \
    --column="Aciklama" \
    TRUE wine_install "Wine ve winetricks kur veya guncelle" \
    FALSE wine_install_vulkan "Wine kur veya guncelle, dxvk ve vkd3d de ekle" \
    FALSE wine_check "Wine durumunu kontrol et" \
    FALSE wine_version "Wine ve winetricks surumlerini goster" \
    FALSE winecfg "winecfg ac" \
    FALSE wine_rebuild_prefix "Wine prefix klasorunu yeniden olustur" \
    FALSE wine_remove "Wine paketlerini ve ETAP baslaticilarini kaldir" \
    FALSE wine_remove_purge "Wine paketlerini kaldir ve prefix klasorlerini de sil")" || return 1

  GUI_ARGS=(--non-interactive --pause-on-error)
  WINE_GUI_TARGET_USER=""
  WINE_GUI_PREFIX_NAME="${default_prefix}"
  WINE_GUI_WINDOWS_VERSION="${default_windows}"

  case "${selection}" in
    wine_install|wine_install_vulkan)
      prompt_wine_gui_form \
        "ETAP Wine Araci Ayarlari" \
        "Wine kurulumunda kullanilacak prefix ve Windows surumunu girin.\nHedef kullanici alani bilgilendirme amaclidir; kurulum tum ev dizinlerindeki kullanicilar icin bootstrap dener." \
        "${default_user}" \
        "${default_prefix}" \
        "${default_windows}" || return 1
      GUI_ARGS+=(--wine-install --wine-windows-version "${WINE_GUI_WINDOWS_VERSION}")
      append_wine_common_args
      if [[ "${selection}" == "wine_install_vulkan" ]]; then
        zenity --info \
          --title="Vulkan Bilgilendirmesi" \
          --width=420 \
          --text="dxvk ve vkd3d, Vulkan gerektirir.\nEski Intel grafiklerde sorun yasarsaniz bu secenegi kapatip tekrar deneyin." || true
        GUI_ARGS+=(--enable-wine-vulkan)
      else
        GUI_ARGS+=(--disable-wine-vulkan)
      fi
      ;;
    wine_check)
      GUI_ARGS+=(--wine-check)
      ;;
    wine_version)
      GUI_ARGS+=(--wine-version)
      ;;
    winecfg)
      prompt_wine_gui_form \
        "winecfg Ayarlari" \
        "Aktif grafik oturumundaki kullanici icin winecfg acilir.\nGerekirse hedef kullanici ve prefix adini acikca belirtin." \
        "${default_user}" \
        "${default_prefix}" \
        "${default_windows}" || return 1
      GUI_ARGS+=(--winecfg)
      append_wine_common_args
      ;;
    wine_rebuild_prefix)
      prompt_wine_gui_form \
        "Wine Prefix Yeniden Olustur" \
        "Secilen kullanicinin Wine prefix klasoru silinip yeniden olusturulacak." \
        "${default_user}" \
        "${default_prefix}" \
        "${default_windows}" || return 1
      GUI_ARGS+=(--wine-rebuild-prefix --wine-windows-version "${WINE_GUI_WINDOWS_VERSION}")
      append_wine_common_args
      ;;
    wine_remove)
      if ! zenity --question \
        --title="Wine Kaldir" \
        --width=420 \
        --text="Wine paketleri ve ETAP baslaticilari kaldirilacak.\nDevam etmek istiyor musunuz?"; then
        return 1
      fi
      GUI_ARGS+=(--wine-remove)
      ;;
    wine_remove_purge)
      prompt_wine_gui_form \
        "Wine Kaldir ve Prefixleri Sil" \
        "Wine paketleri kaldirilacak. Hedef kullanici bos birakilirsa tum ev dizinlerindeki Wine prefixleri de silinir." \
        "" \
        "${default_prefix}" \
        "${default_windows}" || return 1
      if ! zenity --question \
        --title="Wine ve Prefixleri Kaldir" \
        --width=500 \
        --text="Wine paketleri kaldirilacak ve secilen prefix klasorleri silinecek.\nBu islem geri alinmaz. Devam edilsin mi?"; then
        return 1
      fi
      GUI_ARGS+=(--wine-remove-purge-prefixes)
      append_wine_common_args
      ;;
    *)
      return 1
      ;;
  esac
}

collect_wine_cli_args() {
  local choice
  local default_user="${USER:-}"
  local default_prefix="${WINE_PREFIX_NAME:-.wine-etap}"
  local default_windows="${WINE_WINDOWS_VERSION:-win10}"

  while true; do
    print_line 'ETAP Wine Araci\n'
    print_line '  1) Wine ve winetricks kur veya guncelle\n'
    print_line '  2) Wine kur veya guncelle, dxvk ve vkd3d de ekle\n'
    print_line '  3) Wine durumunu kontrol et\n'
    print_line '  4) Wine ve winetricks surumlerini goster\n'
    print_line '  5) winecfg ac\n'
    print_line '  6) Wine prefix klasorunu yeniden olustur\n'
    print_line '  7) Wine paketlerini ve ETAP baslaticilarini kaldir\n'
    print_line '  8) Wine paketlerini kaldir ve prefix klasorlerini de sil\n'
    print_line 'Seciminiz [1]: '
    choice="$(read_line_from_user || true)"
    choice="${choice:-1}"

    GUI_ARGS=(--non-interactive --pause-on-error)
    WINE_GUI_TARGET_USER=""
    WINE_GUI_PREFIX_NAME="${default_prefix}"
    WINE_GUI_WINDOWS_VERSION="${default_windows}"

    case "${choice}" in
      1)
        prompt_wine_cli_values 0 1 "${default_user}" "${default_prefix}" "${default_windows}"
        GUI_ARGS+=(--wine-install --wine-windows-version "${WINE_GUI_WINDOWS_VERSION}" --disable-wine-vulkan)
        append_wine_common_args
        return 0
        ;;
      2)
        print_line 'Bilgi: dxvk ve vkd3d Vulkan gerektirir. Eski Intel grafiklerde sorun cikabilir.\n'
        prompt_wine_cli_values 0 1 "${default_user}" "${default_prefix}" "${default_windows}"
        GUI_ARGS+=(--wine-install --wine-windows-version "${WINE_GUI_WINDOWS_VERSION}" --enable-wine-vulkan)
        append_wine_common_args
        return 0
        ;;
      3)
        GUI_ARGS+=(--wine-check)
        return 0
        ;;
      4)
        GUI_ARGS+=(--wine-version)
        return 0
        ;;
      5)
        prompt_wine_cli_values 1 0 "${default_user}" "${default_prefix}" "${default_windows}"
        GUI_ARGS+=(--winecfg)
        append_wine_common_args
        return 0
        ;;
      6)
        prompt_wine_cli_values 1 1 "${default_user}" "${default_prefix}" "${default_windows}"
        GUI_ARGS+=(--wine-rebuild-prefix --wine-windows-version "${WINE_GUI_WINDOWS_VERSION}")
        append_wine_common_args
        return 0
        ;;
      7)
        print_line 'Wine paketleri ve ETAP baslaticilari kaldirilacak.\n'
        GUI_ARGS+=(--wine-remove)
        return 0
        ;;
      8)
        print_line 'UYARI: Wine paketleri kaldirilacak ve prefix klasorleri silinecek.\n'
        prompt_wine_cli_values 1 0 "" "${default_prefix}" "${default_windows}"
        GUI_ARGS+=(--wine-remove-purge-prefixes)
        append_wine_common_args
        return 0
        ;;
      *)
        print_line 'Gecersiz secim. Lutfen 1 ile 8 arasinda bir deger girin.\n\n'
        ;;
    esac
  done
}

if [[ ! -x "${MAIN_SCRIPT}" ]]; then
  print_line "HATA: Ana kurulum betigi bulunamadi veya calistirilabilir degil: ${MAIN_SCRIPT}\n"
  pause_before_exit
  exit 1
fi

GUI_ARGS=()
for arg in "$@"; do
  case "${arg}" in
    --wine-gui)
      LAUNCHER_MODE="wine"
      ;;
    --touchdrv-gui)
      LAUNCHER_MODE="touchdrv"
      ;;
    --touch-calibration-gui)
      LAUNCHER_MODE="touch-calibration"
      ;;
    --eta-kayit-repair-gui)
      LAUNCHER_MODE="eta-kayit-repair"
      ;;
    *)
      GUI_ARGS+=("${arg}")
      ;;
  esac
done

GUI_ENV_ARGS=()
load_launcher_state
build_gui_env_args

for arg in "${GUI_ARGS[@]:-}"; do
  if [[ "${arg}" == "--pause-on-error" ]]; then
    PAUSE_ON_ERROR_REQUESTED=1
    break
  fi
done

if [[ "${PAUSE_ON_ERROR_REQUESTED}" != "1" ]]; then
  GUI_ARGS=(--pause-on-error "${GUI_ARGS[@]}")
  PAUSE_ON_ERROR_REQUESTED=1
fi

if handle_wine_informational_loop; then
  exit 0
fi

if [[ "${#GUI_ARGS[@]}" -eq 1 && "${GUI_ARGS[0]}" == "--pause-on-error" ]]; then
  if [[ "${LAUNCHER_MODE}" == "wine" ]]; then
    if launcher_can_use_zenity; then
      if ! collect_wine_gui_args; then
        print_line 'Islem iptal edildi.\n'
        pause_before_exit
        exit 0
      fi
    else
      collect_wine_cli_args
    fi
  elif [[ "${LAUNCHER_MODE}" == "touchdrv" ]]; then
    if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
      if ! collect_touchdrv_gui_args; then
        print_line 'Islem iptal edildi.\n'
        pause_before_exit
        exit 0
      fi
    else
      collect_touchdrv_cli_args
    fi
  elif [[ "${LAUNCHER_MODE}" == "touch-calibration" ]]; then
    if launcher_can_use_zenity; then
      if ! collect_touch_calibration_gui_args; then
        print_line 'Islem iptal edildi.\n'
        pause_before_exit
        exit 0
      fi
    else
      collect_touch_calibration_cli_args
    fi
  elif [[ "${LAUNCHER_MODE}" == "eta-kayit-repair" ]]; then
    if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
      if ! collect_eta_kayit_repair_gui_args; then
        print_line 'Islem iptal edildi.\n'
        pause_before_exit
        exit 0
      fi
    else
      collect_eta_kayit_repair_cli_args
    fi
  elif command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    if ! collect_gui_args; then
      print_line 'Islem iptal edildi.\n'
      pause_before_exit
      exit 0
    fi
  fi
fi

prepare_touchdrv_summary_file
prepare_run_report_file

if [[ "${EUID}" -eq 0 ]]; then
  run_main "${GUI_ARGS[@]}"
  finish_with_status "$?"
fi

print_line "$(launcher_mode_label) baslatiliyor.\n"
print_line 'Yonetici yetkisi gerekiyor. Sistem parolasi istenecektir.\n\n'

if command -v sudo >/dev/null 2>&1; then
  if try_bootstrap_sudo; then
    finish_with_status "$?"
  fi

  run_with_status run_main_with_sudo_prompt
  finish_with_status "$?"
fi

if command -v pkexec >/dev/null 2>&1; then
  if [[ -n "${RUN_REPORT_FILE}" ]]; then
    set +e
    pkexec env "${GUI_ENV_ARGS[@]}" "${MAIN_SCRIPT}" "${GUI_ARGS[@]}" 2>&1 | tee -a "${RUN_REPORT_FILE}"
    status="${PIPESTATUS[0]}"
    set -e
    finish_with_status "${status}"
  fi

  run_with_status pkexec env "${GUI_ENV_ARGS[@]}" "${MAIN_SCRIPT}" "${GUI_ARGS[@]}"
  finish_with_status "$?"
fi

if [[ -n "${RUN_REPORT_FILE}" ]]; then
  printf 'HATA: Bu sistemde ne sudo ne de pkexec bulundu.\n' >>"${RUN_REPORT_FILE}"
fi
print_line 'HATA: Bu sistemde ne sudo ne de pkexec bulundu.\n'
finish_with_status 1
