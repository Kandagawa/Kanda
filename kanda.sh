#!/data/data/com.termux/files/usr/bin/bash

# 1. Cài đặt im lặng (Ẩn log mirror rác)
clear
echo -e "\033[0;36m[*] Đang cài đặt hệ thống Kanda Proxy...\033[0m"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -qq > /dev/null 2>&1
pkg install tor privoxy curl net-tools -y -qq > /dev/null 2>&1

# 2. Tạo lệnh 'kanda'
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

# Cấu hình Tor Control - QUAN TRỌNG ĐỂ ĐỔI IP
echo -e "StrictNodes 0\nMaxCircuitDirtiness \$SEC_INPUT\nCircuitBuildTimeout 10\nControlPort 9051\nCookieAuthentication 0" > \$PREFIX/etc/tor/torrc
sed -i 's/listen-address  127.0.0.1:8118/listen-address  0.0.0.0:8118/g' \$PREFIX/etc/privoxy/config
grep -q "forward-socks5t" \$PREFIX/etc/privoxy/config || echo "forward-socks5t / 127.0.0.1:9050 ." >> \$PREFIX/etc/privoxy/config

pkill tor; pkill privoxy
sleep 1
echo -e "\n\${CYAN}[*] Đang khởi động mạng Tor... (Đợi 100%)\${NC}"
rm -f \$PREFIX/tmp/tor.log
tor > \$PREFIX/tmp/tor.log 2>&1 &

while true; do
    if grep -q "Bootstrapped 100%" \$PREFIX/tmp/tor.log; then break; fi
    PROGRESS=\$(grep -o "Bootstrapped [0-9]*%" \$PREFIX/tmp/tor.log | tail -1)
    echo -ne "\${YELLOW}[>] Tiến độ: \${PROGRESS}...\r\${NC}"
    sleep 1
done

privoxy --no-daemon \$PREFIX/etc/privoxy/config > /dev/null 2>&1 &
echo -e "\n\${GREEN}[+] Mạng đã sẵn sàng!\${NC}"

while true; do
    # ÉP ĐỔI IP QUỐC TẾ MỚI
    (echo authenticate ""; echo signal newnym; echo quit) | nc localhost 9051 > /dev/null 2>&1
    
    # Lấy IP và Quốc gia (Không bao giờ hiện IP thật)
    INFO=\$(curl -s --max-time 15 -x http://127.0.0.1:8118 "https://ipapi.co/json/" | jq -r '.ip + " [" + .country_name + "]"' 2>/dev/null)
    
    if [ -z "\$INFO" ] || [[ "\$INFO" == *"null"* ]]; then
        PRINT_LOG="\${RED}Đang lấy IP mới...\${NC}"
    else
        PRINT_LOG="\${GREEN}\$INFO\${NC}"
    fi

    for (( i=\$SEC_INPUT; i>0; i-- )); do
        echo -ne "\r\${YELLOW}[🔄] IP: \$PRINT_LOG | Xoay sau: \${RED}\${i}s  \${NC}"
        sleep 1
    done
done
EOT

chmod +x $PREFIX/bin/kanda
clear
echo -e "\033[0;32mCÀI ĐẶT HOÀN TẤT!\033[0m Gõ lệnh: \033[0;33mkanda\033[0m"
