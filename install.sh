#! /usr/bin/env bash

# Grub2 Themes
set -o errexit

readonly ROOT_UID=0
readonly MAX_DELAY=20 # max delay for user to enter root password

DEST_DIR="/usr/share/grub/themes"
REO_DIR="$("cd $(dirname $0) && pwd")"

name=Bhairava

#COLORS
CDEF=" \033[0m"      # default color
b_CCIN=" \033[1;36m" # bold info color
b_CGSC=" \033[1;32m" # bold success color
b_CRER=" \033[1;31m" # bold error color
b_CWAR=" \033[1;33m" # bold warning color

# echo like ... with flag type and display message colors
prompt() {
  case ${1} in
  "-s" | "--success")
    echo -e "${b_CGSC}${@/-s/}${CDEF}"
    ;; # print success message
  "-e" | "--error")
    echo -e "${b_CRER}${@/-e/}${CDEF}"
    ;; # print error message
  "-w" | "--warning")
    echo -e "${b_CWAR}${@/-w/}${CDEF}"
    ;; # print warning message
  "-i" | "--info")
    echo -e "${b_CCIN}${@/-i/}${CDEF}"
    ;; # print info message
  *)
    echo -e "$@"
    ;;
  esac
}

# Check command availability
function has_command() {
  command -v "$1" >/dev/null
}

usage() {
  printf "%s\n" "Usage: ${0##*/} [OPTIONS...]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n" "-d, --dest" "Specify destination directory (Default: $DEST_DIR)"
  printf "  %-25s%s\n" "-b, --boot" "Install grub theme into /boot/grub/themes"
  printf "  %-25s%s\n" "-r, --remove" "Remove theme (must add theme name option)"
  printf "  %-25s%s\n" "-j, --justcopy" "Just copy the theme files, without setting the theme system wide"
  printf "  %-25s%s\n" "-h, --help" "Show this help"
}

install() {

  local THEME_DIR="${DEST_DIR}/${name}"

  # Check for root access and proceed if it is present

  # Create themes directory if it didn't exist
  prompt -s "\n Checking for the existence of themes directory..."

  [[ -d "${THEME_DIR}" ]] && rm -rf "${THEME_DIR}"
  mkdir -p "${THEME_DIR}"

  # Copy theme
  prompt -s "\n Installing ${name} theme..."

  # Don't preserve ownership because the owner will be root, and that causes the script to crash if it is ran from terminal by sudo
  cp -a --no-preserve=ownership "${REO_DIR}/*" "${THEME_DIR}"

  [[ "${justcopy:-}" == 'true' ]] && exit 0

  # Set theme
  prompt -s "\n Setting ${name} as default..."

  # Backup grub config
  cp -an /etc/default/grub /etc/default/grub.bak

  # Fedora workaround to fix the missing unicode.pf2 file (tested on fedora 34): https://bugzilla.redhat.com/show_bug.cgi?id=1739762
  # This occurs when we add a theme on grub2 with Fedora.
  if has_command dnf; then
    if [[ -f "/boot/grub2/fonts/unicode.pf2" ]]; then
      if grep "GRUB_FONT=" /etc/default/grub 2>&1 >/dev/null; then
        #Replace GRUB_FONT
        sed -i "s|.*GRUB_FONT=.*|GRUB_FONT=/boot/grub2/fonts/unicode.pf2|" /etc/default/grub
      else
        #Append GRUB_FONT
        echo "GRUB_FONT=/boot/grub2/fonts/unicode.pf2" >>/etc/default/grub
      fi
    elif [[ -f "/boot/efi/EFI/fedora/fonts/unicode.pf2" ]]; then
      if grep "GRUB_FONT=" /etc/default/grub 2>&1 >/dev/null; then
        #Replace GRUB_FONT
        sed -i "s|.*GRUB_FONT=.*|GRUB_FONT=/boot/efi/EFI/fedora/fonts/unicode.pf2|" /etc/default/grub
      else
        #Append GRUB_FONT
        echo "GRUB_FONT=/boot/efi/EFI/fedora/fonts/unicode.pf2" >>/etc/default/grub
      fi
    fi
  fi

  if grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null; then
    #Replace GRUB_THEME
    sed -i "s|.*GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" /etc/default/grub
  else
    #Append GRUB_THEME
    echo "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" >>/etc/default/grub
  fi

  # Make sure the right resolution for grub is set

  gfxmode="GRUB_GFXMODE=1920x1080,auto"

  if grep "GRUB_GFXMODE=" /etc/default/grub 2>&1 >/dev/null; then
    #Replace GRUB_GFXMODE
    sed -i "s|.*GRUB_GFXMODE=.*|${gfxmode}|" /etc/default/grub
  else
    #Append GRUB_GFXMODE
    echo "${gfxmode}" >>/etc/default/grub
  fi

  if grep "GRUB_TERMINAL=console" /etc/default/grub 2>&1 >/dev/null || grep "GRUB_TERMINAL=\"console\"" /etc/default/grub 2>&1 >/dev/null; then
    #Replace GRUB_TERMINAL
    sed -i "s|.*GRUB_TERMINAL=.*|#GRUB_TERMINAL=console|" /etc/default/grub
  fi

  if grep "GRUB_TERMINAL_OUTPUT=console" /etc/default/grub 2>&1 >/dev/null || grep "GRUB_TERMINAL_OUTPUT=\"console\"" /etc/default/grub 2>&1 >/dev/null; then
    #Replace GRUB_TERMINAL_OUTPUT
    sed -i "s|.*GRUB_TERMINAL_OUTPUT=.*|#GRUB_TERMINAL_OUTPUT=console|" /etc/default/grub
  fi

  # For Kali linux
  if [[ -f "/etc/default/grub.d/kali-themes.cfg" ]]; then
    cp -an /etc/default/grub.d/kali-themes.cfg /etc/default/grub.d/kali-themes.cfg.bak
    sed -i "s|.*GRUB_GFXMODE=.*|${gfxmode}|" /etc/default/grub.d/kali-themes.cfg
    sed -i "s|.*GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" /etc/default/grub.d/kali-themes.cfg
  fi

  # Update grub config
  prompt -s "\n Updating grub config...\n"

  updating_grub

  prompt -w "\n * At the next restart of your computer you will see your new Grub theme: '${name}' "

}

