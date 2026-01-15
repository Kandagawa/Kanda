#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH KIỂU MỚI (DOTS STYLE) ---
run_progress() {
    local target=$1
    local current=$2
    local w=25 # Độ dài thanh ngắn lại cho tinh tế
    for ((i=current; i<=target; i++)); do
        local filled=$((i*w/100))
        local empty=$((w-filled))
        
        # Tạo chuỗi bong bóng đã nạp và chưa nạp
        local bar_filled=$(printf '●%.0s' $(seq 1 $filled 2>/dev/null))
        local bar_empty=$(printf '○%.0s' $(seq 1 $empty 2>/dev/null))
        
        # In ra màn hình trên 1 dòng duy nhất
        printf "\r${Y}[*] Đang tải dữ liệu... ${C}[${G}%s${W}%s${C}] ${Y}%d%%${NC}" "$bar_filled" "$bar_empty" "$i"
        sleep 0.015
    done
}

clear

# 1. Cài đặt thầm lặng (Giao diện mới)
run_progress 30 0
pkg update -y > /dev/null 2>&1
run_progress 80 31
pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
run_progress 100 81
mkdir -p $PREFIX/etc/tor

echo -e "\n${G}[ DONE ] Cấu hình hoàn tất!${NC}"
sleep 1

# 2. Cấu hình (30 GIÂY)
sec=30
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc

sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Dọn dẹp
pkill tor; pkill privoxy; sleep 1
clear

# 4. Chạy Privoxy NGẦM
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

# 5. Vòng lặp xoay IP thầm lặng
(
  while true; do
    sleep $sec
    echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    pkill -HUP tor
  done
) &

# 6. Chạy Tor và HIỂN THỊ THÔNG TIN CỐ ĐỊNH
echo -e "${G}>>> HỆ THỐNG ĐÃ KÍCH HOẠT XOAY IP TỰ ĐỘNG <<<${NC}"
echo -e "${C}--------------------------------------------------${NC}"
echo -e "${Y}[ TRẠNG THÁI ]${NC} Đang thiết lập mạch kết nối..."

stdbuf -oL tor 2>/dev/null | grep --line-buffered -E "Bootstrapped 100%" | while read -r line; do
    echo -ne "\033[1A\r\033[K" 
    echo -e "${G}[ OK ]${NC} Kết nối mạch Tor thành công!"
    echo -e "${B}[ PROXY ]${NC} Host: ${G}127.0.0.1${NC} | Port: ${G}8118${NC}"
    echo -e "${C}--------------------------------------------------${NC}"
    echo -e "${Y}>> IP sẽ tự động xoay ngầm mỗi ${sec} giây.${NC}"
    echo -e "${Y}>> Màn hình tĩnh để tiết kiệm tài nguyên.${NC}"
    break
done

wait
