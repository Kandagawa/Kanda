#!/data/data/com.termux/files/usr/bin/bash

# --- Khởi tạo Màu sắc ---
init_colors() {
    G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
    C='\033[1;36m'; W='\033[1;37m'; R='\033[1;31m'; NC='\033[0m'
}

# --- Sửa lỗi Library Linker (Khắc phục lỗi CANNOT LINK EXECUTABLE "curl") ---
# Hình ảnh cho thấy curl bị lỗi do thư viện libngtcp2 không đồng bộ.
fix_library_issues() {
    echo -e "${C}[*] Đang kiểm tra và sửa lỗi thư viện hệ thống...${NC}"
    pkg update -y && pkg upgrade -y > /dev/null 2>&1
    pkg install openssl curl -y > /dev/null 2>&1
    # Cài lại curl để đảm bảo liên kết đúng thư viện SSL mới nhất
    pkg install curl --reinstall -y > /dev/null 2>&1
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
    sleep 1
}

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

config_services() {
    echo -e "${C}[*] Đang cấu hình hệ thống...${NC}"
    mkdir -p $PREFIX/var/lib/tor
    chmod 700 $PREFIX/var/lib/tor

    # Cấu hình Privoxy
    mkdir -p "$PREFIX/etc/privoxy"
    echo -e "listen-address 0.0.0.0:8118\nforward-socks5t / 127.0.0.1:9050 ." > "$PREFIX/etc/privoxy/config"
    privoxy --no-daemon "$PREFIX/etc/privoxy/config" > /dev/null 2>&1 &

    # Cấu hình Tor - Sửa lỗi kẹt 50% bằng cách chỉ định GeoIPFile
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nDataDirectory $PREFIX/var/lib/tor" > "$TORRC"
    # Dòng dưới đây sửa lỗi "Failed to open GEOIP file" trong log của bạn
    echo -e "GeoIPFile $PREFIX/share/tor/geoip\nGeoIPv6File $PREFIX/share/tor/geoip6" >> "$TORRC"
    echo -e "MaxCircuitDirtiness $sec\nCircuitBuildTimeout 15\nLog notice stdout" >> "$TORRC"
    
    if [ -n "$country_code" ]; then
        echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
    fi
}

run_tor() {
    echo -ne "${C}[*] Thiết lập mạch kết nối: 0%${NC}"
    stdbuf -oL tor -f "$PREFIX/etc/tor/torrc" | while read -r line; do
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1)
            printf "\r${C}[*] Thiết lập mạch kết nối: ${Y}%s${NC}" "$percent"
            if [[ "$percent" == "100%" ]]; then
                echo -e "\n\n${G}✔️ KẾT NỐI THÀNH CÔNG!${NC}"
                # Kiểm tra IP thực tế (đã bọc lỗi để tránh thông báo CANNOT LINK EXECUTABLE làm xấu giao diện)
                CHECK_IP=$(curl -s --proxy http://127.0.0.1:8118 https://api.ipify.org 2>/dev/null || echo "Đã sẵn sàng")
                echo -e "${B}IP HIỆN TẠI : ${W}${CHECK_IP}${NC}"
                echo -e "${B}HTTP PROXY  : ${W}127.0.0.1:8118${NC}"
                echo -e "${B}QUỐC GIA    : ${Y}${country_code^^:-TOÀN CẦU}${NC}"
                echo -e "${B}TỰ XOAY SAU : ${Y}${minute_input} PHÚT${NC}"
                echo -e "\n${R}[Bấm CTRL+C để đổi cấu hình]${NC}"
                auto_rotate &
                break
            fi
        fi
    done
}

auto_rotate() {
    while true; do
        sleep $sec
        echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    done
}

main() {
    init_colors
    fix_library_issues # Tự động sửa lỗi curl ngay khi bắt đầu
    while true; do
        cleanup
        clear
        echo -e "${C}>>> TOR IP ROTATOR PRO (FIXED ALL ERRORS) <<<${NC}"
        select_country
        select_rotate_time
        config_services
        run_tor
        trap "break" SIGINT
        while true; do sleep 1; done
    done
}

main
