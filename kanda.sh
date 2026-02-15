#!/data/data/com.termux/files/usr/bin/bash

init_colors() {
    G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
    C='\033[1;36m'; W='\033[1;37m'; R='\033[1;31m'; NC='\033[0m'
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
            echo -e "${G}>> Lựa chọn: Toàn cầu.${NC}"
            return
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e "${G}>> Lựa chọn quốc gia: ${country_code^^}${NC}"
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
    CONF_FILE="$PREFIX/etc/privoxy/config"
    mkdir -p "$PREFIX/etc/privoxy"
    echo "listen-address 0.0.0.0:8118" > "$CONF_FILE"
    echo "forward-socks5t / 127.0.0.1:9050 ." >> "$CONF_FILE"
    privoxy --no-daemon "$CONF_FILE" > /dev/null 2>&1 &

    # Cấu hình Tor với Fix lỗi GeoIP
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nDataDirectory $PREFIX/var/lib/tor" > "$TORRC"
    echo -e "GeoIPFile $PREFIX/share/tor/geoip\nGeoIPv6File $PREFIX/share/tor/geoip6" >> "$TORRC"
    echo -e "MaxCircuitDirtiness $sec\nCircuitBuildTimeout 15\nLog notice stdout" >> "$TORRC"
    
    if [ -n "$country_code" ]; then
        echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
    fi
}

run_tor() {
    echo -ne "${C}[*] Đang thiết lập mạch kết nối: 0%${NC}"
    stdbuf -oL tor -f "$PREFIX/etc/tor/torrc" | while read -r line; do
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1)
            printf "\r${C}[*] Thiết lập mạch kết nối: ${Y}%s${NC}" "$percent"
            if [[ "$percent" == "100%" ]]; then
                echo -e "\n\n${G}✔️ KẾT NỐI THÀNH CÔNG!${NC}"
                echo -e "${B}----------------------------------${NC}"
                echo -e "${B}HTTP PROXY: ${W}127.0.0.1:8118${NC}"
                echo -e "${B}QUỐC GIA:   ${Y}${country_code^^:-TOÀN CẦU}${NC}"
                echo -e "${B}XOAY SAU:   ${Y}${minute_input} PHÚT${NC}"
                echo -e "${B}----------------------------------${NC}"
                echo -e "${R}[Bấm CTRL+C để đổi cấu hình]${NC}"
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
    while true; do
        cleanup
        clear
        echo -e "${C}>>> TOR IP ROTATOR FIX GEOIP <<<${NC}"
        select_country
        select_rotate_time
        config_services
        run_tor
        trap "break" SIGINT
        while true; do sleep 1; done
    done
}

main
