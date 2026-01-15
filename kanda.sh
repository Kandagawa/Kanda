#!/data/data/com.termux/files/usr/bin/bash

# --- 1. GHIM LỆNH VÀO HỆ THỐNG (FIX LỖI KHÔNG NHẬN LỆNH) ---
if [ ! -f "$PREFIX/bin/kanda" ]; then
    # Tải nội dung từ GitHub và lưu trực tiếp thành file kanda
    curl -Ls is.gd/kandaprx -o $PREFIX/bin/kanda
    chmod +x $PREFIX/bin/kanda
    # Cập nhật alias để gõ kanda là chạy file trong bin
    grep -q "alias kanda" ~/.bashrc || echo "alias kanda='$PREFIX/bin/kanda'" >> ~/.bashrc
    source ~/.bashrc
fi

# --- 2. 100% MÃ NGUỒN GỐC ---
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
