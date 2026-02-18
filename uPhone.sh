#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG (ẨN LOG) ---
clear
echo -e "\033[1;33m📦 Đang tối ưu hệ thống siêu tốc... \033[0m"

# Chỉ cài những phụ kiện cần thiết, loại bỏ Tor
pkg update -y &> /dev/null
pkg install curl jq coreutils -y &> /dev/null

# --- 2. TẠO LỆNH BUY (PHIÊN BẢN NO-TOR) ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# Màu sắc
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
PURPLE='\033[1;38;5;141m'; WHITE='\033[1;37m'; GREY='\033[1;30m'

clear
echo -e "${PURPLE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${PURPLE}┃${NC}          ${W}UGPHONE AUTO BUYER PRO (NO-TOR)${NC}           ${PURPLE}┃${NC}"
echo -e "${PURPLE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${GR}Ghi chú: Nên bật VPN trước khi thực hiện để đổi IP.${NC}"

# --- NHẬP DATA ---
echo -e "\n${C}👉 Dán JSON vào đây rồi Enter:${NC}"
read -r DATA
LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

if [[ -z "$LID" || -z "$TOKEN" ]]; then
    echo -e "${R}❌ Dữ liệu JSON không hợp lệ!${NC}"
    exit 1
fi

echo -e "${G}✅ Xác thực thành công!${NC}"

# --- NHẬN QUÀ NGẦM ---
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "terminal: web" -H "lang: vi" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- CHỌN VÙNG ---
echo -e "\n${PURPLE}◈${NC} ${WHITE}CHỌN KHU VỰC:${NC}"
echo -e "  ${GREY}1.${NC} Nhật (JP)    ${GREY}2.${NC} Sing (SG)    ${GREY}3.${NC} Mỹ (US)"
echo -e "  ${GREY}4.${NC} Đức (DE)     ${GREY}5.${NC} Hồng Kông (HK)"
read -p "  ╰─> Nhập số: " CH
case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47";;
    5) N="82542031-4021-397a-9774-4b5311096a66";;
    *) echo "Sai lựa chọn!"; exit 1;;
esac

# --- GIAO DỊCH TRỰC TIẾP ---
echo -e "\n${Y}🚀 Đang thực thi lệnh mua siêu tốc...${NC}"

# Lấy Price ID
RES=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
-H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
-H "login-id: $LID" -H "access-token: $TOKEN" \
-d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')

if [ -n "$AMT" ]; then 
    # Thanh toán
    PAY=$(curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
    -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
    
    ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
    
    if [[ -n "$ORD" ]]; then
        echo -e "\n  ${G}🎉 THÀNH CÔNG!${NC}"
        echo -e "  ${W}Mã Đơn hàng: ${C}$ORD${NC}"
    else
        echo -e "\n  ${R}❌ LỖI THANH TOÁN: $PAY${NC}"
    fi
else 
    echo -e "\n  ${R}❌ LỖI LẤY GIÁ: $RES${NC}"
fi

echo -e "\n${GREY}Gõ 'buy' để thực hiện đơn mới.${NC}"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
clear
echo -e "\n\033[1;32m✅ ĐÃ LOẠI BỎ TOR - TỐI ƯU SIÊU TỐC!\033[0m"
echo -e "\033[1;37mNhập lệnh để bắt đầu mua:\033[0m \033[1;36mbuy\033[0m\n"
