#!/data/data/com.termux/files/usr/bin/bash

# --- Khởi tạo và Màu sắc ---
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
    local label=$1; local percent=$2; local w=25
    local filled=$((percent*w/100)); local empty=$((w-filled))
    printf "\r\033[K  ${GREY}${label}: ${NC}["
    printf "${CYAN}"
    for ((j=0; j<filled; j++)); do printf "━"; done
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "━"; done
    printf "${NC}] ${WHITE}%d%%${NC}" "$percent"
}

cleanup() {
    # Giết sạch tiến trình con (hàm rotate cũ) và Tor/Privoxy
    pkill -P $$ > /dev/null 2>&1
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
    rm -f "$PREFIX/tmp/progress_kanda" > /dev/null 2>&1
}

# --- Lựa chọn thông số ---
select_country() {
    echo -e "\n  ${PURPLE}◈${NC} ${WHITE}VÙNG QUỐC GIA${NC}"
    while true; do
        printf "  ${GREY}╰─>${NC} ${ORANGE}Mã vùng (us, jp, vn, sg... hoặc all):${NC} ${YELLOW}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" || -z "$clean_input" ]]; then
            display_country="TOÀN CẦU"; country_code=""; break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"; display_country="${country_code^^}"; break
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
            sec=$((minute_input * 60)); break
        else
            echo -e "      ${RED}✗ Chỉ nhập số từ 1 đến 9!${NC}"
        fi
    done
}

# --- Cấu hình và Chạy ---
config_privoxy() {
    CONF_DIR="$PREFIX/etc/privoxy"
    mkdir -p $CONF_DIR
    echo -e "listen-address 0.0.0.0:8118\nforward-socks5t / 127.0.0.1:9050 ." > "$CONF_DIR/config"
    privoxy --no-daemon "$CONF_DIR/config" > /dev/null 2>&1 &
}

config_tor() {
    mkdir -p "$PREFIX/var/lib/tor"
    chmod 700 "$PREFIX/var/lib/tor"
    TORRC="$PREFIX/etc/tor/torrc"
    
    # FIX: Đặt MaxCircuitDirtiness 3600 (1 giờ) để chặn Tor tự ý đổi IP
    # Điều này bắt Tor phải đợi lệnh từ script của chúng ta.
    echo -e "ControlPort 9051\nCookieAuthentication 0\nDataDirectory $PREFIX/var/lib/tor\nMaxCircuitDirtiness 3600\nCircuitBuildTimeout 15\nLog notice stdout" > "$TORRC"
    [[ -n "$country_code" ]] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC" || echo -e "StrictNodes 0" >> "$TORRC"
}

auto_rotate() {
    # Hàm này chạy độc lập sau khi Tor đã sẵn sàng
    while true; do
        sleep "$sec"
        # Gửi lệnh đổi IP mượt mà không ngắt kết nối hệ thống
        ( echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 ) > /dev/null 2>&1
    done
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
                echo -e "  ${WHITE}  CHU KỲ     :${NC} ${BLUE}Đúng ${minute_input} phút${NC}"
                echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "  ${GREY}» ${RED}[CTRL+C]${GREY} : Đặt lại cấu hình${NC}\n"
                
                # CHỈ BẮT ĐẦU ĐẾM GIỜ XOAY KHI ĐÃ SẴN SÀNG 100%
                auto_rotate > /dev/null 2>&1 &
                break
            fi
        fi
    done
}

main() {
    init_alias; init_colors; clear
    if ! command -v tor &> /dev/null; then
        pkg update -y && pkg install tor privoxy curl netcat-openbsd openssl -y > /dev/null 2>&1
    fi
    
    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup; clear
        echo -e "  ${PURPLE}▬▬▬${NC} ${WHITE}CẤU HÌNH HỆ THỐNG${NC} ${PURPLE}▬▬▬${NC}"
        select_country; select_rotate_time
        config_privoxy; config_tor; run_tor
        
        while [[ "$stop_flag" == "false" ]]; do 
            sleep 1
        done
        trap - SIGINT
    done
}

main
