#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP NHANH ---
echo -e "\033[1;33m📦 Đang tối ưu lệnh mua... \033[0m"
pkg install curl jq -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
rm -f $PREFIX/bin/buy
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'

# --- BƯỚC 1: NHẬP DATA ---
while true; do
    clear
    echo -e "\n    ${P}[UGPHONE EXECUTOR]${NC} ${GR}(Nhắc nhở: Nên dùng VPN/Mạng khác)${NC}\n"
    
    # Xóa buffer tránh kẹt dữ liệu cũ
    while read -t 0.1 -n 10000 discard; do :; done
    echo -ne "    ${C}❯${NC} ${W}Dán JSON Token:${NC} "
    read -r DATA
    
    LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
    
    if [[ -n "$LID" && -n "$TOKEN" ]]; then break; fi
    echo -e "\n    ${R}✘ JSON sai định dạng!${NC}"
    sleep 1
done

# Nhận quà nhanh
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
echo -e "\n    ${W}Chọn khu vực:${NC}"
echo -e "      1. Nhật Bản (JP)    2. Singapore (SG)"
echo -e "      3. Hoa Kỳ (US)      4. Đức (DE)"
echo -e "      5. Hồng Kông (HK)"
echo -ne "\n    ${C}❯${NC} ${W}Số:${NC} "
read -r CH

case $CH in 
    1|01) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea";;
    2|02) N="3731f6bf-b812-e983-872b-152cdab81276";;
    3|03) N="b0b20248-b103-b041-3480-e90675c57a4f";;
    4|04) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47";;
    5|05) N="82542031-4021-397a-9774-4b5311096a66";;
    *) echo -e "${R}Lựa chọn sai!${NC}"; exit 1;;
esac

# --- BƯỚC 3: MUA HÀNG ---
echo -e "\n    ${Y}●${NC} ${W}Đang thực thi đơn hàng...${NC}"

RES=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')

if [[ -n "$AMT" ]]; then 
    PAY=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    [[ -n "$ORD" ]] && echo -e "\n    ${G}✔ XONG! Mã đơn: ${C}$ORD${NC}" || echo -e "\n    ${R}✘ Thất bại: $PAY${NC}"
else 
    echo -e "\n    ${R}✘ Lỗi: Không lấy được ID giá (Token hết hạn?)${NC}"
fi

echo -e "\n    ${GR}Gõ 'buy' để tiếp tục.${NC}"
EOF

# --- 3. KÍCH HOẠT ---
chmod +x $PREFIX/bin/buy
clear
echo -e "\n    \033[1;32m✅ LỆNH MUA SIÊU TỐC ĐÃ SẴN SÀNG!\033[0m"
echo -e "    \033[1;37mGõ lệnh: \033[1;36mbuy\033[0m\n"
