#!/data/data/com.termux/files/usr/bin/bash

# --- 1. CÀI ĐẶT HỆ THỐNG (ẨN LOG) ---
clear
echo -e "\033[1;33m📦 Đang tối ưu hệ thống và cài đặt phụ kiện... \033[0m"

# Cập nhật và cài đặt ẩn danh
pkg update -y &> /dev/null
pkg install curl jq tor coreutils -y &> /dev/null

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
PURPLE='\033[1;38;5;141m'; WHITE='\033[1;37m'; GREY='\033[1;30m'

render_bar() {
    local label=$1; local percent=$2; local w=25
    local filled=$((percent*w/100)); local empty=$((w-filled))
    printf "\r\033[K  ${GREY}${label}: ${NC}["
    printf "${C}"
    for ((j=0; j<filled; j++)); do printf "━"; done
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "━"; done
    printf "${NC}] ${WHITE}%d%%${NC}" "$percent"
}

clear
echo -e "${PURPLE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${PURPLE}┃${NC}          ${W}UGPHONE AUTO BUYER PRO (GITHUB)${NC}           ${PURPLE}┃${NC}"
echo -e "${PURPLE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

# --- NHẬP DATA ---
echo -e "\n${C}👉 Dán JSON vào đây rồi Enter:${NC}"
read -r DATA
LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

if [[ -z "$LID" || -z "$TOKEN" ]]; then
    echo -e "${R}❌ Dữ liệu JSON không hợp lệ!${NC}"
    exit 1
fi

# --- NHẬN QUÀ NGẦM ---
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "terminal: web" -H "lang: vi" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- CHỌN VÙNG ---
echo -e "\n${PURPLE}◈${NC} ${WHITE}CHỌN KHU VỰC:${NC}"
echo -e "  ${GREY}1.${NC} Nhật (JP)  ${GREY}2.${NC} Sing (SG)  ${GREY}3.${NC} Mỹ (US)  ${GREY}4.${NC} Đức (DE)"
read -p "  ╰─> Nhập số: " CH
case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="jp";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="sg";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="us";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="de";;
    *) echo "Sai lựa chọn!"; exit 1;;
esac

# --- KẾT NỐI TOR ---
pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* &> /dev/null
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

echo -e "\n${C}🔍 Đang lọc Node và thiết lập Tunnel...${NC}"
NODES=$(curl -s "https://onionoo.torproject.org/details?search=country:$CC" | jq -r '.relays[] | select(.running==true and .advertised_bandwidth > 1048576) | .fingerprint' | shuf -n 20 | tr '\n' ',' | sed 's/,$//')
echo -e "DataDirectory $PREFIX/var/lib/tor\nLog notice stdout\nSocksPort 9050" > "$TORRC"
[[ -n "$NODES" ]] && echo -e "ExitNodes $NODES\nStrictNodes 1" >> "$TORRC" || echo -e "ExitNodes {$CC}\nStrictNodes 1" >> "$TORRC"

is_ready=false
while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        render_bar "Tiến trình Tor" "$percent"
        if [ "$percent" -eq 100 ]; then is_ready=true; break; fi
    fi
done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

# --- GIAO DỊCH ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n${G}🚀 Tor Sẵn sàng! Đang gửi lệnh mua...${NC}"
    
    RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
    -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

    AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
    if [ ! -z "$AMT" ]; then 
        PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
        -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
        -H "login-id: $LID" -H "access-token: $TOKEN" \
        -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
        
        ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
        [[ -n "$ORD" ] ] && echo -e "  ${G}🎉 THÀNH CÔNG! ORDER ID: ${C}$ORD${NC}" || echo -e "${R}❌ LỖI: $PAY${NC}"
    else 
        echo -e "${R}❌ LỖI LẤY GIÁ: $RES${NC}"
    fi
fi

pkill -9 tor > /dev/null 2>&1
echo -e "\n${GREY}Gõ 'buy' để thực hiện đơn mới.${NC}"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
clear
echo -e "\n\033[1;32m✅ HỆ THỐNG ĐÃ SẴN SÀNG!\033[0m"
echo -e "\033[1;37mNhập lệnh sau để bắt đầu mua:\033[0m \033[1;36mbuy\033[0m\n"
