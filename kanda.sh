#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH TỰ TẠO ---
# Cập nhật: Thêm cơ chế nhảy số mượt hơn
progress() {
    local w=40 p=$1; shift
    printf "\r${B}[%- ${w}s] %d%% ${NC}" "$(printf "#%.0s" $(seq 1 $((p*w/100))))" "$p"
}

clear
echo -e "${Y}--- ĐANG KHỞI TẠO HỆ THỐNG ---${NC}"

# 1. Cài đặt thầm lặng (Đã tách để thanh progress chạy sớm hơn)
progress 10
pkg update -y > /dev/null 2>&1
progress 40
pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
progress 80
mkdir -p $PREFIX/etc/tor
progress 100
echo -e "\n${G}[ DONE ] Cài đặt hoàn tất.${NC}"
sleep 1

# 2. Cấu hình ép xoay gắt (20 GIÂY)
sec=20
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nLearnCircuitBuildTimeout 0\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc

sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Dọn dẹp
pkill tor; pkill privoxy; sleep 1
clear

# 4. Chạy Privoxy NGẦM
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

# 5. Vòng lặp ÉP XOAY NGAY LẬP TỨC
count=0
(
  while true; do
    sleep $sec
    # Gửi lệnh NEWNYM tới ControlPort của Tor để ép đổi IP ngay lập tức
    echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    # Gửi HUP để cập nhật log
    pkill -HUP tor
  done
) &

# 6. Chạy Tor và CẬP NHẬT LOG TẠI CHỖ
echo -e "${G}>>> HỆ THỐNG ĐANG HOẠT ĐỘNG (ÉP XOAY MỖI ${sec}S) <<<${NC}"
echo -e "${C}--------------------------------------------------${NC}"
echo -e "\n"

stdbuf -oL tor 2>/dev/null | grep --line-buffered -E "Bootstrapped|Reloading config" | while read -r line; do
    echo -ne "\033[1A\033[K" 
    
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -e "${G}[ TRẠNG THÁI ]${NC} IP SẴN SÀNG (Đã xoay: ${Y}${count}${NC})"
    elif [[ "$line" == *"Reloading config"* ]]; then
        ((count++))
        echo -e "${Y}[ TRẠNG THÁI ]${NC} ĐANG ÉP XOAY IP MỚI... (Lần: ${G}${count}${NC})"
    elif [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo $line | grep -oP "\d+%" | head -1)
        if [ ! -z "$percent" ]; then
            echo -e "${B}[ TIẾN TRÌNH ]${NC} Đang thiết lập mạch: ${Y}${percent}${NC}"
        fi
    fi
done
