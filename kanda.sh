#!/data/data/com.termux/files/usr/bin/bash

init_alias() {
    # Thêm vào .bashrc
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
    fi
    # Tạo file thực thi vào hệ thống để nhận lệnh ngay lập tức
    if [ ! -f "$PREFIX/bin/kanda" ]; then
        echo -e '#!/data/data/com.termux/files/usr/bin/bash\ncurl -Ls is.gd/kandaprx | bash' > "$PREFIX/bin/kanda"
        chmod +x "$PREFIX/bin/kanda"
    fi
}

init_colors() {
    G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'; C='\033[1;36m'
    W='\033[1;37m'; R='\033[1;31m'; M='\033[1;35m'; NC='\033[0m'
}

render_bar() {
    local percent=$1
    local w=25
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r\033[K${C}[*] Đang cài đặt: ${B}[${G}"
    for ((j=0; j<filled; j++)); do printf "●"; done
    printf "${W}"
    for ((j=0; j<empty; j++)); do printf "○"; done
    printf "${B}] ${Y}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
}

select_country() {
    echo -e "${B}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${B}│${W}             THIẾT LẬP QUỐC GIA IP              ${B}│${NC}"
    echo -e "${B}└──────────────────────────────────────────────────┘${NC}"
    while true; do
        echo -e "${Y}[?] Nhập mã quốc gia (jp, vn, us, sg... hoặc all)${NC}"
        printf "    Lựa chọn: "
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            echo -e "${G}>> Lựa chọn: Toàn cầu.${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e "${G}>> Lựa chọn quốc gia: ${country_code^^}${NC}"
            break
        else
            echo -e "${R}[!] LỖI: Mã quốc gia không hợp lệ (phải là 2 chữ cái)!${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n${B}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${B}│${W}             THIẾT LẬP THỜI GIAN XOAY           ${B}│${NC}"
    echo -e "${B}└──────────────────────────────────────────────────┘${NC}"
    while true; do
        echo -e "${Y}[?] Nhập số phút để làm mới IP (1-9)${NC}"
        printf "    Số phút: "
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            echo -e "${G}>> Làm mới sau mỗi ${minute_input} phút.${NC}"
            break
        else
            echo -e "${R}[!] LỖI: Chỉ nhập số từ 1 đến 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n${C}[*] Đang khởi tạo dịch vụ hệ thống...${NC}"
    render_bar 20
    pkg update -y > /dev/null 2>&1
    render_bar 60
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
    echo -ne "${C}[*] Thiết lập mạch kết nối: 0%${NC}"
    stdbuf -oL tor -f "$TORRC" 2>/dev/null | while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
            printf "\r${C}[*] Thiết lập mạch kết nối: ${Y}${percent}%%${NC}"
            if [ "$percent" -eq 100 ]; then
                clear
                echo -e "${G}      >>> KẾT NỐI ĐÃ SẴN SÀNG! <<<${NC}"
                echo -e "${B}┌──────────────────────────────────────────────────┐${NC}"
                echo -e "${B}│${C}  PROXY HOST  ${B}│${W}  127.0.0.1                        ${B}│${NC}"
                echo -e "${B}│${C}  PROXY PORT  ${B}│${W}  8118                             ${B}│${NC}"
                echo -e "${B}├──────────────────────────────────────────────────┤${NC}"
                echo -e "${B}│${C}  QUỐC GIA    ${B}│${Y}  ${country_code^^:-TOÀN CẦU}${W}                          ${B}│${NC}"
                echo -e "${B}│${C}  LÀM MỚI     ${B}│${Y}  ${minute_input} PHÚT                            ${B}│${NC}"
                echo -e "${B}└──────────────────────────────────────────────────┘${NC}"
                echo -e "${M}[!] Trạng thái: ${G}Đang hoạt động ngầm...${NC}"
                echo -e "\n${Y}[CTRL+C] để đổi quốc gia${NC} | ${R}[CTRL+C] 2 lần để thoát${NC}"
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
    echo -e "${C}[*] Đang tối ưu hệ thống và fix lỗi curl...${NC}"
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" > /dev/null 2>&1
    
    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        echo -e "${G}====================================================${NC}"
        echo -e "${W}         KANDA PROXY - TỰ ĐỘNG XOAY IP              ${NC}"
        echo -e "${G}====================================================${NC}"
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
