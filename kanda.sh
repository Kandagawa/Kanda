#!/data/data/com.termux/files/usr/bin/bash

# Fix lỗi No such file .bashrc
[ ! -f ~/.bashrc ] && touch ~/.bashrc

# Tự ghim lệnh kanda vào hệ thống
if [ ! -f "$PREFIX/bin/kanda" ]; then
    curl -Ls is.gd/kandaprx -o $PREFIX/bin/kanda
    chmod +x $PREFIX/bin/kanda
    grep -q "alias kanda" ~/.bashrc || echo "alias kanda='kanda'" >> ~/.bashrc
fi

# Dọn dẹp dữ liệu Tor cũ (Xóa sạch thay vì xóa app)
pkill tor; pkill privoxy; sleep 1
rm -rf $PREFIX/var/lib/tor/*

# 100% MÃ NGUỒN GỐC CỦA NÍ
pkg update -y && pkg install tor privoxy curl -y && \
mkdir -p $PREFIX/etc/tor && \
echo -e "StrictNodes 0\nMaxCircuitDirtiness 60\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc && \
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config && \
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config && \
grep -q "kanda.proxy" $PREFIX/etc/hosts || echo "127.0.0.1 kanda.proxy" >> $PREFIX/etc/hosts && \
clear && echo -e "--- ĐANG CHẠY FULL LOG (BẤM CTRL+C ĐỂ DỪNG) ---" && \
privoxy --no-daemon $PREFIX/etc/privoxy/config & \
tor
