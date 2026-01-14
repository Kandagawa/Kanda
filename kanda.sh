#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Cài đặt im lặng tuyệt đối
clear
echo -e "${CYAN}[*] Đang cài đặt hệ thống Kanda Proxy...${NC}"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -qq > /dev/null 2>&1
pkg install tor privoxy curl net-tools -y -qq > /dev/null 2>&1

# 2. Cấu hình hệ thống
mkdir -p $PREFIX/etc/tor
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' $PREFIX/etc/privoxy/config
grep -q "forward-socks5t" $PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> $PREFIX/etc/privoxy/config

# 3. Tạo lệnh 'kanda' - Cải tiến Log không bị tràn
cat <<EOT > $PREFIX/bin/kanda
#!/data/data/com.termux/files/usr/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "\${CYAN}=======================================\${NC}"
echo -e "\${YELLOW}        KANDA PROXY AUTO-ROTATE        \${NC}"
echo -e "\${CYAN}=======================================\${NC}"
echo -e "\${GREEN}[?] Nhập số giây đổi IP (10-300):\${NC}"
read -p ">> " SEC_INPUT

if [[ ! "\$SEC_INPUT" =~ ^[0-9]+$ ]] || [ "\$SEC_INPUT" -lt 10 ]; then SEC_INPUT=10; fi
if [ "\$SEC_INPUT" -gt 300 ]; then SEC_INPUT=300; fi

echo -e "StrictNodes 0\nMaxCircuitDirtiness \$SEC_INPUT\nCircuitBuildTimeout 10\nControlPort 9051\nCookieAuthentication 0" > \$PREFIX/etc/tor/torrc

pkill tor; pkill privoxy
echo -e "\n\${CYAN}[*] Đang đợi mạng Tor đạt 100%...\${NC}"
rm -f \$PREFIX/tmp/tor.log
tor > \$PREFIX/tmp/tor.log 2>&1 &

while true; do
    if grep -q "Bootstrapped 100%" \$PREFIX/tmp/tor.log; then break; fi
    PROGRESS=\$(grep -o "Bootstrapped [0-9]*%" \$PREFIX/tmp/tor.log | tail -1)
    echo -ne "\${YELLOW}[>] Tiến độ: \${PROGRESS}...\r\${NC}"
    sleep 1
done

privoxy --no-daemon \$PREFIX/etc/privoxy/config > /dev/null 2>&1 &
clear
echo -e "\${GREEN}[+] HỆ THỐNG ĐÃ KÍCH HOẠT!\${NC}"
echo -e "\${CYAN}💡 Proxy: 127.0.0.1:8118 | Chu kỳ: \$SEC_INPUT giây\${NC}"
echo -e "\${YELLOW}---------------------------------------\${NC}"

# Vòng lặp Log 1 dòng duy nhất
while true; do
    # Ép đổi IP
    (echo authenticate ""; echo signal newnym; echo quit) | nc localhost 9051 > /dev/null 2>&1
    
    # Lấy IP mới
    NEW_IP=\$(curl -s --max-time 10 -x http://127.0.0.1:8118 https://api.ipify.org)
    
    if [ -z "\$NEW_IP" ]; then
        PRINT_IP="\${RED}Đang kết nối lại...\${NC}"
    else
        PRINT_IP="\${GREEN}\$NEW_IP\${NC}"
    fi

    # Đếm ngược và giữ log trên 1 dòng
    for (( i=\$SEC_INPUT; i>0; i-- )); do
        echo -ne "\r\${YELLOW}[🔄] IP HIỆN TẠI: \$PRINT_IP | Đổi sau: \${RED}\${i}s  \${NC}"
        sleep 1
    done
done
EOT

chmod +x $PREFIX/bin/kanda
clear
echo -e "${GREEN}CÀI ĐẶT XONG!${NC} Gõ lệnh: ${YELLOW}kanda${NC}"
