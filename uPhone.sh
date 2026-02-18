#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG ---
echo -e "\033[1;33m> Thiết lập lần đầu...\033[0m"
termux-wake-lock
pkg install curl jq tor -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc rút gọn
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'

# --- BƯỚC 1: XÁC THỰC ---
while true; do
    clear
    echo -e "${P}[UGPHONE EXECUTOR]${NC}"
    echo -e "${GR}Vui lòng dán JSON Token để tiếp tục...${NC}\n"
    
    while read -t 0.1 -n 10000 discard; do :; done
    echo -ne "${C}❯${NC} ${W}Dữ liệu:${NC} "
    read -r DATA
    
    if [ ${#DATA} -gt 150 ]; then
        LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
        TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
        if [[ -n "$LID" && -n "$TOKEN" ]]; then break; fi
    fi
    echo -e "${R}✘ JSON không hợp lệ!${NC}"
    sleep 1
done

# Nhận quà nhanh (Mạng thường)
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
clear
echo -e "${P}[CHỌN KHU VỰC]${NC}"
echo -e "  1. Nhật Bản (JP)    2. Singapore (SG)"
echo -e "  3. Hoa Kỳ (US)      4. Đức (DE)"
echo -e "  5. Hồng Kông (HK)"
echo -ne "\n${C}❯${NC} ${W}Nhập số:${NC} "
read -r CH

case $CH in 
    1|01) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea";;
    2|02) N="3731f6bf-b812-e983-872b-152cdab81276";;
    3|03) N="b0b20248-b103-b041-3480-e90675c57a4f";;
    4|04) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47";;
    5|05) N="82542031-4021-397a-9774-4b5311096a66";;
    *) echo -e "${R}Lựa chọn không hợp lệ!${NC}"; exit 1;;
esac

# --- BƯỚC 3: KẾT NỐI TOR ---
clear
echo -e "${P}[TOR]${NC} Đang quét Node sống..."
LIVEL_NODES=$(curl -s --connect-timeout 5 "https://onionoo.torproject.org/summary?running=true" | jq -r '.relays[].f' | shuf -n 20 | tr '\n' ',' | sed 's/,$//')

pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 127.0.0.1:9050" > "$TORRC"
[[ -n "$LIVEL_NODES" ]] && echo -e "EntryNodes $LIVEL_NODES" >> "$TORRC"

tor -f "$TORRC" 2>/dev/null | while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        printf "\r${GR}> Tiến trình:${NC} ${G}%d%%${NC}" "$percent"
        if [ "$percent" -eq 100 ]; then echo "OK" > /tmp/tor_ready; break; fi
    fi
done

if [ ! -f /tmp/tor_ready ]; then echo -e "\n${R}✘ Lỗi kết nối Tor!${NC}"; exit 1; fi
rm /tmp/tor_ready; sleep 0.5

# --- BƯỚC 4: GIAO DỊCH ---
echo -e "\n${Y}>${NC} Đang gửi lệnh mua qua Tor..."
RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
if [[ -n "$AMT" ]]; then 
    PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    if [[ -n "$ORD" ]]; then 
        echo -e "${G}✔ THÀNH CÔNG!${NC} Mã đơn: ${C}$ORD${NC}"
    else 
        echo -e "${R}✘ Thất bại:${NC} $PAY"
    fi
else 
    echo -e "${R}✘ Lỗi API:${NC} Server không phản hồi gói giá."
fi

pkill -9 tor > /dev/null 2>&1
echo -e "\n${GR}Gõ 'buy' để thực hiện đơn mới.${NC}"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
grep -q "alias buy='buy'" ~/.bashrc || echo "alias buy='buy'" >> ~/.bashrc

clear
echo -e "\033[1;32m✅ HOÀN TẤT: Đã gỡ bỏ dạng bảng. Gõ 'buy' để chạy.\033[0m"
