#!/data/data/com.termux/files/usr/bin/bash

# --- Khoi tao moi truong ---
init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
        echo 'echo -e "\n\033[1;32mDe quay lai cau hinh nhap: \033[1;33mkanda\033[0m\n"' >> ~/.bashrc
        source ~/.bashrc > /dev/null 2>&1
    fi
}

init_colors() {
    G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'
    W='\033[1;37m'; R='\033[1;31m'; P='\033[1;35m'; NC='\033[0m'
}

render_bar() {
    local percent=$1
    local w=30
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r ${W}[${G}"
    for ((j=0; j<filled; j++)); do printf "■"; done
    printf "${W}"
    for ((j=0; j<empty; j++)); do printf " "; done
    printf "${W}] ${Y}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
}

select_country() {
    echo -e "\n${C}┌──────────────────────────────────────────┐${NC}"
    echo -e "${C}│          THIET LAP QUOC GIA              │${NC}"
    echo -e "${C}└──────────────────────────────────────────┘${NC}"
    echo -e " ${W}Goi y: ${G}vn, jp, us, sg... ${W}hoac ${G}all${NC}"
    while true; do
        printf " ${C}>> ${W}Lua chon: ${G}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            echo -e " ${G}Status: Global Selection${NC}"
            return
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e " ${G}Status: ${country_code^^} Selected${NC}"
            return
        else
            echo -e " ${R}Error: Ma khong hop le!${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n ${W}Nhap thoi gian lam moi (1-9 phut)${NC}"
    while true; do
        printf " ${C}>> ${W}So phut: ${G}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            return
        else
            echo -e " ${R}Error: Chi nhap tu 1 den 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n ${W}SYSTEM: Dang khoi tao dich vu...${NC}"
    render_bar 30
    pkg update -y > /dev/null 2>&1
    render_bar 70
    pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
    render_bar 100
    echo -e "\n"
}

config_tor() {
    mkdir -p "$PREFIX/var/lib/tor"
    chmod 700 "$PREFIX/var/lib/tor"
    mkdir -p $PREFIX/etc/tor
    TORRC="$PREFIX/etc/tor/torrc"
    
    # Logic fix 50%
    echo -e "ControlPort 9051
CookieAuthentication 0
DataDirectory $PREFIX/var/lib/tor
GeoIPFile $PREFIX/share/tor/geoip
GeoIPv6File $PREFIX/share/tor/geoip6
MaxCircuitDirtiness $sec
CircuitBuildTimeout 15
Log notice stdout" > "$TORRC"

    if [ -n "$country_code" ]; then
        echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
    else
        echo -e "StrictNodes 0" >> "$TORRC"
    fi
}

run_tor() {
    echo -ne " ${W}Connecting: 0%${NC}"
    stdbuf -oL tor -f "$TORRC" 2>/dev/null | while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
            printf "\r ${W}Connecting: ${Y}${percent}%%${NC}"
            
            if [ "$percent" -eq 100 ]; then
                clear
                IP_NOW=$(curl -s --proxy http://127.0.0.1:8118 https://api.ipify.org || echo "N/A")
                echo -e "${G}┌──────────────────────────────────────────┐${NC}"
                echo -e "${G}│        KET NOI THANH CONG (ACTIVE)       │${NC}"
                echo -e "${G}├──────────────────────────────────────────┤${NC}"
                echo -e "${G}│ ${W}IP HIEN TAI : ${Y}${IP_NOW}${G}"
                echo -e "${G}│ ${W}PROXY HOST  : ${W}127.0.0.1${G}"
                echo -e "${G}│ ${W}PROXY PORT  : ${W}8118${G}"
                echo -e "${G}│ ${W}QUOC GIA    : ${P}${country_code^^:-GLOBAL}${G}"
                echo -e "${G}│ ${W}LAM MOI     : ${C}${minute_input} PHUT/LAN${G}"
                echo -e "${G}└──────────────────────────────────────────┘${NC}"
                echo -e " ${W}[CTRL+C] de doi cau hinh | [CTRL+C x2] dung hẳn${NC}"
                auto_rotate > /dev/null 2>&1 &
                break
            fi
        fi
    done
}

config_privoxy() {
    CONF_FILE="$PREFIX/etc/privoxy/config"
    mkdir -p "$PREFIX/etc/privoxy"
    echo -e "listen-address 0.0.0.0:8118\nforward-socks5t / 127.0.0.1:9050 ." > "$CONF_FILE"
    privoxy --no-daemon "$CONF_FILE" > /dev/null 2>&1 &
}

auto_rotate() {
    while true; do
        sleep $sec
        (
            pkill -9 tor
            rm -f $PREFIX/var/lib/tor/state
            tor -f "$TORRC" > /dev/null 2>&1 &
            sleep 1
            echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051
        ) > /dev/null 2>&1
    done
}

main() {
    stop_flag=false
    trap 'stop_flag=true' SIGINT
    init_alias
    init_colors
    cleanup
    clear
    
    echo -e "${C}============================================${NC}"
    echo -e "${C}      KANDA IP ROTATOR - VERSION 2.0        ${NC}"
    echo -e "${C}============================================${NC}"

    while true; do
        stop_flag=false
        select_country
        select_rotate_time
        install_services
        config_privoxy
        config_tor
        run_tor
        while [[ "$stop_flag" == "false" ]]; do sleep 1; done
        cleanup
        clear
    done
}

main
