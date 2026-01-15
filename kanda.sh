#!/data/data/com.termux/files/usr/bin/bash

# 1. Cài đặt thầm lặng
pkg update -y > /dev/null 2>&1 && pkg install tor privoxy curl -y > /dev/null 2>&1
mkdir -p $PREFIX/etc/tor

# 2. Cấu hình (Cố định 30s)
sec=30
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Dọn dẹp
pkill tor; pkill privoxy; sleep 1
clear

# 4. Chạy Privoxy ngầm
privoxy --no-daemon $PREFIX/etc/privoxy/config & 

# 5. Vòng lặp xoay IP ngầm
(
  while true; do
    sleep $sec
    pkill -HUP tor
  done
) &

# 6. Chạy Tor và LỌC LOG ĐẸP
echo -e "\033[1;32m>>> HỆ THỐNG ĐÃ SẴN SÀNG - ĐANG THEO DÕI XOAY IP <<<\033[0m"
echo -e "\033[1;36m--------------------------------------------------\033[0m"

tor | grep --line-buffered -E "Bootstrapped|Reloading config|resetting internal state" | while read -r line; do
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -e "\033[1;32m[ OK ]\033[0m Kết nối thành công! IP đã sẵn sàng."
    elif [[ "$line" == *"Reloading config"* ]]; then
        echo -e "\033[1;33m[ ROTATE ]\033[0m Đang tiến hành xoay IP mới (mỗi 30s)..."
    elif [[ "$line" == *"Bootstrapped"* ]]; then
        # Hiện tiến trình kết nối theo phần trăm
        percent=$(echo $line | grep -oP "\d+%" )
        echo -e "\033[1;34m[ PROGRESS ]\033[0m Đang thiết lập mạch: $percent"
    fi
done
