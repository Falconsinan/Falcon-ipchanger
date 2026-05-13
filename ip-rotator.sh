#!/bin/bash

# ==========================================
#        FALCON by SINAN
#   Advanced Tor IP Rotator v3
# ==========================================

# -------- COLORS --------
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# -------- CONFIG --------
TOR_PROXY="socks5h://127.0.0.1:9050"
TOR_CONTROL_PORT=9051
CHECK_URL="https://checkip.amazonaws.com"
LOG_FILE="falcon.log"

# -------- BANNER --------
banner() {

clear

echo -e "${CYAN}"

cat << "EOF"

███████╗ █████╗ ██╗      ██████╗ ██████╗ ███╗   ██╗
██╔════╝██╔══██╗██║     ██╔════╝██╔═══██╗████╗  ██║
█████╗  ███████║██║     ██║     ██║   ██║██╔██╗ ██║
██╔══╝  ██╔══██║██║     ██║     ██║   ██║██║╚██╗██║
██║     ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║
╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝

        Advanced Tor Rotator v3
               by SINAN

EOF

echo -e "${RESET}"
}

# -------- CLEAN EXIT --------
cleanup() {

    echo -e "\n${RED}[!] Exiting FALCON...${RESET}"
    exit 0
}

trap cleanup SIGINT

# -------- LOGGING --------
log() {

    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

# -------- ROOT CHECK --------
root_check() {

    if [[ "$EUID" -ne 0 ]]; then

        echo -e "${RED}[!] Run as root${RESET}"
        exit 1
    fi
}

# -------- INSTALL PACKAGES --------
install_packages() {

    echo -e "${BLUE}[*] Installing dependencies...${RESET}"

    if command -v apt &>/dev/null; then

        apt update -y
        apt install -y tor curl netcat-openbsd

    elif command -v yum &>/dev/null; then

        yum install -y tor curl nc

    elif command -v pacman &>/dev/null; then

        pacman -Sy --noconfirm tor curl openbsd-netcat

    else

        echo -e "${RED}[!] Unsupported distro${RESET}"
        exit 1
    fi
}

# -------- DEPENDENCY CHECK --------
dependency_check() {

    local missing=0

    for pkg in tor curl nc; do

        if ! command -v "$pkg" &>/dev/null; then
            missing=1
        fi
    done

    if [[ $missing -eq 1 ]]; then
        install_packages
    fi
}

# -------- CHECK NETCAT --------
check_netcat() {

    if ! nc -h 2>&1 | grep -q "\-z"; then

        echo -e "${RED}[!] Unsupported netcat version${RESET}"
        echo -e "${YELLOW}[!] Install netcat-openbsd${RESET}"

        exit 1
    fi
}

# -------- START TOR --------
start_tor() {

    echo -e "${BLUE}[*] Starting Tor service...${RESET}"

    systemctl start tor 2>/dev/null

    sleep 3

    if systemctl is-active --quiet tor; then

        echo -e "${GREEN}[+] Tor service started${RESET}"

    else

        echo -e "${RED}[!] Failed to start Tor${RESET}"
        exit 1
    fi
}

# -------- CHECK CONTROL PORT --------
check_control_port() {

    if nc -z 127.0.0.1 "$TOR_CONTROL_PORT" &>/dev/null; then

        echo -e "${GREEN}[+] Tor control port active${RESET}"

    else

        echo -e "${RED}[!] Tor control port disabled${RESET}"

        echo
        echo "Add this to /etc/tor/torrc:"
        echo
        echo "ControlPort 9051"
        echo "CookieAuthentication 0"
        echo

        exit 1
    fi
}

# -------- GET TOR IP --------
get_ip() {

    curl -s --max-time 15 -x "$TOR_PROXY" "$CHECK_URL"
}

# -------- VERIFY TOR --------
verify_tor() {

    local tor_ip
    tor_ip=$(get_ip)

    if [[ -z "$tor_ip" ]]; then

        echo -e "${RED}[!] Failed to connect through Tor${RESET}"
        log "Tor verification failed"

        exit 1
    fi

    echo -e "${GREEN}[+] Verified Tor IP:${RESET} ${CYAN}$tor_ip${RESET}"
}

# -------- WAIT FOR NEW IP --------
wait_for_new_ip() {

    local old_ip="$1"
    local timeout=15
    local count=0

    while [[ $count -lt $timeout ]]; do

        current_ip=$(get_ip)

        if [[ -n "$current_ip" && "$current_ip" != "$old_ip" ]]; then

            echo "$current_ip"
            return 0
        fi

        sleep 1
        ((count++))
    done

    return 1
}

# -------- CHANGE IP --------
change_ip() {

    OLD_IP=$(get_ip)

    if [[ -z "$OLD_IP" ]]; then

        echo -e "${RED}[!] Failed to fetch current IP${RESET}"
        log "Current IP fetch failed"

        return
    fi

    echo -e "${BLUE}[*] Requesting new Tor circuit...${RESET}"

    printf 'AUTHENTICATE\r\nSIGNAL NEWNYM\r\nQUIT\r\n' \
    | nc 127.0.0.1 "$TOR_CONTROL_PORT" >/dev/null 2>&1

    NEW_IP=$(wait_for_new_ip "$OLD_IP")

    if [[ $? -eq 0 ]]; then

        echo -e "${GREEN}[+] New IP:${RESET} ${CYAN}$NEW_IP${RESET}"
        log "IP changed: $OLD_IP -> $NEW_IP"

    else

        echo -e "${YELLOW}[!] IP unchanged after rotation${RESET}"
        log "Rotation completed but IP unchanged"
    fi
}

# -------- MAIN LOOP --------
main_loop() {

    echo

    read -rp $'\033[1;34m[?] Rotation interval (seconds): \033[0m' interval
    read -rp $'\033[1;34m[?] Number of rotations (0 = infinite): \033[0m' rotations

    if ! [[ "$interval" =~ ^[0-9]+$ ]]; then

        echo -e "${RED}[!] Invalid interval${RESET}"
        exit 1
    fi

    if ! [[ "$rotations" =~ ^[0-9]+$ ]]; then

        echo -e "${RED}[!] Invalid rotation count${RESET}"
        exit 1
    fi

    echo

    if [[ "$rotations" == "0" ]]; then

        echo -e "${GREEN}[+] Infinite mode enabled${RESET}"

        while true; do

            change_ip
            sleep "$interval"
        done

    else

        for ((i=1; i<=rotations; i++)); do

            echo -e "${CYAN}========== Rotation $i/$rotations ==========${RESET}"

            change_ip

            if [[ "$i" -lt "$rotations" ]]; then
                sleep "$interval"
            fi
        done
    fi
}

# -------- START --------
banner
root_check
dependency_check
check_netcat
start_tor
check_control_port
verify_tor

echo
echo -e "${GREEN}[+] Current IP:${RESET} $(get_ip)"
echo

main_loop