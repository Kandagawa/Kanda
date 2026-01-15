#!/data/data/com.termux/files/usr/bin/bash

pkg update -y && pkg install tor privoxy curl -y && \
mkdir -p $PREFIX/etc/tor && \
echo -e "StrictNodes 0\nMaxCircuitDirtiness 60\nCircuitBuildTimeout 5\nLog notice stdout" > $PREFIX/etc/tor/torrc && \
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config && \
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config && \
pkill tor; pkill privoxy; sleep 1; \
clear && echo -e "--- ĐANG CHẠY FULL LOG (BẤM CTRL+C ĐỂ DỪNG) ---" && \
privoxy --no-daemon $PREFIX/etc/privoxy/config & \
tor
