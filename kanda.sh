#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Ép hệ thống ẩn toàn bộ Log Mirror rác và hiện thanh tiến độ chuẩn
export DEBIAN_FRONTEND=noninteractive
# Cấu hình APT im lặng và hiện thanh tiến độ đẹp
mkdir -p $PREFIX/etc/apt/apt.conf.d
echo "Dpkg::Progress-Fancy \"1\";" > $PREFIX/etc/apt/apt.conf.d/99progressbar
echo "quiet \"2\";" > $PREFIX/etc/apt/apt.conf.d/99quiet
echo "APT::Color \"1\";" >> $PREFIX/etc/apt/apt.conf.d/99quiet

clear
echo -e "${CYAN}[*] Đang tối ưu hệ thống & Cài đặt... (Vui lòng đợi thanh tiến độ)${NC}"
# Sử dụng tham số -y -qq để chặn đứng log mirror hiện ra màn hình
apt-get update -y -qq > /dev/null 2>&1
apt-get install tor privoxy curl net-tools -y -qq

# 2. Giao diện thiết lập
clear
echo -e "${CYAN}=======================================${NC}"
echo -e "${YELLOW}    THIẾT LẬP KANDA PROXY AUTO-ROTATE   ${NC}"
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}[?] Nhập số giây muốn xoay IP (10 - 300):${NC}"
read -p ">> " SECONDS

if [ -z "$SECONDS" ] || [ "$SECONDS" -lt 10 ]; then SECONDS=10; fi
if [ "$SECONDS" -gt 300 ]; then SECONDS=300; fi

# 3. Cấu hình hệ thống
mkdir -p $PREFIX/etc/tor
echo -e "StrictNodes 0\nMaxCircuitDirtiness $SECONDS\nCircuitBuildTimeout 10" > $PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 4. Tạo lệnh 'kanda' - Fix lỗi IP & Log chồng lấn
cat <<EOT > $PREFIX/bin/kanda
#!/data/data/com.termux/files/usr/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pkill tor
pkill privoxy
clear
echo -e "\${CYAN}[*] Đang khởi động mạng Tor... (Đợi đạt 100%)\${NC}"

# Chạy Tor ngầm và theo dõi tiến độ tải
tor > /data/data/com.termux/files/usr/tmp/tor.log 2>&1 &

# Vòng lặp đợi Tor đạt 100% (Fix lỗi không lấy được IP của bạn)
while true; do
    if grep -q "Bootstrapped 100%" /data/data/com.termux/files/usr/tmp/tor.log; then
        echo -e "\${GREEN}[+] Mạng Tor đã tải xong 100%!\${NC}"
        break
    fi
    # Hiển thị tiến độ từ log của Tor ra màn hình cho đẹp
    PROGRESS=\$(grep -o "Bootstrapped [0-9]*%" /data/data/com.termux/files/usr/tmp/tor.log | tail -1)
    echo -ne "\${YELLOW}[>] Đang kết nối: \${PROGRESS}...\r\${NC}"
    sleep 1
done

privoxy --no-daemon \$PREFIX/etc/privoxy/config > /dev/null 2>&1 &

echo -e "\${YELLOW}---------------------------------------\${NC}"
echo -e "💡 Proxy: \${CYAN}127.0.0.1:8118\${NC}"
echo -e "⏱ Xoay IP: \${CYAN}$SECONDS giây/lần\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Kiểm tra IP thực tế (Đã có Tor 100% nên chắc chắn thành công)
echo -e "\${YELLOW}[*] Đang xác thực IP...\${NC}"
CURRENT_IP=\$(curl -s --max-time 15 -x http://127.0.0.1:8118 https://api.ipify.org)
LOCATION=\$(curl -s -x http://127.0.0.1:8118 https://ipapi.co/\$CURRENT_IP/country_name/)

if [ -z "\$CURRENT_IP" ]; then
    echo -e "\${RED}[!] Lỗi: Mạng ổn định chưa kịp thiết lập. Hãy thử lại.\${NC}"
else
    echo -e "🌍 IP Hiện tại: \${GREEN}\$CURRENT_IP\${NC} | \${GREEN}\$LOCATION\${NC}"
fi
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Vòng lặp đếm ngược (Sạch, không chồng dòng)
while true; do
    for (( i=\$SECONDS; i>0; i-- )); do
        echo -ne "\${YELLOW}[Sẵn sàng] - Đổi IP sau: \${RED}\${i} giây \${NC}\r"
        sleep 1
    done
    NEW_IP=\$(curl -s --max-time 10 -x http://127.0.0.1:8118 https://api.ipify.org)
    if [ ! -z "\$NEW_IP" ]; then
        echo -e "\n\${GREEN}[🔄] \$(date +%H:%M:%S) -> IP MỚI: \$NEW_IP\${NC}"
    fi
done
EOT

chmod +x $PREFIX/bin/kanda
clear
echo -e "${GREEN}CÀI ĐẶT HOÀN TẤT!${NC}"
echo -e "Gõ lệnh ${YELLOW}kanda${NC} để bắt đầu."
