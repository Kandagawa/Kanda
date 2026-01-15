#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
R='\033[1;31m'
P='\033[1;35m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH ---
show_progress() {
    local current=$1
    local target=$2
    local w=25
    for ((i=current; i<=target; i++)); do
        local filled=$((i*w/100))
        local empty=$((w-filled))
        printf "\r\033[K${Y}[*] Đang tải dữ liệu... ${C}[${G}"
        for ((j=0; j<filled; j++)); do printf "●"; done
        printf "${W}"
        for ((j=0; j<empty; j++)); do printf "○"; done
        printf "${C}] ${Y}%d%%${NC}" "$i"
        sleep 0.005
    done
}

# --- DỌN DẸP HỆ THỐNG ---
pkill -9 tor > /dev/null 2>&1
pkill -9 privoxy > /dev/null 2>&1
pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1

clear
echo -e "${C}========================================${NC}"
echo -e "${G}    HỆ THỐNG CẤU HÌNH XOAY IP QUỐC GIA  ${NC}"
echo -e "${C}========================================${NC}"

# --- VÒNG LẶP CHÍNH ---
while true; do
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

    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    sleep 1

    echo -e "\n${B}[*] Khởi tạo dịch vụ...${NC}"
    show_progress 0 100
    pkg update -y > /dev/null 2>&1
    pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
    mkdir -p $PREFIX/etc/tor

    # Cấu hình
    sec=30
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nLog notice stdout" > $TORRC
    [ ! -z "$country_code" ] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> $TORRC || echo -e "StrictNodes 0" >> $TORRC

    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
    sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
    echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

    privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

    # Đọc log Tor và hiển thị phần trăm ngay dưới dòng trên
    echo -e "\n${B}[*] Thiết lập mạch kết nối...${NC}"
    start_time=$(date +%s)
    finished=false
    percent=0

    while IFS= read -r line; do
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo $line | grep -oP "\d+%" | head -1 | tr -d '%')
            # Hiển thị phần trăm ngay tại dòng này
            printf "\r${Y}>>> Tiến trình Tor: ${G}${percent}%%${NC}"
            
            if [ "$percent" -eq 100 ]; then
                echo -e "\n\n${G}[ THÀNH CÔNG ] Mạch Tor đã sẵn sàng!${NC}"
                echo -e "${C}┌──────────────────────────────────────┐${NC}"
                printf "${C}│${NC}  ${B}HOST:   ${G}%-26s${NC} ${C}│${NC}\n" "127.0.0.1"
                printf "${C}│${NC}  ${B}PORT:   ${G}%-26s${NC} ${C}│${NC}\n" "8118"
                if [ ! -z "$country_code" ]; then
                    printf "${C}│${NC}  ${B}REGION: ${Y}%-26s${NC} ${C}│${NC}\n" "${country_code^^}"
                else
                    printf "${C}│${NC}  ${B}REGION: ${Y}%-26s${NC} ${C}│${NC}\n" "WORLDWIDE"
                fi
                echo -e "${C}└──────────────────────────────────────┘${NC}"
                echo -e "${P}>> Nhấn ${R}CTRL + C${P} để đổi quốc gia khác <<${NC}"
                
                pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
                ( while true; do sleep $sec; echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1; pkill -HUP tor; done ) &
                
                finished=true
                break
            fi
        fi
        
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge 5 ] && [ "$percent" -eq 0 ]; then
            echo -e "\n${R}[ LỖI ] Không thể kết nối (0%% sau 5s). Vui lòng thử lại!${NC}"
            pkill -9 tor; pkill -9 privoxy
            break
        fi
    done < <(stdbuf -oL tor 2>/dev/null)

    if [ "$finished" = true ]; then
        break
    fi
done

wait > /dev/null 2>&1
