#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP ---
if ! command -v tor &> /dev/null; then
    pkg install curl jq tor -y > /dev/null 2>&1
fi

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

G='\033[32m'; R='\033[31m'; Y='\033[33m'; C='\033[36m'; NC='\033[0m'
W='\033[37m'; GR='\033[90m'; P='\033[38;5;141m'

clear
echo -e "${G}✔ HỆ THỐNG ĐÃ KHÓA CHỐNG SPAM.${NC}"
echo -e "${W}Vui lòng dán JSON rồi mới ấn Enter.${NC}"

# --- BƯỚC 1: NHẬP LIỆU (CƠ CHẾ KHÓA CỨNG - FIX SPAM) ---
while true; do
    # Buộc script phải dừng lại hoàn toàn, không nhận phím Enter tự động
    # Chỉ khi DATA có độ dài > 200 mới thoát vòng lặp
    read -r -p "$(echo -e "\n${C}❯${NC} ${W}Dán JSON tại đây:${NC} ")" DATA
    
    # Kiểm tra độ dài: JSON chuẩn bạn gửi luôn cực dài (> 500 ký tự)
    if [ ${#DATA} -gt 200 ]; then
        LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
        TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

        if [[ -n "$LID" && -n "$TOKEN" ]]; then
            echo -e "  ${G}✔ Xác thực thành công: $LID${NC}"
            break
        fi
    fi
    
    # Nếu bị spam hoặc dán sai, nó sẽ xóa sạch màn hình và giữ im lặng 
    # Thay vì hiện chữ "Lỗi" đỏ chót gây rối mắt
    clear
    echo -e "${Y}⚠ Vẫn đang chờ bạn dán dữ liệu JSON...${NC}"
    echo -e "${GR}(Nếu dán rồi mà vẫn hiện dòng này, hãy thử dán lại)${NC}"
    sleep 0.5
done

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
echo -e "\n${C}❯${NC} ${W}Vùng:${NC} ${GR}1-JP | 2-SG | 3-US | 4-DE | 5-HK${NC}"
echo -ne "  ${W}Chọn số:${NC} "
read -r CH
case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="jp";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="sg";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="us";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="de";;
    5) N="82542031-4021-397a-9774-4b5311096a66"; CC="hk";;
    *) exit 1;;
esac

# --- BƯỚC 3: TOR & MUA ---
pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

echo -e "\n${C}❯${NC} ${W}Đang kết nối Proxy $CC...${NC}"
echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 9050\nExitNodes {$CC}\nStrictNodes 1" > "$TORRC"

tor -f "$TORRC" 2>/dev/null &
for i in {1..15}; do
    printf "\r  ${GR}Khởi tạo đường truyền... %d/15${NC}" "$i"
    sleep 1
done

echo -e "\n\n${Y}●${NC} ${W}Đang thực hiện giao dịch...${NC}"
RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
if [[ -n "$AMT" ]]; then 
    PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    [[ -n "$ORD" ]] && echo -e "\n${G}✔ MUA THÀNH CÔNG! ID: $ORD${NC}" || echo -e "\n${R}✘ LỖI THANH TOÁN${NC}"
else 
    echo -e "\n${R}✘ LỖI HỆ THỐNG (Hết lượt/Sai JSON)${NC}"
fi

pkill -9 tor > /dev/null 2>&1
EOF

chmod +x $PREFIX/bin/buy
source ~/.bashrc
buy
