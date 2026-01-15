#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
R='\033[1;31m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH THỰC TẾ ---
render_bar() {
    local percent=$1
    local w=25
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    printf "\r\033[K${C}[*] Đang tải dữ liệu... ${B}[${G}"
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

# --- VÒNG LẶP CHÍNH ---
while true; do
    stop_flag=false
    # Menu nhập mã quốc gia
    while true; do
        echo -e "\n${Y}[?] Nhập mã quốc gia (ví dụ: us, sg, jp hoặc all)${NC}"
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

    # --- TIẾN TRÌNH TẢI ---
    echo -e "\n${C}[*] Khởi tạo dịch vụ...${NC}"
    render_bar 10
    pkg update -y > /dev/null 2>&1
    render_bar 40
    pkg install tor -y > /dev/null 2>&1
    render_bar 70
    pkg install privoxy curl netcat-openbsd -y > /dev/null 2>&1
    render_bar 100
    echo -e "\n"

    mkdir -p $PREFIX/etc/tor
    sec=30
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nLog notice stdout" > $TORRC
    [ ! -z "$country_code" ] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> $TORRC || echo -e "StrictNodes 0" >> $TORRC

    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
    sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
    echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

    privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

    # --- THIẾT LẬP MẠCH KẾT NỐI ---
    echo -ne "${C}[*] Thiết lập mạch kết nối... 0%${NC}"
    start_time=$(date +%s)
    percent=0
    conn_error=false

    # Đọc log từ Tor
    while IFS= read -r line; do
        if [[ "$stop_flag" == "true" ]]; then break; fi
        
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo $line | grep -oP "\d+%" | head -1 | tr -d '%')
            printf "\r${C}[*] Thiết lập mạch kết nối... ${Y}${percent}%%${NC}"
            
            if [ "$percent" -eq 100 ]; then
                echo -e "\n\n${G}[ THÀNH CÔNG ] Kết nối đã sẵn sàng!${NC}"
                echo -e "${B}HOST:   ${W}127.0.0.1${NC}"
                echo -e "${B}PORT:   ${W}8118${NC}"
                [ ! -z "$country_code" ] && echo -e "${B}REGION: ${Y}${country_code^^}${NC}" || echo -e "${B}REGION: ${Y}WORLDWIDE${NC}"
                echo -e "\n${R}* Nhấn CTRL+C để quay lại chọn quốc gia${NC}"
                ( while true; do sleep $sec; echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1; pkill -HUP tor; done ) &
                break
            fi
        fi
        
        # --- XỬ LÝ LỖI 0% QUÁ 5 GIÂY ---
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge 5 ] && [ "$percent" -eq 0 ]; then
            echo -e "\n${R}[ LỖI ] Kết nối thất bại (0%% quá 5s).${NC}"
            echo -e "${Y}>>> Đang quay lại menu chọn quốc gia...${NC}"
            cleanup
            conn_error=true
            break
        fi
    done < <(stdbuf -oL tor 2>/dev/null)

    # Nếu có lỗi kết nối, nhảy về đầu vòng lặp while true luôn
    if [ "$conn_error" = true ]; then
        continue
    fi

    # Chờ nhấn CTRL+C để đổi quốc gia
    while [[ "$stop_flag" == "false" ]]; do
        sleep 1
    done
    cleanup
    echo -e "\n${Y}--- Đang quay lại bước chọn quốc gia ---${NC}"
done
