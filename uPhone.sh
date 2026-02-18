#!/data/data/com.termux/files/usr/bin/bash

# --- BẢNG MÀU ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'
P='\033[1;38;5;141m'; W='\033[1;37m'; GR='\033[1;30m'; NC='\033[0m'

# --- BIẾN HỆ THỐNG ---
TODAY=$(date +%Y%m%d); TIME=$(date +%H:%M:%S)

# --- GIAO DIỆN GỌN ---
header() {
    clear
    echo -e "${P}╭───────────────────────────────────────────────────╮${NC}"
    echo -e "${P}│${NC}  ${C}uPhone PRO${NC} ${W}v3.0${NC}  ${GR}│${NC}  ${W}Date:${NC} ${G}${TODAY}${NC}  ${GR}│${NC}  ${W}Time:${NC} ${G}${TIME}${NC}  ${P}│${NC}"
    echo -e "${P}╰───────────────────────────────────────────────────╯${NC}"
}

status() {
    echo -e "  ${GR}[${NC}${C}#${NC}${GR}]${NC} ${W}$1${NC}..."
    sleep 0.3
}

# --- KHỞI TẠO ---
header

# Nhập JSON
echo -e "\n  ${C}◈${NC} ${W}Dán dữ liệu JSON:${NC}"
echo -ne "  ${P}╰─>${NC} "
read -r DATA

LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

if [[ -z "$LID" || -z "$TOKEN" ]]; then
    echo -e "\n  ${R}❌ Dữ liệu không hợp lệ!${NC}"; exit 1
fi

echo -e "  ${G}✔️${NC} ${GR}ID:${NC} ${W}${LID:0:10}...${NC}"

# Xử lý nhanh
status "Xác thực tài khoản"
status "Nhận gói quà tặng"
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json" -H "terminal: web" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null

# Menu vùng gọn
echo -e "\n  ${C}◈${NC} ${W}CHỌN VÙNG:${NC}"
echo -e "  ${Y}1.${NC} Nhật(JP)  ${Y}2.${NC} Sing(SG)  ${Y}3.${NC} Mỹ(US)  ${Y}4.${NC} Đức(DE)  ${Y}5.${NC} HK"
echo -ne "  ${P}╰─>${NC} "
read -r CH

case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="JP";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="SG";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="US";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="DE";;
    5) N="f08913a6-b9d5-1b79-8e49-5889cdce6980"; CC="HK";;
    *) echo -e "  ${R}Sai vùng!${NC}"; exit 1;;
esac

echo -e "  ${G}✔️${NC} ${GR}Target:${NC} ${W}${CC}${NC}"
status "Gửi yêu cầu thanh toán"

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
        echo -e "\n  ${G}🎉 THÀNH CÔNG!${NC}"
        echo -e "  ${GR}Order:${NC} ${C}${ORD}${NC}"
    else
        echo -e "\n  ${R}❌ THẤT BẠI:${NC} ${W}${PAY}${NC}"
    fi
else
    echo -e "\n  ${R}❌ LỖI:${NC} ${W}Hết Point/Token hỏng!${NC}"
fi

echo -e "\n  ${GR}Done. Nhấn Enter để thoát.${NC}"
read -r
