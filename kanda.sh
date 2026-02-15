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
    # Palette màu thanh lịch
    PURPLE='\033[38;5;141m'
    CYAN='\033[38;5;81m'
    GREEN='\033[38;5;121m'
    YELLOW='\033[38;5;222m'
    RED='\033[38;5;203m'
    WHITE='\033[38;5;231m'
    GREY='\033[38;5;243m'
    BLUE='\033[38;5;117m'
    NC='\033[0m'
}

render_bar() {
    local percent=$1
    local w=30
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r  ${GREY}Trạng thái: ${NC}["
    printf "${CYAN}"
    for ((j=0; j<filled; j++)); do printf "💧"; done # Sử dụng icon giọt nước nhỏ hoặc thanh mảnh
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "·"; done
    printf "${NC}] ${WHITE}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
}

select_country() {
    echo -e "\n  ${PURPLE}◈${NC} ${WHITE}THIẾT LẬP VÙNG QUỐC GIA${NC}"
    while true; do
        printf "  ${GREY}╰─>${NC} ${BLUE}Nhập mã (vd: us, jp, all):${NC} ${YELLOW}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            echo -e "      ${GREEN}✓ Đã chọn: Toàn cầu${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e "      ${GREEN}✓ Đã chọn: ${country_code^^}${NC}"
            break
        else
            echo -e "      ${RED}✗ Mã không hợp lệ!${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n  ${PURPLE}◈${NC} ${WHITE}THỜI GIAN LÀM MỚI IP${NC}"
    while true; do
        printf "  ${GREY}╰─>${NC} ${BLUE}Số phút (1-9):${NC} ${YELLOW}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            echo -e "      ${GREEN}✓ Tự động xoay sau ${minute_input} phút${NC}"
            break
        else
            echo -e "      ${RED}✗ Chỉ nhập số 1-9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n  ${GREY}Đang chuẩn bị tài nguyên hệ thống...${NC}"
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
                echo -e "\n  ${GREEN}✨ HỆ THỐNG ĐÃ KÍCH HOẠT THÀNH CÔNG${NC}"
                echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "   ${CYAN}⚡${NC}  ${WHITE}IP PROXY   :${NC} ${YELLOW}127.0.0.1:8118${NC}"
                echo -e "   ${CYAN}⚡${NC}  ${WHITE}VÙNG CHỌN  :${NC} ${GREEN}${country_code^^:-TOÀN CẦU}${NC}"
                echo -e "   ${CYAN}⚡${NC}  ${WHITE}CHU KỲ XOAY:${NC} ${BLUE}${minute_input} phút${NC}"
                echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "  ${GREY}» Lệnh quay lại:${NC} ${PURPLE}kanda${NC}"
                echo -e "  ${GREY}» Dừng hệ thống:${NC} ${RED}[CTRL+C]${NC}\n"
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
          sleep 1; echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 ) > /dev/null 2>&1
    done
}

main() {
    init_alias
    init_colors
    clear
    echo -e "${GREY}[*] Đang tinh chỉnh môi trường Termux...${NC}"
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" > /dev/null 2>&1
    
    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        echo -e "  ${PURPLE}▬▬▬${NC} ${WHITE}BỘ ĐIỀU KHIỂN PROXY TỰ ĐỘNG${NC} ${PURPLE}▬▬▬${NC}"
        echo -e "  ${GREY}      (Giao diện Minimal Color)${NC}"
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
