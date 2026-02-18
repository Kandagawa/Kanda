#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG ---
echo -e "\033[1;33m📦 Đang kiểm tra hệ thống... \033[0m"
pkg install curl jq tor -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

G='\033[32m'; R='\033[31m'; Y='\033[33m'; C='\033[36m'; NC='\033[0m'
W='\033[37m'; GR='\033[90m'; P='\033[38;5;141m'

# --- BƯỚC 1: XÁC THỰC JSON ---
while true; do
    clear
    echo -e "${P}●${NC} ${W}UGPHONE BUYER - XÁC THỰC${NC}"
    echo -e "${GR}──────────────────────────────────────────${NC}"
    
    # Dọn rác bộ nhớ đệm
    while read -t 0.1 -n 10000 discard; do :; done
    
    echo -ne "${C}❯${NC} ${W}Dán dữ liệu JSON:${NC} "
    read -r DATA
    
    if [ ${#DATA} -gt 150 ]; then
        LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
        TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

        if [[ -n "$LID" && -n "$TOKEN" ]]; then
            break
        fi
    fi
    echo -e "\n${R}✘ Dữ liệu không hợp lệ! Vui lòng thử lại.${NC}"
    sleep 1.5
done

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
while true; do
    clear
    echo -e "${P}●${NC} ${W}Xác thực thành công:${NC} ${G}$LID${NC}"
    echo -e "${GR}──────────────────────────────────────────${NC}"
    echo -e "${W}Chọn vùng muốn mua:${NC}"
    echo -e "  ${C}1.${NC} Nhật Bản (JP)    ${C}2.${NC} Singapore (SG)"
    echo -e "  ${C}3.${NC} Hoa Kỳ (US)      ${C}4.${NC} Đức (DE)"
    echo -e "  ${C}5.${NC} Hồng Kông (HK)"
    echo -e "${GR}──────────────────────────────────────────${NC}"
    echo -ne "${C}❯${NC} ${W}Nhập số:${NC} "
    read -r CH
    
    case $CH in 
        1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="jp"; break;;
        2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="sg"; break;;
        3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="us"; break;;
        4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="de"; break;;
        5) N="82542031-4021-397a-9774-4b5311096a66"; CC="hk"; break;;
    esac
done

# --- BƯỚC 3: THIẾT LẬP ĐƯỜNG TRUYỀN (ẨN DANH) ---
clear
echo -e "${P}●${NC} ${W}Đang khởi tạo đường truyền bảo mật...${NC}"
pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"
echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 9050\nExitNodes {$CC}\nStrictNodes 1" > "$TORRC"

is_ready=false
while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        # Render thanh tiến trình đơn giản
        printf "\r  ${GR}Tiến trình: ${W}%d%%${NC} " "$percent"
        if [ "$percent" -eq 100 ]; then 
            is_ready=true
            sleep 1 # Chờ 1s sau khi đạt 100% như yêu cầu
            break 
        fi
    fi
done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

# --- BƯỚC 4: GIAO DỊCH ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n${Y}●${NC} ${W}Đang gửi yêu cầu mua...${NC}"
    
    RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
    -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

    AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
    if [[ -n "$AMT" ]]; then 
        PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
        -H "Content-Type: application/json;charset=UTF-8" -H "login-id: $LID" -H "access-token: $TOKEN" \
        -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
        
        ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
        if [[ -n "$ORD" ]]; then 
            echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "  ${G}✔ THÀNH CÔNG!${NC}"
            echo -e "  ${W}Mã đơn hàng:${NC} ${C}$ORD${NC}"
            echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        else 
            echo -e "\n${R}✘ LỖI THANH TOÁN:${NC} $PAY"
        fi
    else 
        echo -e "\n${R}✘ LỖI HỆ THỐNG:${NC} Không lấy được thông tin giá."
    fi
fi

pkill -9 tor > /dev/null 2>&1
echo -e "\n${GR}Gõ 'buy' để thực hiện đơn hàng mới.${NC}"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
grep -q "alias buy='buy'" ~/.bashrc || echo "alias buy='buy'" >> ~/.bashrc

clear
echo -e "\033[1;32m✅ HỆ THỐNG ĐÃ SẴN SÀNG!\033[0m"
echo -e "\033[1;37mGõ lệnh \033[1;36mbuy\033[0m \033[1;37mđể bắt đầu giao dịch.\033[0m"
