#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG ---
echo -e "\033[1;33m📦 Đang tối ưu hệ thống siêu tốc... \033[0m"
pkg install curl jq -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
rm -f $PREFIX/bin/buy
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'

# --- BƯỚC 1: XÁC THỰC JSON ---
while true; do
    clear
    echo -e "\n    ${P}[UGPHONE TERMINAL EXECUTOR - NO TOR]${NC}"
    echo -e "    ${Y}⚠️  LƯU Ý: Vui lòng BẬT VPN trước khi dán JSON!${NC}\n"
    
    while read -t 0.1 -n 10000 discard; do :; done
    echo -ne "    ${C}❯${NC} ${W}Dán JSON tại đây:${NC} "
    read -r DATA
    
    LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
    
    if [[ -n "$LID" && -n "$TOKEN" ]]; then break; fi
    echo -e "\n    ${R}✘ Lỗi: Dữ liệu JSON không hợp lệ!${NC}"
    sleep 1.2
done

# Kiểm tra IP hiện tại để người dùng xác nhận đã bật VPN chưa
MY_IP=$(curl -s https://api64.ipify.org)
echo -e "    ${GR}IP hiện tại:${NC} ${G}$MY_IP${NC} (Hãy chắc chắn đây là IP VPN)"
sleep 1

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
echo -e "\n    ${P}[CHỌN KHU VỰC GIAO DỊCH]${NC}"
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

# --- BƯỚC 3: GIAO DỊCH SIÊU TỐC ---
echo -e "\n    ${Y}●${NC} ${W}Đang gửi lệnh mua trực tiếp qua VPN...${NC}"

RES=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')

if [[ -n "$AMT" ]]; then 
    PAY=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    if [[ -n "$ORD" ]]; then 
        echo -e "\n    ${G}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "    ${G}┃${NC}     ${W}GIAO DỊCH HOÀN TẤT THÀNH CÔNG${NC}     ${G}┃${NC}"
        echo -e "    ${G}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
        echo -e "    ${W}Mã Đơn:${NC} ${C}$ORD${NC}\n"
    else 
        echo -e "\n    ${R}✘ Lỗi thanh toán: $PAY${NC}"
    fi
else 
    echo -e "\n    ${R}✘ Lỗi: API không phản hồi (Kiểm tra lại VPN/Token).${NC}"
fi

echo -e "    ${GR}Gõ 'buy' để thực hiện đơn mới.${NC}\n"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
clear
echo -e "\n    \033[1;32m✅ ĐÃ LOẠI BỎ TOR - TỐI ƯU SIÊU TỐC!\033[0m"
echo -e "    \033[1;33m⚠️  GHI NHỚ: Bật VPN trước khi dùng lệnh 'buy'.\033[0m"
echo -e "    \033[1;37mSử dụng lệnh: \033[1;36mbuy\033[0m\n"
