#!/data/data/com.termux/files/usr/bin/bash

# --- 1. SETUP HỆ THỐNG ---
echo -e "\033[1;33m📦 Đang tối ưu hệ thống & Lọc Node sống... \033[0m"
pkg install curl jq tor -y > /dev/null 2>&1

# --- 2. TẠO LỆNH BUY ---
cat << 'EOF' > $PREFIX/bin/buy
#!/data/data/com.termux/files/usr/bin/bash

# Bảng màu chuyên nghiệp
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; NC='\033[0m'
W='\033[1;37m'; GR='\033[1;30m'; P='\033[1;38;5;141m'

# --- BƯỚC 1: XÁC THỰC JSON ---
while true; do
    clear
    echo -e "\n    ${P}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "    ${P}┃${NC}     ${W}UGPHONE TERMINAL EXECUTOR${NC}      ${P}┃${NC}"
    echo -e "    ${P}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "    ${GR}  Trạng thái: Đang chờ dữ liệu Auth...${NC}\n"
    
    while read -t 0.1 -n 10000 discard; do :; done
    
    echo -ne "    ${C}❯${NC} ${W}Dán JSON tại đây:${NC} "
    read -r DATA
    
    if [ ${#DATA} -gt 150 ]; then
        LID=$(echo "$DATA" | grep -oP '(?<="login_id":")[^"]*' | head -n 1)
        TOKEN=$(echo "$DATA" | grep -oP '(?<="access_token":")[^"]*' | head -n 1)
        if [[ -n "$LID" && -n "$TOKEN" ]]; then break; fi
    fi
    echo -e "\n    ${R}✘ Lỗi: Dữ liệu JSON không hợp lệ!${NC}"
    sleep 1.2
done

# Nhận quà ngầm
curl -s -X POST "https://www.ugphone.com/api/apiv1/fee/newPackage" \
-H "Content-Type: application/json;charset=UTF-8" \
-H "login-id: $LID" -H "access-token: $TOKEN" -d "{}" > /dev/null &

# --- BƯỚC 2: CHỌN VÙNG ---
while true; do
    clear
    echo -e "\n    ${P}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "    ${P}┃${NC}    ${G}ID:${NC} ${W}${LID:0:20}...${NC}      ${P}┃${NC}"
    echo -e "    ${P}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "    ${W}Vui lòng chọn khu vực giao dịch:${NC}\n"
    echo -e "      ${C}01.${NC} Nhật Bản (JP)    ${C}02.${NC} Singapore (SG)"
    echo -e "      ${C}03.${NC} Hoa Kỳ (US)      ${C}04.${NC} Đức (DE)"
    echo -e "      ${C}05.${NC} Hồng Kông (HK)"
    echo -e "\n    ${GR}────────────────────────────────────────${NC}"
    echo -ne "    ${C}❯${NC} ${W}Nhập số:${NC} "
    read -r CH
    
    case $CH in 
        1|01) N="07fb1cda-f347-7e09-f50d-a8d894f2ffea"; break;;
        2|02) N="3731f6bf-b812-e983-872b-152cdab81276"; break;;
        3|03) N="b0b20248-b103-b041-3480-e90675c57a4f"; break;;
        4|04) N="9f1980ab-6d4b-5192-a19f-c6d4bc5d3a47"; break;;
        5|05) N="82542031-4021-397a-9774-4b5311096a66"; break;;
    esac
done

# --- BƯỚC 3: LỌC NODE NGẪU NHIÊN & SỐNG ---
clear
echo -e "\n    ${P}●${NC} ${W}Hãy chờ tiến trình...${NC}"

# Lấy danh sách các node Running, Fast, Stable và bóc ngẫu nhiên 30 node
LIVEL_NODES=$(curl -s "https://onionoo.torproject.org/summary?running=true" | jq -r '.relays[] | select(.f | contains("V")) | .f' | shuf -n 30 | tr '\n' ',' | sed 's/,$//')

pkill -9 tor > /dev/null 2>&1
rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
mkdir -p "$PREFIX/var/lib/tor" && chmod 700 "$PREFIX/var/lib/tor"
TORRC="$PREFIX/etc/tor/torrc_mua"

# Cấu hình Tor không giới hạn vùng để tối ưu tốc độ nhưng dùng EntryNodes sống
echo -e "DataDirectory $PREFIX/var/lib/tor\nSocksPort 9050" > "$TORRC"
[[ -n "$LIVEL_NODES" ]] && echo -e "EntryNodes $LIVEL_NODES" >> "$TORRC"

is_ready=false
while read -r line; do
    if [[ "$line" == *"Bootstrapped"* ]]; then
        percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
        printf "\r    ${GR}Kết nối mạng: ${NC}${G}%d%%${NC} " "$percent"
        if [ "$percent" -eq 100 ]; then 
            is_ready=true; sleep 1; break 
        fi
    fi
done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

# --- BƯỚC 4: GIAO DỊCH ---
if [ "$is_ready" = true ]; then
    echo -e "\n\n    ${Y}●${NC} ${W}Đang thực thi lệnh mua...${NC}"
    
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
            echo -e "\n    ${G}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
            echo -e "    ${G}┃${NC}     ${W}GIAO DỊCH HOÀN TẤT THÀNH CÔNG${NC}     ${G}┃${NC}"
            echo -e "    ${G}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
            echo -e "    ${W}Mã Đơn:${NC} ${C}$ORD${NC}\n"
        else 
            echo -e "\n    ${R}✘ Giao dịch thất bại:${NC} $PAY"
        fi
    else 
        echo -e "\n    ${R}✘ Lỗi: Không lấy được thông tin gói.${NC}"
    fi
fi

pkill -9 tor > /dev/null 2>&1
echo -e "    ${GR}Gõ 'buy' để thực hiện lại.${NC}\n"
EOF

# --- 3. HOÀN TẤT ---
chmod +x $PREFIX/bin/buy
grep -q "alias buy='buy'" ~/.bashrc || echo "alias buy='buy'" >> ~/.bashrc

clear
echo -e "\n    \033[1;32m✅ HOÀN THÀNH!\033[0m"
echo -e "    \033[1;37mGõ lệnh: \033[1;36mbuy\033[0m\n"
