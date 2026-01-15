#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC ---
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'

# --- HÀM THANH TIẾN TRÌNH DOTS ---
run_progress() {
    local target=$1
    local current=$2
    local w=25
    for ((i=current; i<=target; i++)); do
        local filled=$((i*w/100))
        local empty=$((w-filled))
        local bar_filled=$(printf '●%.0s' $(seq 1 $filled 2>/dev/null))
        local bar_empty=$(printf '○%.0s' $(seq 1 $empty 2>/dev/null))
        printf "\r${Y}[*] Đang tải dữ liệu... ${C}[${G}%s${W}%s${C}] ${Y}%d%%${NC}" "$bar_filled" "$bar_empty" "$i"
        sleep 0.01
    done
}

clear
echo -e "${C}>>> KHỞI TẠO CẤU HÌNH HỆ THỐNG <<<${NC}"

# 1. Tải dữ liệu (Giữ log)
run_progress 30 0
pkg update -y > /dev/null 2>&1
run_progress 80 31
pkg install tor privoxy curl netcat-openbsd -y > /dev/null 2>&1
run_progress 100 81
mkdir -p $PREFIX/etc/tor
echo -e "\n${G}[ DONE ] Cài đặt hoàn tất.${NC}"

# 2. Cấu hình
sec=30
echo -e "StrictNodes 0\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 10\nControlPort 9051\nCookieAuthentication 0\nLog notice stdout" > $PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
sed -i '/forward-socks5t/d' $PREFIX/etc/privoxy/config
echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Khởi động dịch vụ ngầm
pkill tor; pkill privoxy; sleep 1
privoxy --no-daemon $PREFIX/etc/privoxy/config > /dev/null 2>&1 & 

# 4. Vòng lặp xoay IP (ẨN HOÀN TOÀN LOG)
(
  while true; do
    sleep $sec
    echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 > /dev/null 2>&1
    pkill -HUP tor
  done
) &

# 5. Thiết lập mạch và hiện Bảng Host:Port
echo -e "\n${G}>>> HỆ THỐNG ĐANG HOẠT ĐỘNG <<<${NC}"
echo -e "${C}--------------------------------------------------${NC}"

stdbuf -oL tor 2>/dev/null | while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo $line | grep -oP "\d+%" | head -1)
        if [ ! -z "$percent" ]; then
            printf "\r${B}[ TIẾN TRÌNH ]${NC} Thiết lập mạch kết nối: ${Y}%s${NC} " "$percent"
        fi
    fi
    
    if [[ "$line" == *"Bootstrapped 100%"* ]]; then
        echo -ne "\r\033[K" # Xóa dòng tiến trình %
        echo -e "${C}┌────────────────────────────────────────────────┐${NC}"
        echo -e "${C}│${NC}  ${G}KẾT NỐI THÀNH CÔNG!${NC}                          ${C}│${NC}"
        echo -e "${C}├────────────────────────────────────────────────┤${NC}"
        echo -e "${C}│${NC}  ${W}HOST:${NC} ${G}127.0.0.1${NC}                               ${C}│${NC}"
        echo -e "${C}│${NC}  ${W}PORT:${NC} ${G}8118${NC}                                    ${C}│${NC}"
        echo -e "${C}└────────────────────────────────────────────────┘${NC}"
        break
    fi
done

# Chặn mọi log sau khi hoàn tất
wait > /dev/null 2>&1
