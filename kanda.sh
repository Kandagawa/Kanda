#!/data/data/com.termux/files/usr/bin/bash

# --- Tự động cài lệnh kanda vào hệ thống nếu chưa có ---
if [ ! -f "$PREFIX/bin/kanda" ]; then
    curl -Ls is.gd/kandaprx -o $PREFIX/bin/kanda
    chmod +x $PREFIX/bin/kanda
    grep -q "alias kanda" ~/.bashrc || echo "alias kanda='kanda'" >> ~/.bashrc
fi

# --- 100% MÃ NGUỒN CỦA NÍ ---
pkg update -y && pkg install tor privoxy curl -y && \
mkdir -p $PREFIX/etc/tor && \
echo -e "StrictNodes 0\nMaxCircuitDirtiness 60\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc && \
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config && \
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config && \
grep -q "kanda.proxy" $PREFIX/etc/hosts || echo "127.0.0.1 kanda.proxy" >> $PREFIX/etc/hosts && \
pkill tor; pkill privoxy; sleep 1; \
clear && echo -e "--- ĐANG CHẠY FULL LOG (BẤM CTRL+C ĐỂ DỪNG) ---" && \
privoxy --no-daemon $PREFIX/etc/privoxy/config & \
tor
