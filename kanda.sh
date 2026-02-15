#!/data/data/com.termux/files/usr/bin/bash

init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
        echo 'echo -e "\n\033[1;32mĐể quay lại cấu hình nhập: \033[1;33mkanda\033[0m\n"' >> ~/.bashrc
        source ~/.bashrc > /dev/null 2>&1
    fi
}

init_colors() {
    G='\033[1;32m'
    Y='\033[1;33m'
    B='\033[1;34m'
    C='\033[1;36m'
    W='\033[1;37m'
    R='\033[1;31m'
    NC='\033[0m'
    BOLD='\033[1m'
}

render_bar() {
    local percent=$1
    local w=20
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r  ${W}── ${C}Tiến trình: ${B}[${G}"
    for ((j=0; j<filled; j++)); do printf "■"; done
    printf "${W}"
    for ((j=0; j<empty; j++)); do printf " "; done
    printf "${B}] ${Y}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
}

select_country() {
    echo -e "\n  ${BOLD}${W}┌────────────────────────────────────────┐${NC}"
    echo -e "  ${W}│        ${C}THIẾT LẬP VÙNG QUỐC GIA         ${W}│${NC}"
    echo -e "  ${W}└────────────────────────────────────────┘${NC}"
    echo -e "  ${W}● ${C}Gợi ý: ${G}us, jp, sg, de, ca... ${W}hoặc ${Y}all${NC}"
    while true; do
        printf "  ${BOLD}${G}»${NC} ${W}Nhập mã: ${NC}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            return
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            return
        else
            echo -e "  ${R}✘ Lỗi: Mã quốc gia phải là 2 ký tự!${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n  ${BOLD}${W}┌────────────────────────────────────────┐${NC}"
    echo -e "  ${W}│       ${C}THỜI GIAN LÀM MỚI (PHÚT)         ${W}│${NC}"
    echo -e "  ${W}└────────────────────────────────────────┘${NC}"
    echo -e "  ${W}● ${C}Lưu ý: ${Y}Nên chọn từ 1 đến 5 phút${NC}"
    while true; do
        printf "  ${BOLD}${G}»${NC} ${W}Số phút: ${NC}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            return
        else
            echo -e "  ${R}✘ Lỗi: Vui lòng nhập từ 1 đến 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -ne "\n"
    render_bar 30
    pkg update -y > /dev/null 2>&1
    render_bar 70
    pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
    render_bar 100
    echo -e "\n"
}

config_privoxy() {
    CONF_DIR="$PREFIX/etc/privoxy"
    CONF_FILE="$CONF_DIR/config"
    mkdir -p $CONF_DIR
    if [ ! -f "$CONF_FILE" ]; then
        echo "listen-address 0.0.0.0:8118" > "$CONF_FILE"
    else
        sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' "$CONF_FILE"
    fi
    sed -i '/forward-socks5t/d' "$CONF_FILE"
    echo "forward-socks5t / 127.0.0.1:9050 ." >> "$CONF_FILE"
    privoxy --no-daemon "$CONF_FILE" > /dev/null 2>&1 &
}

config_tor() {
    mkdir -p $PREFIX/etc/tor
    TORRC="$PREFIX/etc/tor/torrc"
    mkdir -p $PREFIX/var/lib/tor
    chmod 700 $PREFIX/var/lib/tor
    echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nDataDirectory $PREFIX/var/lib/tor\nLog notice stdout" > "$TORRC"
    if [ -n "$country_code" ]; then
        echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
    else
        echo -e "StrictNodes 0" >> "$TORRC"
    fi
}

run_tor() {
    printf "  ${W}── ${C}Đang tạo mạch kết nối: ${Y}0%%${NC}"
    stdbuf -oL tor -f "$TORRC" | while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | sed -n 's/.*Bootstrapped \([0-9]\{1,3\}\)%.*/\1/p')
            if [ -n "$percent" ]; then
                printf "\r  ${W}── ${C}Đang tạo mạch kết nối: ${Y}${percent}%%${NC}"
                if [ "$percent" -eq 100 ]; then
                    clear
                    echo -e "\n  ${G}${BOLD}✔ KẾT NỐI ĐÃ SẴN SÀNG!${NC}"
                    echo -e "  ${W}┌────────────────────────────────────────┐${NC}"
                    echo -e "  ${W}│  ${C}REGION ${W}» ${Y}${country_code^^:-GLOBAL}${NC}"
                    echo -e "  ${W}│  ${C}RENEW  ${W}» ${Y}${minute_input} PHÚT${NC}"
                    echo -e "  ${W}│  ${C}PROXY  ${W}» ${G}127.0.0.1:8118${NC}"
                    echo -e "  ${W}└────────────────────────────────────────┘${NC}"
                    echo -e "  ${BOLD}${Y}[LƯU Ý QUAN TRỌNG]${NC}"
                    echo -e "  ${W}● Dán ${G}127.0.0.1:8118${W} vào app cần dùng Proxy.${NC}"
                    echo -e "  ${W}● IP sẽ tự động thay đổi sau mỗi ${Y}${minute_input} phút.${NC}"
                    echo -e "  ${W}● Nhấn ${R}CTRL+C${W} để thay đổi cấu hình.${NC}\n"
                    auto_rotate > /dev/null 2>&1 &
                    break
                fi
            fi
        fi
    done
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
    echo -e "  ${BOLD}${C}>>> CẤU HÌNH XOAY IP QUỐC GIA TỰ ĐỘNG <<<${NC}"
    echo -e "  ${R}Ghi chú: Đảm bảo kết nối mạng ổn định.${NC}"
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
