#!/data/data/com.termux/files/usr/bin/bash

if ! grep -q "alias kanda=" ~/.bashrc; then
    echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
    echo 'echo -e "\n\033[1;32mĐể quay lại trang proxy nhập: \033[1;33mkanda\033[0m\n"' >> ~/.bashrc
    source ~/.bashrc > /dev/null 2>&1
fi

G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
R='\033[1;31m'
NC='\033[0m'

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

stop_flag=false
trap 'stop_flag=true' SIGINT

cleanup
clear
echo -e "${C}>>> CẤU HÌNH XOAY IP QUỐC GIA <<<${NC}"

while true; do
    stop_flag=false
    while true; do
        echo -e "\n${Y}[?] Nhập mã quốc gia (vd: jp, vn, sg... hoặc all)${NC}"
        echo -e "\n${R}[CTRL + C] để quay lại nếu bị treo vì sai mã hoặc không có ip quốc gia đó${NC}"
        printf "    Lựa chọn: "
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            echo -e "${G}>> Lựa chọn: Toàn thế giới.${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e "${G}>> Lựa chọn quốc gia: ${country_code^^}${NC}"
            break
        else
            echo -e "${R}[!] LỖI: Mã không hợp lệ!${NC}"
        fi
    done

    cleanup
    sleep 1

    echo -e "\n${C}[*] Khởi tạo dịch vụ...${NC}"
    render_bar 10
    pkg update -y > /dev/null 2>&1
    render_bar 40
    pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
    render_bar 100
    echo -e "\n"

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

    mkdir -p $PREFIX/etc/tor
    sec=30
    TORRC="$PREFIX/etc/tor/torrc"
    
    # Sửa đổi: Thêm NewCircuitPeriod và CircuitBuildTimeout để hỗ trợ 'all' tốt hơn
    echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nNewCircuitPeriod 15\nCircuitBuildTimeout 15\nLog notice stdout" > $TORRC
    [ ! -z "$country_code" ] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> $TORRC || echo -e "StrictNodes 0" >> $TORRC

    privoxy --no-daemon "$CONF_FILE" > /dev/null 2>&1 & 

    echo -ne "${C}[*] Thiết lập mạch kết nối: 0%${NC}"
    
    percent=0
    # Sửa đổi: Thêm -f "$TORRC" để Tor luôn đọc đúng file cấu hình mới nhất
    while IFS= read -r line; do
        if [[ "$stop_flag" == "true" ]]; then break; fi
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo $line | grep -oP "\d+%" | head -1 | tr -d '%')
            printf "\r${C}[*] Thiết lập mạch kết nối: ${Y}${percent}%%${NC}"
            
            if [ "$percent" -eq 100 ]; then
                echo -e "\n\n${G}[THÀNH CÔNG] Kết nối đã sẵn sàng!${NC}"
                echo -e "\n${B}HOST:   ${W}127.0.0.1${NC}"
                echo -e "${B}PORT:   ${W}8118${NC}"
                [ ! -z "$country_code" ] && echo -e "${B}REGION: ${Y}${country_code^^}${NC}" || echo -e "${B}REGION: ${Y}WORLDWIDE${NC}"
                echo -e "\n${R}* Nhấn CTRL+C để quay lại chọn quốc gia${NC}"
                
                # Sửa đổi quan trọng: Bỏ pkill -HUP tor để tránh làm treo mạch, chỉ dùng SIGNAL NEWNYM
                ( while true; do sleep $sec; echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1; done ) > /dev/null 2>&1 &
                break
            fi
        fi
    done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

    while [[ "$stop_flag" == "false" ]]; do sleep 1; done
    cleanup
done
