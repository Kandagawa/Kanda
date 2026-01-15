#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH TỰ TẠO ---
progress() {
    local w=40 p=$1; shift
    printf "\r${B}[%- ${w}s] %d%% ${NC}" "$(printf "#%.0s" $(seq 1 $((p*w/100))))" "$p"
}

clear
echo -e "${Y}--- ĐANG KHỞI TẠO HỆ THỐNG ---${NC}"

# 1. Cài đặt thầm lặng
(
    pkg update -y > /dev/null 2>&1 && progress 30
    pkg install tor privoxy curl -y > /dev/null 2>&1 && progress 70
    mkdir -p $PREFIX/etc/tor && progress 100
    echo -e "\n"
)

# 2. Cấu hình
sec=30
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Dọn dẹp
pkill tor; pkill privoxy; sleep 1
clear

# 4. Chạy Privoxy NGẦM HOÀN TOÀN (Fix lỗi chồng log)
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

# 5. Vòng lặp xoay IP ngầm
(
  while true; do
    sleep $sec
    pkill -HUP tor
  done
) &

# 6. Chạy Tor và LỌC LOG SIÊU SẠCH
echo -e "${G}>>> HỆ THỐNG ĐÃ SẴN SÀNG - ĐANG THEO DÕI XOAY IP <<<${NC}"
echo -e "${C}--------------------------------------------------${NC}"

# Dùng stdbuf để giải quyết việc delay log và lọc sạch rác
stdbuf -oL tor 2>/dev/null | grep --line-buffered -E "Bootstrapped|Reloading config" | while read -r line; do
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -e "${G}[ OK ]${NC} Kết nối thành công! IP đã sẵn sàng."
    elif [[ "$line" == *"Reloading config"* ]]; then
        echo -e "${Y}[ ROTATE ]${NC} Đang tiến hành xoay IP mới (mỗi 30s)..."
    elif [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo $line | grep -oP "\d+%" | head -1)
        # Chỉ in tiến trình nếu có %
        if [ ! -z "$percent" ]; then
            echo -e "${B}[ PROGRESS ]${NC} Đang thiết lập mạch: $percent"
        fi
    fi
done
