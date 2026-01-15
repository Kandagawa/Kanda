#!/data/data/com.termux/files/usr/bin/bash

# --- HÀM TỐI ƯU HỆ THỐNG (CHẠY KHI CÀI ĐẶT) ---
setup_kanda() {
    echo -e "\033[0;36m[*] Đang dọn dẹp và tối ưu hệ thống...\033[0m"
    export DEBIAN_FRONTEND=noninteractive
    pkg update -y -qq > /dev/null 2>&1
    pkg install tor privoxy curl net-tools jq -y -qq > /dev/null 2>&1
    
    # Thiết lập alias để gõ 'kanda' là chạy ngay
    if ! grep -q "alias kanda" ~/.bashrc; then
        echo "alias kanda='bash $PREFIX/bin/kanda_proxy'" >> ~/.bashrc
        cp $0 $PREFIX/bin/kanda_proxy
        chmod +x $PREFIX/bin/kanda_proxy
    fi
}

# --- GIAO DIỆN VÀ CHẠY CHÍNH (KHI GÕ LỆNH KANDA) ---
run_kanda() {
    clear
    echo -e "\033[1;34m╭────────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;34m│\033[1;33m          KANDA PROXY AUTO-ROTATE SYSTEM        \033[1;34m│\033[0m"
    echo -e "\033[1;34m╰────────────────────────────────────────────────╯\033[0m"
    
    # Chỉ hỏi thời gian khi gõ lệnh kanda
    read -p " Nhập số giây đổi IP (5-300s): " SEC_INPUT
    if [[ ! "$SEC_INPUT" =~ ^[0-9]+$ ]]; then SEC_INPUT=60; fi
    if [ "$SEC_INPUT" -lt 5 ]; then SEC_INPUT=5; fi
    if [ "$SEC_INPUT" -gt 300 ]; then SEC_INPUT=300; fi

    # Ghi cấu hình chuẩn của bạn
    mkdir -p $PREFIX/etc/tor
    echo -e "StrictNodes 0\nMaxCircuitDirtiness $SEC_INPUT\nCircuitBuildTimeout 5\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc

    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
    grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config
    grep -q "kanda.proxy" $PREFIX/etc/hosts || echo "127.0.0.1 kanda.proxy" >> $PREFIX/etc/hosts

    pkill tor; pkill privoxy; sleep 1
    
    # Khởi chạy Privoxy ngầm
    privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 &
    
    # Hàm hiện IP thực tế giữa Log (Chạy ngầm)
    (
        while true; do
            # Đợi Tor sẵn sàng mới lấy IP
            IP_INFO=$(curl -s -x http://127.0.0.1:8118 "https://api.ipify.org" 2>/dev/null)
            if [ ! -z "$IP_INFO" ]; then
                echo -e "\n\033[1;32m[🌐] IP QUỐC TẾ HIỆN TẠI: $IP_INFO\033[0m\n"
            fi
            sleep $SEC_INPUT
        done
    ) &

    echo -e "\033[1;32m--- ĐANG KHỞI CHẠY TOR (CHỜ 100% ĐỂ CÓ IP MỚI) ---\033[0m"
    # Phơi Log Tor trực tiếp để bạn bắt lỗi
    tor
}

# --- KIỂM TRA TRẠNG THÁI ---
if [ -f "$PREFIX/bin/kanda_proxy" ]; then
    run_kanda
else
    setup_kanda
    echo -e "\033[0;32m[OK] Cài đặt xong! Gõ 'source ~/.bashrc' hoặc mở lại app, sau đó gõ 'kanda' để dùng.\033[0m"
fi
