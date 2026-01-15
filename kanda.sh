#!/data/data/com.termux/files/usr/bin/bash

# 1. Cài đặt và cấu hình ban đầu
pkg update -y && pkg install tor privoxy curl -y
mkdir -p $PREFIX/etc/tor

# FIX LỖI XUNG ĐỘT: Đọc dữ liệu trực tiếp từ terminal (tty)
echo -n "Ní muốn bao nhiêu giây đổi IP một lần? (Ví dụ: 30): "
read sec < /dev/tty

# Kiểm tra nếu ní không nhập gì thì mặc định là 60 giây
if [ -z "$sec" ]; then
  sec=60
fi

# 2. Ghi cấu hình Tor
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc

# 3. Cấu hình Privoxy
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 4. Dọn dẹp tiến trình cũ
pkill tor; pkill privoxy; sleep 1

clear
echo -e "--- ĐANG CHẠY FULL LOG (XOAY IP MỖI $sec GIÂY) ---"

# 5. Chạy Privoxy ngầm
privoxy --no-daemon $PREFIX/etc/privoxy/config & 

# 6. Vòng lặp ngầm để ép xoay IP (chạy background)
(
  while true; do
    sleep $sec
    pkill -HUP tor
  done
) &

# 7. Tor chạy sau cùng để hiện FULL LOG
tor
