#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
R='\033[1;31m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH DOTS (TẢI DỮ LIỆU) ---
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

# --- BƯỚC NHẬP MÃ QUỐC GIA ---
while true; do
    echo -e "\n${Y}[?] Nhập mã quốc gia (ISO hoặc all)${NC}"
    printf "    Lựa chọn: "
    read input </dev/tty
    
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs)
    
    if [[ "$input_lower" == "all" ]]; then
        country_code=""
        echo -e "${G}>> Chọn: Toàn thế giới.${NC}"
        break
    elif [[ "$input_lower" =~ ^[a-z]{2}$ ]]; then
        country_code="$input_lower"
        echo -e "${G}>> Chọn quốc gia: ${country_code^^}${NC}"
        break
    else
        echo -e "${R}[!] Lỗi: Nhập đúng 2 chữ cái mã quốc gia!${NC}"
    fi
done

echo -e "\n${B}[*] Đang chuẩn bị dịch vụ...${NC}\n"

# 1. Tải dữ liệu (Giữ log)
run_progress 30 0
pkg update -y > /dev/null 2>&1
run_progress 80 31
pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
run_progress 100 81
mkdir -p $PREFIX/etc/tor
echo -e "\n${G}[ DONE ] Đã tải xong dữ liệu.${NC}"

# 2. Cấu hình thầm lặng
sec=30
TORRC="$PREFIX/etc/tor/torrc"
echo -e "ControlPort 9051\nCookieAuthentication 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nLog notice stdout" > $TORRC
[ ! -z "$country_code" ] && echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> $TORRC || echo -e "StrictNodes 0" >> $TORRC

sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Chạy dịch vụ ngầm
pkill tor; pkill privoxy; sleep 1
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

(
  while true; do
    sleep $sec
    echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    pkill -HUP tor
  done
) &

# 4. Hiện log Boot (KHÔNG XOÁ) và hiện Host/Port/Country
echo -e "${B}[*] Đang thiết lập mạch kết nối...${NC}"
stdbuf -oL tor 2>/dev/null | while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo $line | grep -oP "\d+%" | head -1)
        if [ ! -z "$percent" ]; then
            # In đè lên cùng 1 dòng để theo dõi % nhưng không xóa khi xong
            printf "\r${B}[ TIẾN TRÌNH ]${NC} Thiết lập mạch Tor: ${Y}%s${NC} " "$percent"
        fi
    fi
    
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -e "\n" # Xuống dòng để giữ lại log Boot bên trên
        echo -e "${B}HOST:   ${G}127.0.0.1${NC}"
        echo -e "${B}PORT:   ${G}8118${NC}"
        if [ ! -z "$country_code" ]; then
            echo -e "${B}REGION: ${Y}${country_code^^}${NC}"
        else
            echo -e "${B}REGION: ${Y}WORLDWIDE${NC}"
        fi
        break
    fi
done

# Chặn mọi log xoay IP phát sinh sau đó để màn hình sạch
wait > /dev/null 2>&1
