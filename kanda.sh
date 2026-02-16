#!/data/data/com.termux/files/usr/bin/bash

init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
        echo -e 'echo -e "\\n\\033[1;30m Lệnh quay lại cấu hình nhập: \\033[1;36mkanda\\033[0m\\n"' >> ~/.bashrc
        
        if [ ! -f "$PREFIX/bin/kanda" ]; then
            echo -e '#!/data/data/com.termux/files/usr/bin/bash\ncurl -Ls is.gd/kandaprx | bash' > "$PREFIX/bin/kanda"
            chmod +x "$PREFIX/bin/kanda"
        fi
        
        source ~/.bashrc > /dev/null 2>&1
    fi
}

init_colors() {
    PURPLE='\033[1;38;5;141m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'
    YELLOW='\033[1;33m'; RED='\033[1;31m'; WHITE='\033[1;37m'
    GREY='\033[1;30m'; BLUE='\033[1;34m'; NC='\033[0m'
    ORANGE='\033[1;38;5;209m'
}

render_bar() {
    local label=$1
    local percent=$2
    local w=25
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r\033[K  ${GREY}${label}: ${NC}["
    printf "${CYAN}"
    for ((j=0; j<filled; j++)); do printf "━"; done
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "━"; done
    printf "${NC}] ${WHITE}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
    rm -f "$PREFIX/tmp/progress_kanda" > /dev/null 2>&1
}

select_country() {
    echo -e "\n  ${PURPLE}◈${NC} ${WHITE}VÙNG QUỐC GIA${NC}"
    while true; do
        printf "  ${GREY}╰─>${NC} ${ORANGE}Mã vùng (us, jp, vn, sg... hoặc all):${NC} ${YELLOW}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" || -z "$clean_input" ]]; then
            display_country="TOÀN CẦU"
            country_code=""
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            display_country="${country_code^^}"
            break
        else
            echo -e "      ${RED}✗ Mã không hợp lệ!${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n  ${PURPLE}◈${NC} ${WHITE}THỜI GIAN XOAY IP${NC}"
    while true; do
        printf "  ${GREY}╰─>${NC} ${ORANGE}Số phút (1 đến 9):${NC} ${YELLOW}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            break
        else
            echo -e "      ${RED}✗ Chỉ nhập số từ 1 đến 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n  ${GREY}Đang khởi động tiến trình hệ thống...${NC}"
    
    local current_p=20
    render_bar "Tiến trình 1" $current_p

    if ! command -v tor &> /dev/null || ! command -v privoxy &> /dev/null; then
        mkdir -p "$PREFIX/tmp"
        touch "$PREFIX/tmp/progress_kanda"
        (
            for ((i=21; i<=98; i++)); do
                [[ ! -f "$PREFIX/tmp/progress_kanda" ]] && break
                echo "$i" > "$PREFIX/tmp/progress_kanda"
                sleep 0.15
            done
        ) &
        local sub_pid=$!
        
        pkg update -y > /dev/null 2>&1
        pkg install tor privoxy curl netcat-openbsd openssl -y > /dev/null 2>&1
        
        kill $sub_pid &> /dev/null
    else
        for ((i=21; i<=100; i+=10)); do
            render_bar "Tiến trình 1" $i
            sleep 0.05
        done
    fi
    
    rm -f "$PREFIX/tmp/progress_kanda" > /dev/null 2>&1
    render_bar "Tiến trình 1" 100
    echo -e "" 
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
    render_bar "Tiến trình 2" 0
    stdbuf -oL tor -f "$TORRC" 2>/dev/null | while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
            render_bar "Tiến trình 2" "$percent"
            if [ "$percent" -eq 100 ]; then
                clear
                echo -e "\n  ${GREEN}HỆ THỐNG ĐÃ SẴN SÀNG${NC}"
                echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "  ${WHITE}  ĐỊA CHỈ    :${NC} ${YELLOW}127.0.0.1:8118${NC}"
                echo -e "  ${WHITE}  QUỐC GIA   :${NC} ${GREEN}${display_country}${NC}"
                echo -e "  ${WHITE}  CHU KỲ     :${NC} ${BLUE}${minute_input} phút${NC}"
                echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "  ${GREY}» ${RED}[CTRL+C]${GREY}           : Đặt lại cấu hình${NC}"
                echo -e "  ${GREY}» ${RED}[CTRL+C]+[CTRL+Z]${GREY}  : Dừng hoàn toàn${NC}\n"
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
    echo -e "  ${RED}Đảm bảo mạng ổn định${NC}"
    echo -e "  ${RED}[*] Kiểm tra hệ thống...${NC}"
    
    if ! command -v tor &> /dev/null || ! command -v privoxy &> /dev/null; then
        pkg install tor privoxy curl netcat-openbsd openssl -y > /dev/null 2>&1
    fi
    
    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        echo -e "  ${PURPLE}▬▬▬${NC} ${WHITE}CẤU HÌNH HỆ THỐNG${NC} ${PURPLE}▬▬▬${NC}"
        select_country
        select_rotate_time
        install_services
        config_privoxy
        config_tor
        run_tor
        
        while [[ "$stop_flag" == "false" ]]; do 
            if [[ -f "$PREFIX/tmp/progress_kanda" ]]; then
                val=$(cat "$PREFIX/tmp/progress_kanda" 2>/dev/null)
                [[ -n "$val" ]] && render_bar "Tiến trình 1" "$val"
            fi
            sleep 0.2
        done
    done
}

main
