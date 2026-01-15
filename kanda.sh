#!/data/data/com.termux/files/usr/bin/bash

# 1. Hàm cài đặt (Ẩn các dòng log pkg rác)
setup_kanda() {
    echo -e "\033[0;36m[*] Đang kiểm tra và tối ưu gói hệ thống...\033[0m"
    export DEBIAN_FRONTEND=noninteractive
    pkg update -y -qq > /dev/null 2>&1
    pkg install tor privoxy curl net-tools jq -y -qq > /dev/null 2>&1
    
    # Tạo alias để gõ 'kanda' là chạy từ GitHub
    if ! grep -q "alias kanda" ~/.bashrc; then
        echo "alias kanda='bash <(curl -Ls is.gd/kandaprx)'" >> ~/.bashrc
    fi
}

# 2. Giao diện chào mừng & Nhập liệu
clear
echo -e "\033[1;34m╭────────────────────────────────────────────────╮\033[0m"
echo -e "\033[1;34m│\033[1;33m          KANDA PROXY AUTO-ROTATE SYSTEM        \033[1;34m│\033[0m"
echo -e "\033[1;34m╰────────────────────────────────────────────────╯\033[0m"
echo -e "\033[0;32m[?] Nhập số giây xoay IP (5-300s)\033[0m"
read -p ">> " SEC_INPUT

# Ràng buộc thời gian (Mặc định 60s nếu nhập sai)
if [[ ! "$SEC_INPUT" =~ ^[0-9]+$ ]]; then SEC_INPUT=60; fi
if [ "$SEC_INPUT" -lt 5 ]; then SEC_INPUT=5; fi
if [ "$SEC_INPUT" -gt 300 ]; then SEC_INPUT=300; fi

# 3. Thực hiện cài đặt & Cấu hình (Dùng đúng mã của ní)
setup_kanda
mkdir -p $PREFIX/etc/tor

# Ghi cấu hình Tor (Giữ nguyên Log notice stdout để ní soi lỗi)
echo -e "StrictNodes 0\nMaxCircuitDirtiness $SEC_INPUT\nCircuitBuildTimeout 5\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc

# Cấu hình Privoxy & Hosts
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config
grep -q "kanda.proxy" $PREFIX/etc/hosts || echo "127.0.0.1 kanda.proxy" >> $PREFIX/etc/hosts

# 4. Dọn dẹp & Khởi chạy
pkill tor; pkill privoxy; sleep 1
clear

# Chạy Privoxy ngầm
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 &

# Hàm hiển thị IP hiện tại (Chạy song song với Log Tor)
monitor_ip() {
    echo -e "\033[1;32m--- HỆ THỐNG ĐANG HOẠT ĐỘNG (CHU KỲ: ${SEC_INPUT}s) ---\033[0m"
    echo -e "\033[1;36mProxy: kanda.proxy:8118 | Bấm Ctrl+C để dừng\033[0m"
    echo -e "\033[1;34m--------------------------------------------------\033[0m"
    while true; do
        # Lấy IP quốc tế qua proxy để chứng minh đã đổi IP
        IP_INFO=$(curl -s -x http://127.0.0.1:8118 "https://ipapi.co/json/" | jq -r '.ip + " [" + .country_name + "]"' 2>/dev/null)
        if [ ! -z "$IP_INFO" ] && [[ "$IP_INFO" != *"null"* ]]; then
            echo -e "\033[1;33m[🌐] IP HIỆN TẠI: \033[1;32m$IP_INFO\033[0m"
        fi
        sleep $SEC_INPUT
    done
}

# Chạy trình giám sát IP trong luồng riêng
monitor_ip &

# Chạy Tor trực tiếp để in Log Bootstrapped đẹp mắt đúng ý ní
tor
