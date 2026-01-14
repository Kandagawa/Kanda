#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Tối ưu hệ thống im lặng tuyệt đối
export DEBIAN_FRONTEND=noninteractive
mkdir -p $PREFIX/etc/apt/apt.conf.d
echo "Dpkg::Progress-Fancy \"1\";" > $PREFIX/etc/apt/apt.conf.d/99progressbar
echo "quiet \"2\";" > $PREFIX/etc/apt/apt.conf.d/99quiet

clear
echo -e "${CYAN}[*] Đang cài đặt gói hệ thống... (Vui lòng đợi)${NC}"
# Cài đặt im lặng, không hiện log mirror rác
pkg update -y -qq > /dev/null 2>&1
pkg install tor privoxy curl net-tools -y -qq

# 2. Giao diện thiết lập thời gian (ĐẢM BẢO HỎI NGƯỜI DÙNG)
clear
echo -e "${CYAN}=======================================${NC}"
echo -e "${YELLOW}    THIẾT LẬP KANDA PROXY AUTO-ROTATE   ${NC}"
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}[?] Bạn muốn bao nhiêu giây đổi IP một lần?${NC}"
echo -e "${YELLOW}(Nhập số từ 10 đến 300, mặc định là 10)${NC}"
read -p ">> " SECONDS

# Kiểm tra dữ liệu nhập vào
if [[ ! "$SECONDS" =~ ^[0-9]+$ ]] || [ "$SECONDS" -lt 10 ]; then SECONDS=10; fi
if [ "$SECONDS" -gt 300 ]; then SECONDS=300; fi

# 3. Ghi cấu hình hệ thống
mkdir -p $PREFIX/etc/tor
echo -e "StrictNodes 0\nMaxCircuitDirtiness $SECONDS\nCircuitBuildTimeout 10" > $PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 4. Tạo lệnh 'kanda' - Cải tiến hiển thị & Fix lỗi kết nối
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

# Xóa log cũ và chạy Tor ngầm
rm -f \$PREFIX/tmp/tor.log
tor > \$PREFIX/tmp/tor.log 2>&1 &

# Đợi mạng Tor sẵn sàng 100% (Sửa lỗi "Không lấy được IP")
while true; do
    if grep -q "Bootstrapped 100%" \$PREFIX/tmp/tor.log; then
        echo -e "\${GREEN}[+] Mạng Tor đã kết nối thành công 100%!\${NC}"
        break
    fi
    PROGRESS=\$(grep -o "Bootstrapped [0-9]*%" \$PREFIX/tmp/tor.log | tail -1)
    echo -ne "\${YELLOW}[>] Tiến độ: \${PROGRESS}...\r\${NC}"
    sleep 1
done

privoxy --no-daemon \$PREFIX/etc/privoxy/config > /dev/null 2>&1 &

echo -e "\${YELLOW}---------------------------------------\${NC}"
echo -e "💡 Proxy: \${CYAN}127.0.0.1:8118\${NC}"
echo -e "⏱ Xoay IP: \${CYAN}$SECONDS giây/lần\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Kiểm tra IP thực tế sau khi Tor đã 100%
echo -e "\${YELLOW}[*] Đang xác thực địa chỉ IP...\${NC}"
CURRENT_IP=\$(curl -s --max-time 15 -x http://127.0.0.1:8118 https://api.ipify.org)
if [ -z "\$CURRENT_IP" ]; then
    echo -e "\${RED}[!] Lỗi: Không thể lấy IP. Hãy thử gõ lại lệnh 'kanda'.\${NC}"
else
    LOCATION=\$(curl -s -x http://127.0.0.1:8118 https://ipapi.co/\$CURRENT_IP/country_name/)
    echo -e "🌍 IP: \${GREEN}\$CURRENT_IP\${NC} | 📍 Quốc gia: \${GREEN}\$LOCATION\${NC}"
fi
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Vòng lặp đếm ngược và đổi IP (Sạch, không chồng dòng)
while true; do
    for (( i=$SECONDS; i>0; i-- )); do
        echo -ne "\${YELLOW}[Sẵn sàng] - Tự đổi IP sau: \${RED}\${i}s  \${NC}\r"
        sleep 1
    done
    NEW_IP=\$(curl -s --max-time 10 -x http://127.0.0.1:8118 https://api.ipify.org)
    if [ ! -z "\$NEW_IP" ]; then
        echo -e "\n\${GREEN}[🔄] \$(date +%H:%M:%S) -> ĐÃ ĐỔI IP MỚI: \$NEW_IP\${NC}"
    fi
done
EOT

chmod +x $PREFIX/bin/kanda
clear
echo -e "${GREEN}CÀI ĐẶT HOÀN TẤT!${NC}"
echo -e "Bây giờ bạn hãy gõ: ${YELLOW}kanda${NC}"
