#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
R='\033[1;31m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH DOTS ---
run_progress() {
    local target=$1
    local current=$2
    local w=25
    for ((i=current; i<=target; i++)); do
        local filled=$((i*w/100))
        local empty=$((w-filled))
        local bar_filled=$(printf '●%.0s' $(seq 1 $filled 2>/dev/null))
        local bar_empty=$(printf '○%.0s' $(seq 1 $empty 2>/dev/null))
        printf "\r${Y}[*] Đang tải dữ liệu... ${C}[${G}%s${W}%s${C}] ${Y}%d%%${NC}" "$bar_filled" "$bar_empty" "$i"
        sleep 0.01
    done
}

clear
echo -e "${C}>>> CẤU HÌNH XOAY IP QUỐC GIA <<<${NC}"

# --- VÒNG LẶP KIỂM TRA NHẬP MÃ QUỐC GIA ---
while true; do
    echo -e "\n${Y}[?] Nhập mã quốc gia (2 chữ cái, ví dụ: us, sg, jp...)${NC}"
    echo -e "${Y}[?] Nhập 'all' để kết nối toàn thế giới.${NC}"
    read -p "    Lựa chọn của bạn: " input
    
    # Chuyển về chữ thường để kiểm tra
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$input_lower" == "all" ]]; then
        country_code=""
        echo -e "${G}>> Đã chọn: Toàn thế giới.${NC}"
        break
    elif [[ "$input_lower" =~ ^[a-z]{2}$ ]]; then
        country_code="$input_lower"
        echo -e "${G}>> Đã chọn quốc gia: ${country_code^^}${NC}"
        break
    else
        echo -e "${R}[!] Lỗi: Mã quốc gia không hợp lệ. Vui lòng nhập đúng 2 chữ cái hoặc 'all'.${NC}"
    fi
done

echo -e "\n${B}[*] Bắt đầu quá trình tải và thiết lập...${NC}\n"

# 1. Tải dữ liệu (Chỉ chạy sau khi đã nhập mã xong)
run_progress 30 0
pkg update -y > /dev/null 2>&1
run_progress 80 31
pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
run_progress 100 81
mkdir -p $PREFIX/etc/tor
echo -e "\n${G}[ DONE ] Cài đặt hoàn tất.${NC}"

# 2. Cấu hình Torrc
sec=30
TORRC="$PREFIX/etc/tor/torrc"
echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nLog notice stdout" > $TORRC

if [ ! -z "$country_code" ]; then
    echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> $TORRC
else
    echo -e "StrictNodes 0" >> $TORRC
fi

# Cấu hình Privoxy
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Khởi động dịch vụ
pkill tor; pkill privoxy; sleep 1
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

# 4. Vòng lặp xoay IP thầm lặng
(
  while true; do
    sleep $sec
    echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    pkill -HUP tor
  done
) &

# 5. Thiết lập mạch và hiện Bảng
echo -e "\n${G}>>> HỆ THỐNG ĐANG HOẠT ĐỘNG <<<${NC}"
echo -e "${C}--------------------------------------------------${NC}"

stdbuf -oL tor 2>/dev/null | while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo $line | grep -oP "\d+%" | head -1)
        if [ ! -z "$percent" ]; then
            printf "\r${B}[ TIẾN TRÌNH ]${NC} Thiết lập mạch Tor: ${Y}%s${NC} " "$percent"
        fi
    fi
    
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -ne "\r\033[K"
        echo -e "${C}┌────────────────────────────────────────────────┐${NC}"
        echo -e "${C}│${NC}  ${G}KẾT NỐI THÀNH CÔNG!${NC}                          ${C}│${NC}"
        echo -e "${C}├────────────────────────────────────────────────┤${NC}"
        echo -e "${C}│${NC}  ${W}HOST:${NC} ${G}127.0.0.1${NC}                               ${C}│${NC}"
        echo -e "${C}│${NC}  ${W}PORT:${NC} ${G}8118${NC}                                    ${C}│${NC}"
        if [ ! -z "$country_code" ]; then
            echo -e "${C}│${NC}  ${W}QUỐC GIA:${NC} ${Y}${country_code^^}${NC}                             ${C}│${NC}"
        else
            echo -e "${C}│${NC}  ${W}QUỐC GIA:${NC} ${Y}TOÀN THẾ GIỚI${NC}                     ${C}│${NC}"
        fi
        echo -e "${C}└────────────────────────────────────────────────┘${NC}"
        break
    fi
done

wait > /dev/null 2>&1
