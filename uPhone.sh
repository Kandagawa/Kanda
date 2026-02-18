#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG ---
echo -e "\033[1;33m📦 Đang tối ưu thống... \033[0m"
pkg install curl jq tor lsof -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
# Xóa file cũ để tránh xung đột đường dẫn /tmp
rm -f $PREFIX/bin/buy

cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'

# --- BƯỚC 1: XÁC THỰC JSON ---
while true; do
    clear
    echo -e "\n    ${P}[UGPHONE TERMINAL EXECUTOR]${NC}"
    echo -e "    ${GR}Trạng thái: Đang chờ dữ liệu Auth...${NC}\n"
    
    while read -t 0.1 -n 10000 discard; do :; done
    echo -ne "    ${C}❯${NC} ${W}Dán JSON tại đây:${NC} "
    read -r DATA
    
    LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
    
    if [[ -n "$LID" && -n "$TOKEN" ]]; then break; fi
    echo -e "\n    ${R}✘ Lỗi: Dữ liệu không hợp lệ!${NC}"
    sleep 1.2
done

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
clear
echo -e "\n    ${P}[CHỌN KHU VỰC]${NC}"
echo -e "      ${C}01.${NC} Nhật Bản    ${C}02.${NC} Singapore"
echo -e "      ${C}03.${NC} Hoa Kỳ      ${C}04.${NC} Đức"
echo -e "      ${C}05.${NC} Hồng Kông"
echo -ne "\n    ${C}❯${NC} ${W}Nhập số:${NC} "
read -r CH
case $CH in 
    1|01) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea";;
    2|02) N="3731f6bf-b812-e983-872b-152cdab81276";;
    3|03) N="b0b20248-b103-b041-3480-e90675c57a4f";;
    4|04) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47";;
    5|05) N="82542031-4021-397a-9774-4b5311096a66";;
    *) echo -e "${R}Sai lựa chọn!${NC}"; exit 1;;
esac

# --- BƯỚC 3: KẾT NỐI TOR (FIX LỖI JQ & PATH) ---
clear
echo -e "\n    ${P}●${NC} ${W}Đang bóc Node chất lượng cao...${NC}"
pkill -9 tor > /dev/null 2>&1
rm -rf $HOME/.tor_data
mkdir -p "$HOME/.tor_data" && chmod 700 "$HOME/.tor_data"

# Vòng lặp lấy Node cho đến khi thành công (Chống lỗi jq)
while true; do
    JSON_DATA=$(curl -s --connect-timeout 10 "https://onionoo.torproject.org/summary?running=true&fast=true")
    LIVEL_NODES=$(echo "$JSON_DATA" | jq -r '.relays[].f' 2>/dev/null | shuf -n 25 | tr '\n' ',' | sed 's/,$//')
    
    if [[ -n "$LIVEL_NODES" && "$LIVEL_NODES" != "null" ]]; then
        break
    else
        echo -ne "\r    ${Y}⚡ Đang tải lại danh sách Node...${NC}"
        sleep 2
    fi
done

TORRC="$HOME/.tor_data/torrc"
echo -e "DataDirectory $HOME/.tor_data\nSocksPort 127.0.0.1:9050" > "$TORRC"
echo "EntryNodes $LIVEL_NODES" >> "$TORRC"

TOR_LOG="$HOME/.tor_data/tor.log"
> "$TOR_LOG"
tor -f "$TORRC" > "$TOR_LOG" 2>&1 &

is_ready=false
while true; do
    if [ -f "$TOR_LOG" ] && grep -q "Bootstrapped 100%" "$TOR_LOG"; then
        printf "\r    ${GR}Tiến trình: ${NC}${G}100%% (Đã kết nối)${NC} "
        is_ready=true; break
    fi
    
    if [ -f "$TOR_LOG" ]; then
        percent=$(grep -oP "Bootstrapped \d+%" "$TOR_LOG" | tail -1 | grep -oP "\d+")
        [[ -n "$percent" ]] && printf "\r    ${GR}Tiến trình: ${NC}${G}%s%%${NC} " "$percent"
    fi
    
    if ! pgrep -x "tor" > /dev/null; then
        tor -f "$TORRC" > "$TOR_LOG" 2>&1 &
    fi
    sleep 0.5
done

# --- BƯỚC 4: GIAO DỊCH ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n    ${Y}●${NC} ${W}Đang gửi lệnh mua tới Server...${NC}"
    RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
    -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

    AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
    if [[ -n "$AMT" ]]; then 
        PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
        -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
        -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
        ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
        [[ -n "$ORD" ]] && echo -e "\n    ${G}✔ THÀNH CÔNG!${NC} Mã: ${C}$ORD${NC}" || echo -e "\n    ${R}✘ Lỗi: $PAY${NC}"
    else 
        echo -e "\n    ${R}✘ Lỗi: Không lấy được giá (Check lại JSON).${NC}"
    fi
fi

pkill -9 tor > /dev/null 2>&1
rm -rf "$HOME/.tor_data"
echo -e "\n    ${GR}Gõ 'buy' để thực hiện đơn mới.${NC}\n"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
clear
echo -e "\n    \033[1;32m✅ ĐÃ FIX TRIỆT ĐỂ LỖI JQ VÀ ĐƯỜNG DẪN!\033[0m"
echo -e "    \033[1;37mGõ lệnh: \033[1;36mbuy\033[0m\n"
