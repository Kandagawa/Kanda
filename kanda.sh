#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH CHẠY MƯỢT (CHỈ 1 DÒNG DUY NHẤT) ---
run_progress() {
    local target=$1
    local current=$2
    local w=40
    for ((i=current; i<=target; i++)); do
        # \r để đưa con trỏ về đầu dòng, ghi đè lên dòng cũ
        printf "\r${Y}[*] Đang tải dữ liệu... ${B}[%- ${w}s] %d%% ${NC}" "$(printf "#%.0s" $(seq 1 $((i*w/100))))" "$i"
        sleep 0.015
    done
}

clear

# 1. Cài đặt thầm lặng với thanh progress duy nhất
run_progress 30 0
pkg update -y > /dev/null 2>&1

run_progress 80 31
pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1

run_progress 100 81
mkdir -p $PREFIX/etc/tor

echo -e "\n${G}[ DONE ] Cấu hình hoàn tất, đang khởi động hệ thống...${NC}"
sleep 1.5

# 2. Cấu hình (30 GIÂY)
sec=30
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc

sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Dọn dẹp
pkill tor; pkill privoxy; sleep 1
clear

# 4. Chạy Privoxy NGẦM
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

# 5. Vòng lặp xoay IP nhẹ nhàng (Sử dụng NEWNYM để đổi IP sạch)
count=0
(
  while true; do
    sleep $sec
    echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    pkill -HUP tor
  done
) &

# 6. Chạy Tor và CẬP NHẬT LOG TẠI CHỖ
echo -e "${G}>>> HỆ THỐNG ĐANG HOẠT ĐỘNG <<<${NC}"
echo -e "${C}--------------------------------------------------${NC}"
echo -e "\n"

stdbuf -oL tor 2>/dev/null | grep --line-buffered -E "Bootstrapped|Reloading config" | while read -r line; do
    # Di chuyển lên 1 dòng và xóa dòng đó để ghi đè log mới
    echo -ne "\033[1A\033[K" 
    
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -e "${G}[ TRẠNG THÁI ]${NC} IP SẴN SÀNG (Đã xoay: ${Y}${count}${NC})"
    elif [[ "$line" == *"Reloading config"* ]]; then
        ((count++))
        echo -e "${Y}[ TRẠNG THÁI ]${NC} ĐANG LÀM MỚI IP... (Lần: ${G}${count}${NC})"
    elif [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo $line | grep -oP "\d+%" | head -1)
        if [ ! -z "$percent" ]; then
            echo -e "${B}[ TIẾN TRÌNH ]${NC} Đang kết nối mạch: ${Y}${percent}${NC}"
        fi
    fi
done
