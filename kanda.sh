#!/data/data/com.termux/files/usr/bin/bash

# Cài đặt và cấu hình
pkg update -y && pkg install tor privoxy curl -y
mkdir -p $PREFIX/etc/tor

# Hỏi ní muốn bao nhiêu giây xoay 1 lần
echo -n "Ní muốn bao nhiêu giây đổi IP một lần? (Ví dụ: 30): "
read sec

# Ghi cấu hình Tor (MaxCircuitDirtiness để hỗ trợ xoay)
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc

# Cấu hình Privoxy
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
# Xóa dòng cũ nếu có để tránh trùng lặp
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# Dọn dẹp tiến trình cũ
pkill tor; pkill privoxy; sleep 1

clear
echo -e "--- ĐANG CHẠY FULL LOG (XOAY IP MỖI $sec GIÂY) ---"

# 1. Chạy Privoxy ngầm
privoxy --no-daemon $PREFIX/etc/privoxy/config & 

# 2. Vòng lặp ngầm để ÉP Tor xoay IP đúng số giây ní chọn
(
  while true; do
    sleep $sec
    pkill -HUP tor
    # Không hiện thông báo ở đây để tránh đè lên Log Tor của ní
  done
) &

# 3. Tor chạy sau cùng để ní nhìn LOG
tor
