#!/data/data/com.termux/files/usr/bin/bash

# 1. Cài đặt các gói cần thiết
pkg update -y && pkg install tor privoxy curl -y
mkdir -p $PREFIX/etc/tor

# 2. Cố định thời gian xoay IP là 30 giây
sec=30

# 3. Ghi cấu hình Tor (MaxCircuitDirtiness hỗ trợ xoay tự động)
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc

# 4. Cấu hình Privoxy để chạy cùng Tor
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 5. Dọn dẹp các tiến trình cũ để tránh bị kẹt
pkill tor; pkill privoxy; sleep 1

clear
echo -e "--- ĐANG CHẠY FULL LOG (TỰ XOAY IP MỖI $sec GIÂY) ---"

# 6. Chạy Privoxy dưới nền
privoxy --no-daemon $PREFIX/etc/privoxy/config & 

# 7. Vòng lặp ép Tor xoay IP ngay lập tức mỗi 30 giây
(
  while true; do
    sleep $sec
    pkill -HUP tor
  done
) &

# 8. Tor chạy sau cùng để ní theo dõi LOG thực tế
tor
