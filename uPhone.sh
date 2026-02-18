#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG ---
clear
echo -e "    \033[1;33m📦 Thiết lập lần đầu... \033[0m"
pkg update -y &> /dev/null
pkg install curl jq coreutils -y &> /dev/null

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'

while true; do
    clear
    echo -e "\n    ${P}[UGPHONE CỦA ${G}HANAMI]${NC}"
    echo -e "    ${GR}*Lưu ý: Nên thay đổi IP khi thực hiện mua...${NC}\n"
    
    echo -ne "    ${C}❯${NC} ${W}Dán JSON:${NC} "
    read -r DATA
    
    LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
    
    if [[ -n "$LID" && -n "$TOKEN" ]]; then break; fi
    echo -e "\n    ${R}✘ Dữ liệu không hợp lệ!${NC}"
    sleep 1.2
done

clear
echo -e "\n    ${P}[UGPHONE AUTO BUYER PRO]${NC}"
echo -e "    ${G}✅ ID: $LID ${NC}"

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

echo -e "\n    ${W}Chọn máy chủ:${NC}"
echo -e "      ${C}1.${NC} Nhật (JP)     ${C}2.${NC} Sing (SG)     ${C}3.${NC} Mỹ (US)"
echo -e "      ${C}4.${NC} Đức (DE)      ${C}5.${NC} Hong Kong (HK)"
echo -ne "\n    ${C}❯${NC} ${W}Nhập số:${NC} "
read -r CH

case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47";;
    5) N="82542031-4021-397a-9774-4b5311096a66";;
    *) echo -e "    ${R}Sai lựa chọn!${NC}"; exit 1;;
esac

echo -e "\n    ${Y}● Đang gửi lệnh mua...${NC}"

RES=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
-H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | jq -r '.data.amount_id // empty')
MSG_RES=$(echo "$RES" | jq -r '.msg')

if [ -n "$AMT" ]; then 
    PAY=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | jq -r '.data.order_id // empty')
    MSG_PAY=$(echo "$PAY" | jq -r '.msg')
    
    if [[ -n "$ORD" ]]; then
        echo -e "\n    ${G}✔ THÀNH CÔNG!${NC}"
        echo -e "    ${W}Mã đơn: ${C}$ORD${NC}"
    else
        echo -e "\n    ${R}✘ THẤT BẠI: $MSG_PAY${NC}"
    fi
else 
    echo -e "\n    ${R}✘ LỖI: $MSG_RES${NC}"
fi

echo -e "\n    ${GR}Kết thúc quá trình, tiếp tục gõ "buy".${NC}"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
clear
echo -e "\n    \033[1;32m✅ HOÀN TẤT CÀI ĐẶT!\033[0m"
echo -e "    \033[1;37mGõ lệnh:\033[0m \033[1;36mbuy\033[0m\n"
