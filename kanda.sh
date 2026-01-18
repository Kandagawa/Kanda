#!/data/data/com.termux/files/usr/bin/bash

init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
        echo 'echo -e "\n\033[1;32mĐể quay lại trang proxy nhập: \033[1;33mkanda\033[0m\n"' >> ~/.bashrc
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
}

render_bar() {
    local percent=$1
    local w=25
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r\033[K${C}[*] Đang tải dữ liệu: ${B}[${G}"
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
    while true; do
        echo -e "\n${Y}[?] Nhập mã quốc gia (vd: jp, vn, sg... hoặc all)${NC}"
        echo -e "\n${R}[CTRL+C] để quay lại nếu bị treo vì sai mã hoặc không có ip quốc gia đó${NC}"
        printf "    Lựa chọn: "
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            echo -e "${G}>> Lựa chọn: Toàn cầu.${NC}"
            return
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e "${G}>> Lựa chọn quốc gia: ${country_code^^}${NC}"
            return
        else
            echo -e "${R}[!] LỖI: Mã không hợp lệ!${NC}"
        fi
    done
}

select_rotate_time() {
    while true; do
        echo -e "\n${Y}[?] Nhập thời gian làm mới IP (từ 1 đến 9 phút)${NC}"
        printf "    Số phút: "
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            echo -e "${G}>> IP sẽ làm mới mỗi ${minute_input} phút.${NC}"
            return
        else
            echo -e "${R}[!] LỖI: Chỉ nhập 1 chữ số từ 1 đến 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    sleep 1
    echo -e "\n${C}[*] Khởi tạo dịch vụ...${NC}"
    render_bar 10
    pkg update -y > /dev/null 2>&1
    render_bar 40
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
    echo -e "ControlPort 9051
CookieAuthentication 0
MaxCircuitDirtiness $sec
CircuitBuildTimeout 10
Log notice stdout" > "$TORRC"
    if [ -n "$country_code" ]; then
        echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
    else
        echo -e "StrictNodes 0" >> "$TORRC"
    fi
}

run_tor() {
    echo -ne "${C}[*] Thiết lập mạch kết nối: 0%${NC}"
    stdbuf -oL tor -f "$TORRC" 2>/dev/null | while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | tr -d '%')
            printf "\r${C}[*] Thiết lập mạch kết nối: ${Y}${percent}%%${NC}"
            if [ "$percent" -eq 100 ]; then
                echo -e "\n\n${G}[THÀNH CÔNG] Kết nối đã sẵn sàng!${NC}"
                echo -e "\n${B}HOST:   ${W}127.0.0.1${NC}"
                echo -e "${B}PORT:   ${W}8118${NC}"
                echo -e "${B}RENEW:  ${Y}${minute_input} PHÚT${NC}"
                if [ -n "$country_code" ]; then
                    echo -e "${B}REGION: ${Y}${country_code^^}${NC}"
                else
                    echo -e "${B}REGION: ${Y}TOÀN CẦU${NC}"
                fi
                echo -e "\n${R}* Nhấn CTRL+C để làm mới quốc gia${NC}"
                auto_rotate > /dev/null 2>&1 &
                break
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
    # Ẩn log Stopped bằng cách disown tiến trình khi nhấn CTRL+Z
    trap 'echo -e "\n${R}[!] Đang ẩn log hệ thống...${NC}"; bg > /dev/null 2>&1; disown' SIGTSTP
    init_alias
    init_colors
    cleanup
    clear
    echo -e "${C}>>> CẤU HÌNH XOAY IP QUỐC GIA TỰ ĐỘNG <<<${NC}"
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
    done
}

main
