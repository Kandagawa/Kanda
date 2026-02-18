#!/data/data/com.termux/files/usr/bin/bash

# --- BẢNG MÀU ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'
W='\033[1;37m'; GR='\033[1;30m'; NC='\033[0m'
TODAY=$(date +%Y%m%d)

clear
# Nhập dữ liệu ngay lập tức
echo -ne "${C}◈${NC} ${W}Dán JSON:${NC} "
read -r DATA

LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

[[ -z "$LID" ]] && { echo -e "${R}❌ Lỗi JSON!${NC}"; exit 1; }

# Tự động nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json" -H "terminal: web" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null

# Chọn vùng nhanh trên 1 dòng
echo -e "\n${C}◈${NC} ${W}VÙNG:${NC} ${Y}1${NC}.JP ${Y}2${NC}.SG ${Y}3${NC}.US ${Y}4${NC}.DE ${Y}5${NC}.HK"
echo -ne "${C}◈${NC} ${W}Chọn:${NC} "
read -r CH

case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="JP";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="SG";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="US";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="DE";;
    5) N="f08913a6-b9d5-1b79-8e49-5889cdce6980"; CC="HK";;
    *) exit 1;;
esac

echo -ne "\n${G}●${NC} ${W}Đang mua ${CC}...${NC}"

# API Mua
RES=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json" -H "terminal: web" \
-H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')

if [[ -n "$AMT" ]]; then
    PAY=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json" -H "terminal: web" -H "update-date: $TODAY" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    
    if [[ -n "$ORD" ]]; then
        echo -e "\r${G}●${NC} ${W}Thành công:${NC} ${C}${ORD}${NC}"
    else
        echo -e "\r${R}●${NC} ${W}Thất bại:${NC} ${GR}${PAY}${NC}"
    fi
else
    echo -e "\r${R}●${NC} ${W}Lỗi:${NC} ${GR}Check Points/Token${NC}"
fi
