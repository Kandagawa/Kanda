#!/data/data/com.termux/files/usr/bin/bash

# --- KHỞI TẠO ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
WHITE='\033[1;37m'; GREY='\033[1;30m'
TODAY=$(date +%Y%m%d)

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
# Nhập dữ liệu
echo -ne "${C}◈${NC} ${WHITE}Dán JSON:${NC} "
read -r DATA

# Dùng Python để bóc tách ID và Token (Xử lý được mọi loại JSON)
LID=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('login_id', d.get('UGPHONE-MQTT', {}).get('login_id', '')))" "$DATA" 2>/dev/null)
TOKEN=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('access_token', d.get('UGPHONE-MQTT', {}).get('access_token', '')))" "$DATA" 2>/dev/null)

# Nếu Python không có, dùng bộ lọc dự phòng siêu mạnh
if [[ -z "$LID" || -z "$TOKEN" ]]; then
    LID=$(echo "$DATA" | grep -oE '"login_id":"[^"]+"' | cut -d'"' -f4 | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oE '"access_token":"[^"]+"' | cut -d'"' -f4 | head -n 1)
fi

if [[ -z "$LID" || -z "$TOKEN" ]]; then
    echo -e "${R}❌ Vẫn không lọc được! Kiểm tra lại JSON đi bạn.${NC}"
    exit 1
fi

echo -e "${G}●${NC} ${WHITE}Xác thực:${NC} ${G}${LID:0:10}... OK${NC}"

# --- BƯỚC 1: NHẬN QUÀ ---
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json" -H "terminal: web" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null

# --- BƯỚC 2: CHỌN VÙNG ---
echo -e "\n${C}◈${NC} ${WHITE}VÙNG:${NC} ${Y}1${NC}.JP ${Y}2${NC}.SG ${Y}3${NC}.US ${Y}4${NC}.DE ${Y}5${NC}.HK"
echo -ne "${C}◈${NC} ${WHITE}Chọn:${NC} "
read -r CH
case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="jp";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="sg";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="us";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="de";;
    5) N="f08913a6-b9d5-1b79-8e49-5889cdce6980"; CC="hk";;
    *) exit 1;;
esac

# --- BƯỚC 3: KẾT NỐI NGẦM ---
pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

echo -e "\n${C}🔍${NC} ${WHITE}Thiết lập đường truyền...${NC}"
NODES=$(curl -s "https://onionoo.torproject.org/details?search=country:$CC" | jq -r '.relays[] | select(.running==true and .advertised_bandwidth > 1048576) | .fingerprint' | tr '\n' ',' | sed 's/,$//')
echo -e "DataDirectory $PREFIX/var/lib/tor\nLog notice stdout\nSocksPort 9050" > "$TORRC"
[[ -n "$NODES" ]] && echo -e "ExitNodes $NODES\nStrictNodes 1" >> "$TORRC" || echo -e "ExitNodes {$CC}\nStrictNodes 1" >> "$TORRC"

is_ready=false
while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        render_bar "Khởi tạo mạng" "$percent"
        if [ "$percent" -eq 100 ]; then is_ready=true; break; fi
    fi
done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

# --- BƯỚC 4: MUA HÀNG ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n${G}🚀${NC} ${WHITE}Đang gửi lệnh mua...${NC}"
    
    RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
    -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

    AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
    if [ ! -z "$AMT" ]; then 
        PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
        -H "Content-Type: application/json;charset=UTF-8" \
        -H "terminal: web" -H "lang: vi" -H "update-date: $TODAY" \
        -H "login-id: $LID" -H "access-token: $TOKEN" \
        -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
        
        ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
        if [ ! -z "$ORD" ]; then 
            echo -e "${G}✅ THÀNH CÔNG! ORDER:${NC} ${C}$ORD${NC}"
        else 
            echo -e "${R}❌ LỖI GIAO DỊCH:${NC} ${GREY}$PAY${NC}"
        fi
    else 
        echo -e "${R}❌ LỖI DỮ LIỆU:${NC} ${GREY}$RES${NC}"
    fi
fi

pkill -9 tor > /dev/null 2>&1
echo -ne "\n${GREY}Xong.${NC}"
