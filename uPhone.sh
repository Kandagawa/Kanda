#!/data/data/com.termux/files/usr/bin/bash

# --- 1. KIỂM TRA HỆ THỐNG ---
if ! command -v tor &> /dev/null || ! command -v jq &> /dev/null; then
    echo -e "\033[1;33m📦 Đang chuẩn bị gói hỗ trợ... \033[0m"
    pkg install curl jq tor -y > /dev/null 2>&1
fi

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# --- MÀU SẮC TỐI GIẢN ---
G='\033[32m'; R='\033[31m'; Y='\033[33m'; C='\033[36m'; NC='\033[0m'
W='\033[37m'; GR='\033[90m'; P='\033[38;5;141m'
TODAY=$(date +%Y%m%d)

render_bar() {
    local label=$1; local percent=$2; local w=20
    local filled=$((percent*w/100)); local empty=$((w-filled))
    printf "\r  ${GR}${label}${NC} "
    for ((j=0; j<filled; j++)); do printf "${C}●${NC}"; done
    for ((j=0; j<empty; j++)); do printf "${GR}○${NC}"; done
    printf " ${W}%d%%${NC}" "$percent"
}

clear

# --- BƯỚC 1: NHẬP LIỆU (CHỐNG SPAM KIỂU KANDA) ---
# Quét sạch bộ nhớ đệm trước khi bắt đầu
while read -t 0.1 -n 10000 discard; do :; done

while true; do
    echo -ne "${C}❯${NC} ${W}Dán JSON:${NC} "
    # Đọc dữ liệu trực tiếp từ tty để tránh bị trôi lệnh
    read -r DATA </dev/tty
    
    # Chỉ xử lý nếu chuỗi đủ dài (JSON thật luôn > 200 ký tự)
    # Nếu ngắn quá, script sẽ lặng lẽ xóa màn hình và chờ tiếp, không báo lỗi gây spam
    if [ ${#DATA} -gt 150 ]; then
        LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
        TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)

        if [[ -n "$LID" && -n "$TOKEN" ]]; then
            echo -e "  ${G}✔${NC} ${GR}Xác thực: $LID${NC}"
            break
        fi
    fi
    
    # Nếu spam Enter hoặc dán sai, làm sạch màn hình và hiện lại lời mời nhập
    clear
    echo -e "${P}●${NC} ${W}Hệ thống đang chờ JSON hợp lệ...${NC} ${GR}(Vui lòng dán rồi ấn Enter)${NC}"
done

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
echo -e "\n${C}❯${NC} ${W}Vùng:${NC} ${GR}1-JP | 2-SG | 3-US | 4-DE | 5-HK${NC}"
while true; do
    echo -ne "  ${W}Chọn số:${NC} "
    read -r CH </dev/tty
    case $CH in 
        1) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; CC="jp"; break;;
        2) N="3731f6bf-b812-e983-872b-152cdab81276"; CC="sg"; break;;
        3) N="b0b20248-b103-b041-3480-e90675c57a4f"; CC="us"; break;;
        4) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; CC="de"; break;;
        5) N="82542031-4021-397a-9774-4b5311096a66"; CC="hk"; break;;
        *) echo -e "  ${R}✘ Chọn lại!${NC}";;
    esac
done

# --- BƯỚC 3: KẾT NỐI PROXY ---
pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

echo -e "\n${C}❯${NC} ${W}Đang kết nối đường truyền ($CC)...${NC}"
echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 9050\nExitNodes {$CC}\nStrictNodes 1" > "$TORRC"

is_ready=false
while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        render_bar "Proxy" "$percent"
        if [ "$percent" -eq 100 ]; then is_ready=true; break; fi
    fi
done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

# --- BƯỚC 4: GIAO DỊCH ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n${Y}●${NC} ${W}Đang thực hiện mua...${NC}"
    
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
            echo -e "${G}✔ THÀNH CÔNG!${NC} ${W}Mã đơn: $ORD${NC}"
        else 
            echo -e "${R}✘ THẤT BẠI:${NC} $PAY"
        fi
    else 
        echo -e "${R}✘ LỖI HỆ THỐNG:${NC} Không lấy được thông tin giá."
    fi
fi

pkill -9 tor > /dev/null 2>&1
EOF

# --- HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
source ~/.bashrc
echo -e "\033[32m✔ Đã sẵn sàng. Gõ 'buy' để bắt đầu.\033[0m"
buy
