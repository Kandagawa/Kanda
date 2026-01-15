#!/data/data/com.termux/files/usr/bin/bash

# --- 1. CÀI ĐẶT IM LẶNG (FIX LỖI NO SUCH FILE) ---
setup_kanda() {
    echo -e "\033[0;36m[*] Đang cài đặt hệ thống Kanda... Vui lòng đợi.\033[0m"
    (
        export DEBIAN_FRONTEND=noninteractive
        pkg update -y -qq
        pkg install tor privoxy curl jq -y -qq
    ) > /dev/null 2>&1
    
    # Tải script về lưu trực tiếp vào bin để fix lỗi "No such file"
    curl -Ls is.gd/kandaprx -o $PREFIX/bin/kanda
    chmod +x $PREFIX/bin/kanda
    
    # Tạo alias an toàn
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='kanda'" >> ~/.bashrc
    fi
}

# --- 2. LOGIC CHẠY CHÍNH ---
run_kanda() {
    clear
    echo -e "\033[1;34m╭────────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;34m│\033[1;33m          KANDA PROXY AUTO-ROTATE SYSTEM        \033[1;34m│\033[0m"
    echo -e "\033[1;34m╰────────────────────────────────────────────────╯\033[0m"
    
    read -p " Nhập số giây đổi IP (5-300s): " SEC_INPUT
    if [[ ! "$SEC_INPUT" =~ ^[0-9]+$ ]]; then SEC_INPUT=60; fi
    if [ "$SEC_INPUT" -lt 5 ]; then SEC_INPUT=5; fi
    if [ "$SEC_INPUT" -gt 300 ]; then SEC_INPUT=300; fi

    # Ghi cấu hình chuẩn
    mkdir -p $PREFIX/etc/tor
    echo -e "StrictNodes 0\nMaxCircuitDirtiness $SEC_INPUT\nCircuitBuildTimeout 5\nLog notice file $PREFIX/tmp/tor.log" > $PREFIX/etc/tor/torrc
    
    # Fix lỗi Privoxy
    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config 2>/dev/null
    sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config 2>/dev/null
    echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

    # Bước cực quan trọng: Xóa cache Tor cũ để fix lỗi kẹt 40-50%
    pkill tor; pkill privoxy; sleep 1
    rm -rf $PREFIX/var/lib/tor/*
    rm -f $PREFIX/tmp/tor.log
    
    privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 &
    tor > /dev/null 2>&1 &

    clear
    echo -e "\033[1;32m--- KANDA PROXY ĐANG HOẠT ĐỘNG ---\033[0m"
    echo -e "\033[1;36mChu kỳ: ${SEC_INPUT}s | Bấm Ctrl+C để dừng\033[0m"
    echo "--------------------------------------------------"

    while true; do
        if [ -f "$PREFIX/tmp/tor.log" ]; then
            PROGRESS=$(grep -o "Bootstrapped [0-9]*%" $PREFIX/tmp/tor.log | tail -1)
            if [ ! -z "$PROGRESS" ]; then
                echo -ne "\r\033[1;33m[>] Tiến độ: $PROGRESS... \033[0m"
                if [[ "$PROGRESS" == "Bootstrapped 100%" ]]; then
                    echo -ne "\r\033[1;32m[OK] Đã thông mạch! Chờ 2s ổn định...          \033[0m"
                    sleep 2
                    IP_INFO=$(curl -s -x http://127.0.0.1:8118 "https://api.ipify.org" 2>/dev/null)
                    if [ ! -z "$IP_INFO" ]; then
                        echo -e "\n\033[1;35m[🌐] IP HIỆN TẠI: \033[1;32m$IP_INFO\033[0m"
                        echo "--------------------------------------------------"
                    fi
                    > $PREFIX/tmp/tor.log
                    sleep $SEC_INPUT
                fi
            fi
        fi
        sleep 1
    done
}

# --- 3. KIỂM TRA ---
if [[ "$0" == *"/bin/kanda" ]]; then
    run_kanda
else
    setup_kanda
    clear
    echo -e "\033[0;32m[✔] Cài đặt xong! Hãy gõ lệnh:\033[0m"
    echo -e "\033[1;33msource ~/.bashrc && kanda\033[0m"
fi
