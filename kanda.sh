#!/data/data/com.termux/files/usr/bin/bash

# --- 1. HÀM CÀI ĐẶT (CHỈ CHẠY LẦN ĐẦU) ---
# Triệt để ẩn log cài đặt, chỉ để lại thông báo gọn gàng
setup_kanda() {
    echo -e "\033[0;36m[*] Đang cài đặt hệ thống Kanda... Vui lòng đợi.\033[0m"
    (
        export DEBIAN_FRONTEND=noninteractive
        pkg update -y -qq
        pkg install tor privoxy curl jq -y -qq
    ) > /dev/null 2>&1
    
    # Thiết lập lệnh 'kanda' vào hệ thống
    if ! grep -q "alias kanda" ~/.bashrc; then
        echo "alias kanda='bash $PREFIX/bin/kanda'" >> ~/.bashrc
        cp $0 $PREFIX/bin/kanda
        chmod +x $PREFIX/bin/kanda
    fi
}

# --- 2. LOGIC CHẠY CHÍNH (KHI GÕ LỆNH KANDA) ---
run_kanda() {
    clear
    echo -e "\033[1;34m╭────────────────────────────────────────────────╮\033[0m"
    echo -e "\033[1;34m│\033[1;33m          KANDA PROXY AUTO-ROTATE SYSTEM        \033[1;34m│\033[0m"
    echo -e "\033[1;34m╰────────────────────────────────────────────────╯\033[0m"
    
    # Bước 1: Hỏi thời gian xoay IP
    read -p " Nhập số giây đổi IP (5-300s): " SEC_INPUT
    # Kiểm tra tính hợp lệ của thời gian
    if [[ ! "$SEC_INPUT" =~ ^[0-9]+$ ]]; then SEC_INPUT=60; fi
    if [ "$SEC_INPUT" -lt 5 ]; then SEC_INPUT=5; fi
    if [ "$SEC_INPUT" -gt 300 ]; then SEC_INPUT=300; fi

    # Bước 2: Ghi cấu hình (Logic 100% của ní)
    mkdir -p $PREFIX/etc/tor
    echo -e "StrictNodes 0\nMaxCircuitDirtiness $SEC_INPUT\nCircuitBuildTimeout 5\nLog notice file $PREFIX/tmp/tor.log" > $PREFIX/etc/tor/torrc
    
    sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
    sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
    echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

    # Bước 3: Khởi động lại tiến trình
    pkill tor; pkill privoxy; sleep 1
    rm -f $PREFIX/tmp/tor.log
    
    # Chạy ngầm để lấy log tiến độ
    privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 &
    tor > /dev/null 2>&1 &

    clear
    echo -e "\033[1;32m--- KANDA PROXY ĐANG HOẠT ĐỘNG ---\033[0m"
    echo -e "\033[1;36mChu kỳ xoay: ${SEC_INPUT}s | Bấm Ctrl+C để dừng\033[0m"
    echo "--------------------------------------------------"

    # Bước 4: Vòng lặp theo dõi tiến độ Bootstrapped và hiện IP
    while true; do
        if [ -f "$PREFIX/tmp/tor.log" ]; then
            # Lấy tiến độ Bootstrapped từ log của Tor
            PROGRESS=$(grep -o "Bootstrapped [0-9]*%" $PREFIX/tmp/tor.log | tail -1)
            
            if [ ! -z "$PROGRESS" ]; then
                # In tiến trình Bootstrapped trên 1 dòng duy nhất
                echo -ne "\r\033[1;33m[>] Tiến độ hệ thống: $PROGRESS... \033[0m"
                
                # Khi đạt 100%, chờ ổn định rồi mới nhả IP
                if [[ "$PROGRESS" == "Bootstrapped 100%" ]]; then
                    echo -ne "\r\033[1;32m[OK] Đã thông mạch! Đang kết nối IP mới...          \033[0m"
                    
                    # Chờ 2 giây để IP kết nối ổn định như ní yêu cầu
                    sleep 2
                    
                    # Lấy và hiển thị IP quốc tế hiện tại
                    IP_INFO=$(curl -s -x http://127.0.0.1:8118 "https://api.ipify.org" 2>/dev/null)
                    if [ ! -z "$IP_INFO" ]; then
                        echo -e "\n\033[1;35m[🌐] IP QUỐC TẾ HIỆN TẠI: \033[1;32m$IP_INFO\033[0m"
                        echo "--------------------------------------------------"
                    fi
                    
                    # Dọn log cũ để chuẩn bị cho chu kỳ xoay tiếp theo
                    > $PREFIX/tmp/tor.log
                    sleep $SEC_INPUT
                fi
            fi
        fi
        sleep 1
    done
}

# --- 3. KIỂM TRA ĐIỀU KIỆN CHẠY ---
if [ -f "$PREFIX/bin/kanda" ]; then
    # Nếu đã cài đặt (có file 'kanda' trong bin), chạy giao diện chính
    run_kanda
else
    # Nếu chưa cài đặt, tiến hành setup im lặng
    setup_kanda
    clear
    echo -e "\033[0;32m[✔] Cài đặt hoàn tất thành công!\033[0m"
    echo -e "\033[0;33mBây giờ hãy gõ 'source ~/.bashrc' (chỉ lần đầu) và gõ 'kanda' để chạy.\033[0m"
fi
