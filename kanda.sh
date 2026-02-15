#!/data/data/com.termux/files/usr/bin/bash

# --- Khởi tạo Màu sắc ---
init_colors() {
    G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
    C='\033[1;36m'; W='\033[1;37m'; R='\033[1;31m'; NC='\033[0m'
}

# --- Kiểm tra & Cài đặt gói ---
check_deps() {
    echo -e "${C}[*] Đang kiểm tra tài nguyên hệ thống...${NC}"
    local deps=(tor privoxy curl netcat-openbsd)
    for pkg in "${deps[@]}"; do
        if ! command -v $pkg &> /dev/null; then
            echo -e "${Y}[!] Đang cài đặt thiếu: $pkg...${NC}"
            pkg install $pkg -y > /dev/null 2>&1
        fi
    done
}

# --- Cấu hình lệnh tắt (Alias) ---
init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='bash $(realpath $0)'" >> ~/.bashrc
        echo -e "${G}[+] Đã tạo lệnh tắt. Lần sau chỉ cần gõ: ${Y}kanda${NC}"
    fi
}

# --- Dọn dẹp ---
cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
}

# --- Chọn Quốc gia ---
select_country() {
    while true; do
        echo -e "\n${Y}[?] Nhập mã quốc gia (jp, sg, us, de... hoặc all)${NC}"
        printf "    Lựa chọn: "
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            return
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            return
        else
            echo -e "${R}[!] Lỗi: Mã không hợp lệ!${NC}"
        fi
    done
}

# --- Chọn thời gian xoay ---
select_rotate_time() {
    while true; do
        echo -e "${Y}[?] Thời gian làm mới IP (1-9 phút):${NC} "
        read min_in </dev/tty
        if [[ "$min_in" =~ ^[1-9]$ ]]; then
            sec=$((min_in * 60))
            minute_input=$min_in
            return
        fi
    done
}

# --- Cấu hình Dịch vụ ---
config_services() {
    echo -e "${C}[*] Đang cấu hình hệ thống...${NC}"
    mkdir -p $PREFIX/var/lib/tor
    chmod 700 $PREFIX/var/lib/tor

    # Cấu hình Privoxy
    mkdir -p "$PREFIX/etc/privoxy"
    echo -e "listen-address 0.0.0.0:8118\nforward-socks5t / 127.0.0.1:9050 ." > "$PREFIX/etc/privoxy/config"
    privoxy --no-daemon "$PREFIX/etc/privoxy/config" > /dev/null 2>&1 &

    # Cấu hình Tor (Fix GeoIP)
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nDataDirectory $PREFIX/var/lib/tor" > "$TORRC"
    echo -e "GeoIPFile $PREFIX/share/tor/geoip\nGeoIPv6File $PREFIX/share/tor/geoip6" >> "$TORRC"
    echo -e "MaxCircuitDirtiness $sec\nCircuitBuildTimeout 15\nLog notice stdout" >> "$TORRC"
    
    [[ -n "$country_code" ] ] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
}

# --- Chạy Tor & Hiển thị ---
run_tor() {
    echo -ne "${C}[*] Đang thiết lập mạch kết nối: 0%${NC}"
    stdbuf -oL tor -f "$PREFIX/etc/tor/torrc" | while read -r line; do
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1)
            printf "\r${C}[*] Thiết lập mạch kết nối: ${Y}%s${NC}" "$percent"
            if [[ "$percent" == "100%" ]]; then
                echo -e "\n\n${G}✔️ KẾT NỐI THÀNH CÔNG!${NC}"
                echo -e "${B}----------------------------------${NC}"
                echo -e "${B}IP HIỆN TẠI : ${W}$(curl -s --proxy http://127.0.0.1:8118 https://api.ipify.org)${NC}"
                echo -e "${B}HTTP PROXY  : ${W}127.0.0.1:8118${NC}"
                echo -e "${B}QUỐC GIA    : ${Y}${country_code^^:-TOÀN CẦU}${NC}"
                echo -e "${B}TỰ XOAY SAU : ${Y}${minute_input} PHÚT${NC}"
                echo -e "${B}----------------------------------${NC}"
                echo -e "${R}[Bấm CTRL+C để ĐỔI QUỐC GIA]${NC}"
                auto_rotate &
                break
            fi
        fi
    done
}

# --- Tự động xoay IP ---
auto_rotate() {
    while true; do
        sleep $sec
        echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    done
}

# --- Luồng chính ---
main() {
    init_colors
    check_deps
    init_alias
    while true; do
        cleanup
        clear
        echo -e "${C}>>> TOR IP ROTATOR PRO (FIXED) <<<${NC}"
        select_country
        select_rotate_time
        config_services
        run_tor
        trap "break" SIGINT
        while true; do sleep 1; done
    done
}

main
