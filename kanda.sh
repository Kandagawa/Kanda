#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 1. Cài đặt các gói
pkg update -y && pkg install tor privoxy curl -y

# 2. Giao diện thiết lập
clear
echo -e "${CYAN}=======================================${NC}"
echo -e "${YELLOW}    THIẾT LẬP KANDA PROXY AUTO-ROTATE   ${NC}"
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}[?] Nhập số giây muốn xoay IP (10s - 300s):${NC}"
read -p ">> " SECONDS

if [ -z "$SECONDS" ] || [ "$SECONDS" -lt 10 ]; then SECONDS=10; fi
if [ "$SECONDS" -gt 300 ]; then SECONDS=300; fi

# 3. Cấu hình hệ thống
mkdir -p $PREFIX/etc/tor
echo -e "StrictNodes 0\nMaxCircuitDirtiness $SECONDS\nCircuitBuildTimeout 5" > $PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 4. Tạo lệnh 'kanda' với giao diện Log đẹp
cat <<EOT > $PREFIX/bin/kanda
#!/data/data/com.termux/files/usr/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pkill tor
pkill privoxy
echo -e "\${CYAN}[*] Đang khởi động hệ thống Tor & Privoxy...\${NC}"
tor > /dev/null 2>&1 &
sleep 2
privoxy --no-daemon \$PREFIX/etc/privoxy/config > /dev/null 2>&1 &

echo -e "\${GREEN}[+] ĐÃ KÍCH HOẠT PROXY THÀNH CÔNG!\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"
echo -e "💡 Proxy: \${CYAN}127.0.0.1:8118\${NC}"
echo -e "⏱ Xoay IP: \${CYAN}$SECONDS giây/lần\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Kiểm tra IP thực tế sau khi bật
echo -e "\${YELLOW}[*] Đang kiểm tra IP hiện tại...\${NC}"
sleep 3
CURRENT_IP=\$(curl -s -x http://127.0.0.1:8118 https://api.ipify.org)
LOCATION=\$(curl -s -x http://127.0.0.1:8118 https://ipapi.co/\$CURRENT_IP/country_name/)

if [ -z "\$CURRENT_IP" ]; then
    echo -e "\${RED}[!] Lỗi: Không lấy được IP. Vui lòng thử lại!\${NC}"
else
    echo -e "🌍 IP Của Bạn: \${GREEN}\$CURRENT_IP\${NC}"
    echo -e "📍 Quốc Gia: \${GREEN}\$LOCATION\${NC}"
fi
echo -e "\${YELLOW}---------------------------------------\${NC}"
echo -e "\${CYAN}(Bấm Ctrl+C nếu muốn quay lại terminal)\${NC}"

# Hiển thị đồng hồ thời gian thực và cập nhật IP mỗi \$SECONDS giây
while true; do
    echo -ne "\${YELLOW}[Sẵn sàng] - \$(date +%H:%M:%S) - Đang chờ xoay IP...\r\${NC}"
    sleep \$SECONDS
    NEW_IP=\$(curl -s -x http://127.0.0.1:8118 https://api.ipify.org)
    echo -e "\n\${GREEN}[🔄] ĐÃ XOAY IP MỚI: \$NEW_IP\${NC}"
done
EOT

chmod +x $PREFIX/bin/kanda

clear
echo -e "${GREEN}CÀI ĐẶT HOÀN TẤT!${NC}"
echo -e "Gõ lệnh ${YELLOW}kanda${NC} để bắt đầu."
