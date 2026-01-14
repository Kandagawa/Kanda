#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Ẩn log hệ thống rác và hiện thanh tiến độ khi cài đặt
export DEBIAN_FRONTEND=noninteractive
echo "quiet \"2\";" > $PREFIX/etc/apt/apt.conf.d/99quiet
echo "Dpkg::Progress-Fancy \"1\";" > $PREFIX/etc/apt/apt.conf.d/99progressbar

clear
echo -e "${CYAN}[*] Đang tối ưu hệ thống & Cài đặt gói (Vui lòng chờ...)${NC}"
pkg update -y && pkg install tor privoxy curl -y -qq

# 2. Giao diện thiết lập thời gian
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

# 4. Tạo lệnh 'kanda' với Log không chồng lấn và Fix lỗi kết nối
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
echo -e "\${CYAN}[*] Đang khởi động Tor... (Có thể mất 15-30s)\${NC}"
tor > /dev/null 2>&1 &

# Chờ Tor khởi động thực sự (Check cổng 9050)
while ! nc -z localhost 9050; do   
  sleep 1
done

privoxy --no-daemon \$PREFIX/etc/privoxy/config > /dev/null 2>&1 &

echo -e "\${GREEN}[+] HỆ THỐNG ĐÃ SẴN SÀNG!\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"
echo -e "💡 Proxy: \${CYAN}127.0.0.1:8118\${NC}"
echo -e "⏱ Xoay IP: \${CYAN}$SECONDS giây/lần\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Kiểm tra IP lần đầu (có cơ chế thử lại nếu Tor chưa xong)
echo -e "\${YELLOW}[*] Đang lấy danh tính IP...\${NC}"
MAX_RETRIES=5
for i in \$(seq 1 \$MAX_RETRIES); do
    CURRENT_IP=\$(curl -s --max-time 10 -x http://127.0.0.1:8118 https://api.ipify.org)
    if [ ! -z "\$CURRENT_IP" ]; then break; fi
    echo -e "\${RED}[!] Đang kết nối lại mạng Tor (Lần \$i)...\${NC}"
    sleep 5
done

if [ -z "\$CURRENT_IP" ]; then
    echo -e "\${RED}[!] Lỗi: Mạng Tor chậm, vui lòng gõ lại lệnh 'kanda'.\${NC}"
else
    LOCATION=\$(curl -s -x http://127.0.0.1:8118 https://ipapi.co/\$CURRENT_IP/country_name/)
    echo -e "🌍 IP: \${GREEN}\$CURRENT_IP\${NC} | 📍 Quốc gia: \${GREEN}\$LOCATION\${NC}"
fi
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Vòng lặp Log sạch (Không bị chồng dòng)
while true; do
    for (( i=\$SECONDS; i>0; i-- )); do
        echo -ne "\${YELLOW}[Sẵn sàng] - Đợi xoay IP sau: \${RED}\${i}s \${NC}\r"
        sleep 1
    done
    NEW_IP=\$(curl -s --max-time 10 -x http://127.0.0.1:8118 https://api.ipify.org)
    if [ ! -z "\$NEW_IP" ]; then
        echo -e "\n\${GREEN}[🔄] \$(date +%H:%M:%S) - ĐÃ ĐỔI IP MỚI: \$NEW_IP\${NC}"
    fi
done
EOT

chmod +x $PREFIX/bin/kanda
clear
echo -e "${GREEN}CÀI ĐẶT HOÀN TẤT!${NC}"
echo -e "Bây giờ bạn hãy gõ: ${YELLOW}kanda${NC}"
