#!/data/data/com.termux/files/usr/bin/bash

# --- 1. CÀI ĐẶT MÔI TRƯỜNG ---
echo -e "\033[1;33m📦 Đang kiểm tra hệ thống... \033[0m"
pkg install curl jq tor python -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# --- CẤU HÌNH MÀU SẮC ---
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'
TODAY=$(date +%Y%m%d)

render_bar() {
    local label=$1; local percent=$2; local w=30
    local filled=$((percent*w/100)); local empty=$((w-filled))
    printf "\r  ${W}${label}${NC} ["
    for ((j=0; j<filled; j++)); do printf "${C}━${NC}"; done
    for ((j=0; j<empty; j++)); do printf "${GR}━${NC}"; done
    printf "] ${W}%d%%${NC}" "$percent"
}

# --- GIAO DIỆN CHÍNH ---
clear
echo -e "${P}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "    ${W}UGPHONE TERMINAL BUYER${NC} | ${G}STABLE 2.2${NC}"
echo -e "${P}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# --- BƯỚC 1: XÁC THỰC ---
while true; do
    read -t 0.1 -n 10000 discard
    echo -ne "\n${W}[+] Dán dữ liệu JSON: ${NC}"
    read -r DATA
    LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
    TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

    if [[ -n "$LID" ]]; then
        echo -e "  ${G}╰─> Đã xác thực người dùng: ${W}$LID${NC}"
        break
    else
        echo -e "  ${R}╰─> Dữ liệu không hợp lệ, vui lòng thử lại!${NC}"
    fi
done

# --- BƯỚC 2: QUÀ TẶNG (Chạy ngầm) ---
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "terminal: web" -H "lang: vi" -H "update-date: $TODAY" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 3: CHỌN KHU VỰC ---
echo -e "\n${W}[+] Danh sách khu vực hỗ trợ:${NC}"
echo -e "  ${C}1.${NC} Nhật Bản (JP)    ${C}2.${NC} Singapore (SG)    ${C}3.${NC} Hoa Kỳ (US)"
echo -e "  ${C}4.${NC} Đức (DE)         ${C}5.${NC} Hồng Kông (HK)"
echo -ne "\n${W}[?] Chọn khu vực (1-5): ${NC}"
read -r CH
case $CH in 
    1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="jp";;
    2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="sg";;
    3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="us";;
    4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="de";;
    5) N="82542031-4021-397a-9774-4b5311096a66"; CC="hk";;
    *) echo -e "  ${R}╰─> Lựa chọn không hợp lệ!${NC}"; exit 1;;
esac

# --- BƯỚC 4: KẾT NỐI (ẨN LOG TOR) ---
pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

echo -e "\n${W}[+] Khởi tạo đường truyền bảo mật ($CC)...${NC}"
echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 9050\nExitNodes {$CC}\nStrictNodes 1" > "$TORRC"

is_ready=false
# Chạy tor và lọc bỏ toàn bộ log văn bản, chỉ lấy số phần trăm
while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        render_bar "Tiến trình kết nối" "$percent"
        if [ "$percent" -eq 100 ]; then is_ready=true; break; fi
    fi
done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

# --- BƯỚC 5: GIAO DỊCH ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n${Y}[!] Đang thực hiện giao dịch, vui lòng chờ...${NC}"
    
    RES=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/queryResourcePrice" \
    -H "Content-Type: application/json;charset=UTF-8" -H "terminal: web" -H "lang: vi" \
    -H "login-id: $LID" -H "access-token: $TOKEN" \
    -d "{\"order_type\":\"newpay\",\"period_time\":4,\"unit\":\"hour\",\"resource_type\":\"cloudphone\",\"resource_param\":{\"pay_mode\":\"subscription\",\"config_id\":\"8dd93fc7-27bc-35bf-b3e4-3f2000ceb746\",\"network_id\":\"$N\",\"count\":1,\"use_points\":3,\"points\":250}}")

    AMT=$(echo "$RES" | grep -oP '(?<="amount_id":")[^"]*')
    if [[ -n "$AMT" ]]; then 
        PAY=$(curl --socks5-hostname 127.0.0.1:9050 -s -X POST "https://www.ugphone.com/api/apiv1/fee/payment" \
        -H "Content-Type: application/json;charset=UTF-8" \
        -H "terminal: web" -H "lang: vi" -H "update-date: $TODAY" \
        -H "login-id: $LID" -H "access-token: $TOKEN" \
        -d "{\"amount_id\":\"$AMT\",\"pay_channel\":\"free\"}")
        
        ORD=$(echo "$PAY" | grep -oP '(?<="order_id":")[^"]*')
        if [[ -n "$ORD" ]]; then 
            echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "  ${W}🏆 GIAO DỊCH THÀNH CÔNG!${NC}"
            echo -e "  ${W}📦 MÃ ĐƠN HÀNG:${NC} ${G}$ORD${NC}"
            echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        else 
            echo -e "  ${R}❌ Lỗi thanh toán: $PAY${NC}"
        fi
    else 
        echo -e "  ${R}❌ Lỗi hệ thống: Không lấy được thông tin giá.${NC}"
    fi
fi

pkill -9 tor > /dev/null 2>&1
echo -e "\n${GR}Gõ 'buy' để thực hiện giao dịch mới.${NC}"
EOF

# --- HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
grep -q "alias buy='buy'" ~/.bashrc || echo "alias buy='buy'" >> ~/.bashrc
source ~/.bashrc

echo -e "\n\033[1;32m✅ Hệ thống đã sẵn sàng. Gõ 'buy' để bắt đầu.\033[0m"
buy
