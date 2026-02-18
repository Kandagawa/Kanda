#!/data/data/com.termux/files/usr/bin/bash

# --- 1. KIỂM TRA PHỤ KIỆN (CHỈ CÀI NẾU THIẾU - MẤT 0.1s) ---
for pkg in curl jq tor; do
    command -v $pkg &> /dev/null || pkg install $pkg -y
done

# --- 2. TẠO LỆNH 'buy' TRỰC TIẾP ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
PURPLE='\033[1;38;5;141m'; WHITE='\033[1;37m'; GREY='\033[1;30m'
TODAY=$(date +%Y%m%d)

clear
while true; do
    read -t 0.1 -n 10000 discard
    echo -e "${C}👉 Dán JSON vào rồi Enter:${NC}"
    echo -ne "${C}◈${NC} "
    read -r DATA
    LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
    [[ -n "$LID" ]] && break || echo -e "${R}❌ JSON sai! Thử lại...${NC}\n"
done

# Nhận quà chạy ngầm luôn
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

echo -e "\n${PURPLE}◈ CHỌN VÙNG:${NC} ${Y}1${NC}.JP ${Y}2${NC}.SG ${Y}3${NC}.US ${Y}4${NC}.DE"
read -p "  ╰─> Nhập số: " CH
case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="{jp}";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="{sg}";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="{us}";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="{de}";;
    *) exit 1;;
esac

# --- KẾT NỐI TOR SIÊU TỐC (BỎ LỌC NODE) ---
pkill -9 tor > /dev/null 2>&1
# Giữ cache để lần sau vào phát được luôn
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

# Ép Tor dùng thẳng Node của quốc gia đó, không cần đi hỏi server Onionoo nữa
echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 9050\nExitNodes $CC\nStrictNodes 1" > "$TORRC"

echo -e "\n${C}🚀 Đang kết nối mạng $CC...${NC}"
tor -f "$TORRC" --runasdaemon 1 > /dev/null 2>&1

# Chờ cổng mạng mở là dứt điểm luôn
while ! nc -z 127.0.0.1 9050; do sleep 0.2; done

echo -e "${G}✅ Mạng Sẵn Sàng! Đang gửi lệnh mua...${NC}"

RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" \
-H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
if [[ -n "$AMT" ]]; then 
    PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    [[ -n "$ORD" ]] && echo -e "${G}🎉 THÀNH CÔNG! ID: $ORD${NC}" || echo -e "${R}❌ LỖI THANH TOÁN${NC}"
else 
    echo -e "${R}❌ LỖI LẤY GIÁ${NC}"
fi

pkill -9 tor > /dev/null 2>&1
echo -e "\n${GREY}Xong. Gõ 'buy' để chạy lại.${NC}"
EOF

# --- 3. KÍCH HOẠT ---
chmod +x $PREFIX/bin/buy
grep -q "alias buy='buy'" ~/.bashrc || echo "alias buy='buy'" >> ~/.bashrc
source ~/.bashrc
clear
echo -e "\033[1;32m✅ CÀI XONG! Gõ 'buy' để dứt điểm.\033[0m"
buy
