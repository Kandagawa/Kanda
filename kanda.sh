#!/data/data/com.termux/files/usr/bin/bash

init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
    fi
    if [ ! -f "$PREFIX/bin/kanda" ]; then
        echo -e '#!/data/data/com.termux/files/usr/bin/bash\ncurl -Ls is.gd/kandaprx | bash' > "$PREFIX/bin/kanda"
        chmod +x "$PREFIX/bin/kanda"
    fi
}

init_colors() {
    # Tông màu chuyên nghiệp: Cyan, White, Grey
    G='\033[38;5;82m'; Y='\033[38;5;226m'; B='\033[38;5;33m'
    C='\033[38;5;51m'; W='\033[38;5;255m'; R='\033[38;5;196m'
    D='\033[38;5;244m'; NC='\033[0m'
}

render_bar() {
    local percent=$1
    local w=30
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r${D}  Status: ${C}"
    for ((j=0; j<filled; j++)); do printf "━"; done
    printf "${D}"
    for ((j=0; j<empty; j++)); do printf "━"; done
    printf " ${W}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
}

select_country() {
    echo -e "\n${W}  [ SETTINGS ]${NC}"
    while true; do
        printf "  ${D}» Target Country (eg: us, jp, all): ${W}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            break
        else
            echo -e "  ${R}! Invalid code.${NC}"
        fi
    done
}

select_rotate_time() {
    while true; do
        printf "  ${D}» Rotation Interval (1-9 min): ${W}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            break
        else
            echo -e "  ${R}! Enter 1-9.${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n${D}  Synchronizing system...${NC}"
    render_bar 30
    pkg update -y > /dev/null 2>&1
    render_bar 70
    pkg install tor privoxy curl netcat-openbsd openssl -y > /dev/null 2>&1
    render_bar 100
    echo -e "\n"
}

config_privoxy() {
    CONF_DIR="$PREFIX/etc/privoxy"
    CONF_FILE="$CONF_DIR/config"
    mkdir -p $CONF_DIR
    echo "listen-address 0.0.0.0:8118" > "$CONF_FILE"
    echo "forward-socks5t / 127.0.0.1:9050 ." >> "$CONF_FILE"
    privoxy --no-daemon "$CONF_FILE" > /dev/null 2>&1 &
}

config_tor() {
    mkdir -p "$PREFIX/var/lib/tor"
    chmod 700 "$PREFIX/var/lib/tor"
    mkdir -p $PREFIX/etc/tor
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nDataDirectory $PREFIX/var/lib/tor\nGeoIPFile $PREFIX/share/tor/geoip\nGeoIPv6File $PREFIX/share/tor/geoip6\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 15\nLog notice stdout" > "$TORRC"
    [[ -n "$country_code" ]] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC" || echo -e "StrictNodes 0" >> "$TORRC"
}

run_tor() {
    render_bar 0
    stdbuf -oL tor -f "$TORRC" 2>/dev/null | while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
            render_bar "$percent"
            if [ "$percent" -eq 100 ]; then
                clear
                echo -e "\n  ${C}●${W} PROXY SYSTEM ACTIVE${NC}"
                echo -e "  ${D}────────────────────────────${NC}"
                echo -e "  ${D}Address  :${W} 127.0.0.1:8118${NC}"
                echo -e "  ${D}Region   :${W} ${country_code^^:-GLOBAL}${NC}"
                echo -e "  ${D}Rotation :${W} ${minute_input} min${NC}"
                echo -e "  ${D}────────────────────────────${NC}"
                echo -e "  ${D}Press [CTRL+C] to reset${NC}\n"
                auto_rotate > /dev/null 2>&1 &
                break
            fi
        fi
    done
}

auto_rotate() {
    while true; do
        sleep $sec
        ( pkill -9 tor; rm -f $PREFIX/var/lib/tor/state; tor -f "$TORRC" > /dev/null 2>&1 &
          sleep 2; echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 ) > /dev/null 2>&1
    done
}

main() {
    init_alias
    init_colors
    clear
    echo -e "${D}[*] Optimizing environment...${NC}"
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" > /dev/null 2>&1
    
    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        echo -e "${W}  PROXY CONFIGURATION${NC}"
        echo -e "${D}  ────────────────────${NC}"
        select_country
        select_rotate_time
        install_services
        config_privoxy
        config_tor
        run_tor
        while [[ "$stop_flag" == "false" ]]; do sleep 1; done
    done
}

main