updating_grub() {
  if has_command update-grub; then
    grub-install
    update-grub
  elif has_command grub-mkconfig; then
    grub-install
    grub-mkconfig -o /boot/grub/grub.cfg
  elif has_command zypper; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
  elif has_command dnf; then
    if [[ -f /boot/efi/EFI/fedora/grub.cfg ]]; then
      prompt -i "Find config file on /boot/efi/EFI/fedora/grub.cfg ...\n"
      grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    fi
    if [[ -f /boot/grub2/grub.cfg ]]; then
      prompt -i "Find config file on /boot/grub2/grub.cfg ...\n"
      grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
  fi

  # Success message
  prompt -s "\n * All done!"
}

remove() {
  local THEME_DIR="${DEST_DIR}/${name}"

  # Check for root access and proceed if it is present
  if [ "$UID" -eq "$ROOT_UID" ]; then
    echo -e "\n Checking for the existence of themes directory..."
    if [[ -d "${THEME_DIR}" ]]; then
      rm -rf "${THEME_DIR}"
    else
      prompt -e "\n ${name} grub theme does not exist!"
      exit 0
    fi

    # Backup grub config
    if [[ -f "/etc/default/grub.bak" ]]; then
      rm -rf /etc/default/grub && mv /etc/default/grub.bak /etc/default/grub
    else
      prompt -e "\n grub.bak does not exist!"
      exit 0
    fi

    # For Kali linux
    if [[ -f "/etc/default/grub.d/kali-themes.cfg.bak" ]]; then
      rm -rf /etc/default/grub.d/kali-themes.cfg && mv /etc/default/grub.d/kali-themes.cfg.bak /etc/default/grub.d/kali-themes.cfg
    fi

    # Update grub config
    prompt -s "\n Resetting grub theme...\n"

    updating_grub

  else
    #Check if password is cached (if cache timestamp not expired yet)
    sudo -n true 2>/dev/null && echo

    if [[ $? == 0 ]]; then
      #No need to ask for password
      sudo "$0" "${PROG_ARGS[@]}"
    else
      #Ask for password
      prompt -e "\n [ Error! ] -> Run me as root! "
      read -p " [ Trusted ] Specify the root password : " -t ${MAX_DELAY} -s

      sudo -S echo <<<$REPLY 2>/dev/null && echo

      if [[ $? == 0 ]]; then
        #Correct password, use with sudo's stdin
        sudo -S "$0" "${PROG_ARGS[@]}" <<<$REPLY
      else
        #block for 3 seconds before allowing another attempt
        sleep 3
        clear
        prompt -e "\n [ Error! ] -> Incorrect password!\n"
        exit 1
      fi
    fi
  fi
}

while [[ $# -gt 0 ]]; do
  PROG_ARGS+=("${1}")
  dialog='false'
  case "${1}" in
  -d | --dest)
    DEST_DIR="${2}"
    shift 2
    ;;
  -b | --boot)
    THEME_DIR="/boot/grub/themes"
    shift 1
    ;;
  -r | --remove)
    remove='true'
    shift 1
    ;;
  -j | --justcopy)
    justcopy='true'
    shift 1

    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    prompt -e "ERROR: Unrecognized installation option '$1'."
    prompt -i "Try '$0 --help' for more information."
    exit 1
    ;;
  esac
done

if [[ "${remove:-}" == 'true' ]]; then
  remove
else
  install

fi

exit 0
