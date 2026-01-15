#!/data/data/com.termux/files/usr/bin/bash

# 1. Hàm cài đặt (Ẩn log rác)
setup_system() {
    echo -e "\033[0;36m[*] Đang tối ưu hệ thống và kiểm tra gói...\033[0m"
    export DEBIAN_FRONTEND=noninteractive
    pkg update -y -qq > /dev/null 2>&1
    pkg install tor privoxy curl net-tools jq -y -qq > /dev/null 2>&1
    
    # Tạo bí danh (alias)
    if ! grep -q "alias kanda" ~/.bashrc; then
        echo "alias kanda='bash <(curl -Ls is.gd/kandaprx)'" >> ~/.bashrc
    fi
}

# 2. Giao diện nhập liệu
clear
echo -e "\033[1;34m╭────────────────────────────────────────────────╮\033[0m"
echo -e "\033[1;34m│\033[1;33m          KANDA PROXY AUTO-ROTATE SYSTEM        \033[1;34m│\033[0m"
echo -e "\033[1;34m╰────────────────────────────────────────────────╯\033[0m"
echo -e "\033[0;32m[?] Nhập số giây đổi IP (5-300s)\033[0m"
read -p ">> " SEC_INPUT

# Kiểm tra điều kiện
if [[ ! "$SEC_INPUT" =~ ^[0-9]+$ ]]; then SEC_INPUT=60; fi
if [ "$SEC_INPUT" -lt 5 ]; then SEC_INPUT=5; fi
if [ "$SEC_INPUT" -gt 300 ]; then SEC_INPUT=300; fi

# 3. Cấu hình hệ thống
setup_system
mkdir -p $PREFIX/etc/tor
echo -e "StrictNodes 0\nMaxCircuitDirtiness $SEC_INPUT\nCircuitBuildTimeout 5\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc

sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config
grep -q "kanda.proxy" $PREFIX/etc/hosts || echo "127.0.0.1 kanda.proxy" >> $PREFIX/etc/hosts

# 4. Khởi chạy tiến trình
pkill tor; pkill privoxy; sleep 1
clear

# Chạy Privoxy ngầm
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 &

# Hàm hiển thị IP (Chạy ngầm để không đè log)
show_ip_status() {
    echo -e "\033[1;32m--- HỆ THỐNG ĐÃ BẮT ĐẦU ---\033[0m"
    echo -e "\033[1;36mProxy: kanda.proxy:8118 | Chu kỳ: ${SEC_INPUT}s\033[0m"
    echo -e "\033[1;34m--------------------------------------------------\033[0m"
    while true; do
        # Lấy IP qua proxy
        IP_INFO=$(curl -s -x http://127.0.0.1:8118 "https://ipapi.co/json/" | jq -r '.ip + " [" + .country_name + "]"' 2>/dev/null)
        if [ ! -z "$IP_INFO" ] && [[ "$IP_INFO" != *"null"* ]]; then
            echo -e "\033[1;33m[🌐] IP HIỆN TẠI: \033[1;32m$IP_INFO\033[0m"
        fi
        sleep $SEC_INPUT
    done
}

# Chạy hàm hiện IP trong một luồng riêng để log Tor trôi bên dưới
show_ip_status &

# Chạy Tor chính thức (Hiện Log trực tiếp)
tor
