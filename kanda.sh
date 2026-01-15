#!/data/data/com.termux/files/usr/bin/bash

# --- 1. TỰ CÀI LỆNH KANDA VÀO MÁY (CHỈ CHẠY LẦN ĐẦU) ---
if [ ! -f "$PREFIX/bin/kanda" ]; then
    # Phải dùng đúng link RAW để tránh lỗi <!DOCTYPE html>
    curl -Ls is.gd/kandaprx -o $PREFIX/bin/kanda
    chmod +x $PREFIX/bin/kanda
    [ ! -f ~/.bashrc ] && touch ~/.bashrc
    grep -q "alias kanda" ~/.bashrc || echo "alias kanda='kanda'" >> ~/.bashrc
fi

# --- 2. DỌN DẸP DỮ LIỆU CŨ ---
pkill tor; pkill privoxy; sleep 1
rm -rf $PREFIX/var/lib/tor/*

# --- 3. CÀI ĐẶT VÀ CẤU HÌNH ---
pkg update -y && pkg install tor privoxy curl -y
mkdir -p $PREFIX/etc/tor
echo -e "StrictNodes 0\nMaxCircuitDirtiness 60\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc

# Cấu hình Privoxy
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# Thêm hosts
grep -q "kanda.proxy" $PREFIX/etc/hosts || echo "127.0.0.1 kanda.proxy" >> $PREFIX/etc/hosts

# --- 4. THỰC THI (TOR CHẠY SAU CÙNG ĐỂ HIỆN LOG) ---
clear
echo -e "--- ĐANG CHẠY FULL LOG (BẤM CTRL+C ĐỂ DỪNG) ---"
# Chạy Privoxy ngầm trước
privoxy --no-daemon $PREFIX/etc/privoxy/config & 
sleep 1
# Tor chạy sau cùng, chiếm quyền điều khiển màn hình để ní xem log
tor
