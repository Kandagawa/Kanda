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
        sleep 0.01
    done
}

clear
echo -e "${C}>>> CẤU HÌNH XOAY IP QUỐC GIA <<<${NC}"

# --- VÒNG LẶP CHÍNH ---
while true; do
    while true; do
        echo -e "\n${Y}[?] Nhập mã quốc gia (ví dụ: us, sg, jp hoặc all)${NC}"
        printf "    Lựa chọn: "
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        
        if [[ "$clean_input" == "all" ]]; then
            country_code=""
            echo -e "${G}>> Chọn: Toàn thế giới.${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            echo -e "${G}>> Chọn quốc gia: ${country_code^^}${NC}"
            break
        else
            echo -e "${R}[!] LỖI: Mã không hợp lệ!${NC}"
        fi
    done

    echo -e "\n${B}[*] Đang chuẩn bị dịch vụ...${NC}"
    show_progress 0 40
    pkg update -y > /dev/null 2>&1
    show_progress 41 85
    pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
    show_progress 86 100
    mkdir -p $PREFIX/etc/tor
    echo -e "\n${G}[ DONE ] Đã tải xong dữ liệu.${NC}"

    # 2. Cấu hình
    sec=30
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nLog notice stdout" > $TORRC
    [ ! -z "$country_code" ] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> $TORRC || echo -e "StrictNodes 0" >> $TORRC

    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
    sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
    echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

    # 3. Chạy dịch vụ
    pkill tor; pkill privoxy; sleep 1
    privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

    # 4. Đọc log Tor và in thông số (Sửa lỗi không hiện Host/Port)
    echo -e "${B}[*] Đang thiết lập mạch kết nối...${NC}"
    start_time=$(date +%s)
    
    # Dùng flag để thoát vòng lặp ngoài
    finished=false

    while IFS= read -r line; do
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo $line | grep -oP "\d+%" | head -1 | tr -d '%')
            printf "\r\033[K${B}[ TIẾN TRÌNH ]${NC} Thiết lập mạch Tor: ${Y}${percent}%%${NC} "
            
            # KHI ĐẠT 100%, IN LUÔN THÔNG SỐ Ở ĐÂY
            if [ "$percent" -eq 100 ]; then
                echo -e "\n"
                echo -e "${B}HOST:   ${G}127.0.0.1${NC}"
                echo -e "${B}PORT:   ${G}8118${NC}"
                if [ ! -z "$country_code" ]; then
                    echo -e "${B}REGION: ${Y}${country_code^^}${NC}"
                else
                    echo -e "${B}REGION: ${Y}WORLDWIDE${NC}"
                fi
                
                # Khởi động xoay IP ngầm
                ( while true; do sleep $sec; echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1; pkill -HUP tor; done ) &
                
                finished=true
                break
            fi
        fi
        
        # Check 3s nếu đứng 0%
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge 3 ] && [ "$percent" -eq 0 ]; then
            echo -e "\n${R}[ LỖI ] Mã '${country_code^^}' không khả dụng (0%% sau 3s).${NC}"
            pkill tor; pkill privoxy
            break
        fi
    done < <(stdbuf -oL tor 2>/dev/null)

    # Thoát vòng lặp chính khi đã thành công
    if [ "$finished" = true ]; then
        break
    fi
done

wait > /dev/null 2>&1
