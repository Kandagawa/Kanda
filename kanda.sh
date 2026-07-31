#!/data/data/com.termux/files/usr/bin/bash

init_alias() {
    if ! grep -q "alias kanda=" ~/.bashrc; then
        echo "alias kanda='curl -Ls is.gd/kandaprx | bash'" >> ~/.bashrc
        echo -e 'echo -e "\\n\\033[1;30m Lệnh quay lại cấu hình nhập: \\033[1;36mkanda\\033[0m\\n"' >> ~/.bashrc
        if [ ! -f "$PREFIX/bin/kanda" ]; then
            echo -e '#!/data/data/com.termux/files/usr/bin/bash\ncurl -Ls is.gd/kandaprx | bash' > "$PREFIX/bin/kanda"
            chmod +x "$PREFIX/bin/kanda"
        fi
        source ~/.bashrc > /dev/null 2>&1
    fi
}

init_colors() {
    PURPLE='\033[1;38;5;141m'; CYAN='\033[1;36m'; GREEN='\033[1;32m'
    YELLOW='\033[1;33m'; RED='\033[1;31m'; WHITE='\033[1;37m'
    GREY='\033[1;30m'; BLUE='\033[1;34m'; NC='\033[0m'
    ORANGE='\033[1;38;5;209m'
}

# Hàm khởi tạo ngôn ngữ
init_language() {
    local lang_file="$PREFIX/etc/kanda_lang.conf"
    if [ -f "$lang_file" ]; then
        LANG_CODE=$(cat "$lang_file")
    else
        clear
        echo -e "\n  ${CYAN}SELECT LANGUAGE${NC}"
        echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ${YELLOW}a)${NC} ${WHITE}Vietnamese${NC}"
        echo -e "  ${YELLOW}b)${NC} ${WHITE}English${NC}"
        printf "\n  ${GREY}Your choice (a/b): ${NC}"
        read -n 1 -s lang_choice </dev/tty
        case "$lang_choice" in
            a|A) LANG_CODE="vn" ;;
            *) LANG_CODE="en" ;;
        esac
        echo "$LANG_CODE" > "$lang_file"
        clear
    fi
    
    if [ "$LANG_CODE" == "vn" ]; then
        TXT_SETUP="⚙️  SETUP LẦN ĐẦU"
        TXT_WARN="! Đảm bảo kết nối mạng ổn định"
        TXT_CHKSYS="[*] Đang kiểm tra hệ thống..."
        TXT_CFG_TITLE="🛠  CẤU HÌNH HỆ THỐNG"
        TXT_TOTAL="Tổng số IP đang hoạt động:"
        TXT_REGION="🌐 VÙNG QUỐC GIA"
        TXT_PROMPT_CT="Mã vùng (us, jp, vn, sg... | all):"
        TXT_GLOBAL_OK="✓ Đã chọn toàn cầu."
        TXT_CHK_IP="⏳ Đang kiểm tra IP cho"
        TXT_INVALID="✗ Mã không hợp lệ! Vui lòng nhập lại."
        TXT_TIME_TITLE="⏱ THỜI GIAN XOAY IP"
        TXT_PROMPT_MIN="Số phút (1 đến 9):"
        TXT_MIN_OK="✓ Đã đặt chu kỳ xoay:"
        TXT_MIN_ERR="✗ Chỉ nhập số từ 1 đến 9!"
        TXT_APPLY="Đang áp dụng cấu hình và khởi động hệ thống..."
        TXT_READY="✅ HỆ THỐNG ĐÃ SẴN SÀNG"
        TXT_ADDR="🔑 Địa chỉ  "
        TXT_CTRY="🌍 Quốc gia "
        TXT_CYC="⏱ Chu kỳ    "
        TXT_MIN="phút"
        TXT_CURR="📡 KẾT NỐI HIỆN TẠI"
        TXT_IP="🌐 IP thực   "
        TXT_LOC="📍 Vị trí    "
        TXT_SPD="⚡ Tốc độ    "
        TXT_SPD_LOAD="Đang đo tốc độ mạng..."
        TXT_COUNT="⏳ Đếm ngược xoay IP:"
        TXT_KEY_R="[Nhấn R] : Chọn lại cấu hình"
        TXT_KEY_X="[Nhấn X] : Xoay IP ngay lập tức"
        TXT_KEY_E="[Nhấn E] : Thoát khỏi ứng dụng"
        TXT_EXIT="❌ Đã thoát hệ thống. Tạm biệt!"
        TXT_ROT="⏳ ĐANG XOAY IP & TẢI DỮ LIỆU"
        TXT_WAIT="Vui lòng đợi hoàn tất..."
        TXT_ERR_LOW_1="✗ Quốc gia"
        TXT_ERR_LOW_2="chỉ có"
        TXT_ERR_LOW_3="IP (Quá ít). Vui lòng chọn quốc gia khác!"
        TXT_OK_LOW_1="✓ Quốc gia"
        TXT_OK_LOW_2="có"
        TXT_OK_LOW_3="IP đang hoạt động."
    else
        TXT_SETUP="⚙️  INITIAL SETUP"
        TXT_WARN="! Ensure stable network connection"
        TXT_CHKSYS="[*] Checking system..."
        TXT_CFG_TITLE="🛠  SYSTEM CONFIGURATION"
        TXT_TOTAL="Total active IPs:"
        TXT_REGION="🌐 REGION"
        TXT_PROMPT_CT="Country code (us, jp, vn, sg... | all):"
        TXT_GLOBAL_OK="✓ Global selected."
        TXT_CHK_IP="⏳ Checking IPs for"
        TXT_INVALID="✗ Invalid code! Please try again."
        TXT_TIME_TITLE="⏱ IP ROTATION TIME"
        TXT_PROMPT_MIN="Minutes (1 to 9):"
        TXT_MIN_OK="✓ Rotation cycle set:"
        TXT_MIN_ERR="✗ Enter numbers 1 to 9 only!"
        TXT_APPLY="Applying configuration and starting system..."
        TXT_READY="✅ SYSTEM IS READY"
        TXT_ADDR="🔑 Address  "
        TXT_CTRY="🌍 Country  "
        TXT_CYC="⏱ Cycle     "
        TXT_MIN="min"
        TXT_CURR="📡 CURRENT CONNECTION"
        TXT_IP="🌐 Real IP   "
        TXT_LOC="📍 Location  "
        TXT_SPD="⚡ Speed     "
        TXT_SPD_LOAD="Measuring network speed..."
        TXT_COUNT="⏳ IP rotation countdown:"
        TXT_KEY_R="[Press R] : Reconfigure"
        TXT_KEY_X="[Press X] : Rotate IP now"
        TXT_KEY_E="[Press E] : Exit application"
        TXT_EXIT="❌ System exited. Goodbye!"
        TXT_ROT="⏳ ROTATING IP & LOADING DATA"
        TXT_WAIT="Please wait to complete..."
        TXT_ERR_LOW_1="✗ Country"
        TXT_ERR_LOW_2="has only"
        TXT_ERR_LOW_3="IPs (Too few). Please choose another!"
        TXT_OK_LOW_1="✓ Country"
        TXT_OK_LOW_2="has"
        TXT_OK_LOW_3="active IPs."
    fi
}

render_bar() {
    local label=$1
    local percent=$2
    local w=30
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    
    printf "\r\033[K  ${GREY}${label}: ${NC}["
    printf "${CYAN}"
    for ((j=0; j<filled; j++)); do printf "█"; done
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "░"; done
    printf "${NC}] ${WHITE}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    pkill -P $$ > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
    rm -f "$PREFIX/tmp/progress_kanda" > /dev/null 2>&1
    rm -f "$PREFIX/tmp/kanda_speed.tmp" > /dev/null 2>&1
    rm -f "$PREFIX/tmp/kanda_newip.tmp" > /dev/null 2>&1
}

# Hàm lấy IP, Vị trí (Nhanh)
get_ip_info() {
    local json ip country code
    json=$(curl -s --max-time 10 --proxy 127.0.0.1:8118 "http://ip-api.com/json")
    
    if [ -z "$json" ]; then
        echo "Lỗi kết nối|Không xác định"
        return
    fi
    local status=$(echo "$json" | jq -r '.status' 2>/dev/null)
    if [ "$status" != "success" ]; then
        echo "Lỗi kết nối|Không xác định"
        return
    fi
    ip=$(echo "$json" | jq -r '.query')
    country=$(echo "$json" | jq -r '.country')
    code=$(echo "$json" | jq -r '.countryCode')
    echo "${ip}|${country} (${code})"
}

# Hàm đo tốc độ mạng ngầm (Mbps) cho lần kết nối đầu
test_speed_once() {
    rm -f "$PREFIX/tmp/kanda_speed.tmp"
    (
        speed_bytes=$(curl -s --max-time 15 -o /dev/null -w "%{speed_download}" --proxy 127.0.0.1:8118 "http://speedtest.tele2.net/1MB.zip")
        if [ -z "$speed_bytes" ] || [ "$speed_bytes" == "0.000" ]; then
            speed_mbps="0.00"
        else
            speed_mbps=$(awk -v s="$speed_bytes" 'BEGIN {printf "%.2f", (s * 8) / 1000000}')
        fi
        echo "$speed_mbps" > "$PREFIX/tmp/kanda_speed.tmp"
    ) &
}

select_country() {
    echo -e "\n  ${CYAN}${TXT_REGION}${NC}"
    while true; do
        printf "  ${GREY}└─▸${NC} ${GREY}${TXT_PROMPT_CT}${NC} ${YELLOW}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        
        if [[ "$clean_input" == "all" ]]; then
            display_country="TOÀN CẦU 🌍"
            country_code=""
            echo -e "      ${GREEN}${TXT_GLOBAL_OK}${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            
            # Kiểm tra số lượng IP của quốc gia vừa nhập
            printf "      ${GREY}${TXT_CHK_IP} ${YELLOW}${country_code^^}${GREY}...${NC}"
            country_nodes=$(curl -s "https://onionoo.torproject.org/summary?search=country:$country_code&running=true" | jq '.relays | length // 0' 2>/dev/null)
            
            # Xóa dòng "Đang kiểm tra..." và in kết quả
            printf "\r\033[K"
            
            if [[ -z "$country_nodes" || "$country_nodes" == "null" ]]; then
                country_nodes=0
            fi

            if [[ "$country_nodes" -lt 3 ]]; then
                echo -e "      ${RED}${TXT_ERR_LOW_1} ${YELLOW}${country_code^^}${RED} ${TXT_ERR_LOW_2} ${YELLOW}${country_nodes}${RED} ${TXT_ERR_LOW_3}${NC}"
            else
                display_country="${country_code^^}"
                echo -e "      ${GREEN}${TXT_OK_LOW_1} ${YELLOW}${country_code^^}${GREEN} ${TXT_OK_LOW_2} ${YELLOW}${country_nodes}${GREEN} ${TXT_OK_LOW_3}${NC}"
                break
            fi
        else
            echo -e "      ${RED}${TXT_INVALID}${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n  ${BLUE}${TXT_TIME_TITLE}${NC}"
    while true; do
        printf "  ${GREY}└─▸${NC} ${GREY}${TXT_PROMPT_MIN}${NC} ${YELLOW}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            echo -e "      ${GREEN}${TXT_MIN_OK} ${YELLOW}${minute_input} ${TXT_MIN}${NC}"
            break
        else
            echo -e "      ${RED}${TXT_MIN_ERR}${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n  ${GREY}${TXT_CHKSYS}${NC}"
    if ! command -v tor &>/dev/null || ! command -v privoxy &>/dev/null || ! command -v jq &>/dev/null; then
        render_bar "Tiến trình 1" 20
        pkg update -y -o Dpkg::Options::="--force-confold" > /dev/null 2>&1
        pkg install tor privoxy curl jq netcat-openbsd openssl -y -o Dpkg::Options::="--force-confold" > /dev/null 2>&1
        hash -r 
        render_bar "Tiến trình 1" 100
    else
        render_bar "Tiến trình 1" 100
    fi
    echo -e "" 
}

config_privoxy() {
    CONF_DIR="$PREFIX/etc/privoxy"
    CONF_FILE="$CONF_DIR/config"
    mkdir -p $CONF_DIR
    echo "listen-address 0.0.0.0:8118" > "$CONF_FILE"
    echo "forward-socks5t / 127.0.0.1:9050 ." >> "$CONF_FILE"
    privoxy --no-daemon "$CONF_FILE" > /dev/null 2>&1 &
}

config_tor() {
    mkdir -p "$PREFIX/var/lib/tor"
    chmod 700 "$PREFIX/var/lib/tor"
    mkdir -p $PREFIX/etc/tor
    TORRC="$PREFIX/etc/tor/torrc"
    echo -e "ControlPort 9051\nCookieAuthentication 0\nDataDirectory $PREFIX/var/lib/tor\nMaxCircuitDirtiness $sec\nCircuitBuildTimeout 15\nLog notice stdout" > "$TORRC"
    if [[ -n "$country_code" ]]; then
        strong_nodes=$(curl -s "https://onionoo.torproject.org/details?search=country:$country_code" | jq -r '.relays[] | select(.running==true and .advertised_bandwidth > 1048576) | .fingerprint' | tr '\n' ',' | sed 's/,$//')
        if [[ -n "$strong_nodes" ]]; then
            echo -e "ExitNodes $strong_nodes\nStrictNodes 1" >> "$TORRC"
        else
            echo -e "ExitNodes {$country_code}\nStrictNodes 1" >> "$TORRC"
        fi
    else
        echo -e "StrictNodes 0" >> "$TORRC"
    fi
}

run_tor() {
    render_bar "Tiến trình 2" 0
    local is_ready=false
    while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
            render_bar "Tiến trình 2" "$percent"
            if [ "$percent" -eq 100 ]; then
                is_ready=true
                break
            fi
        fi
    done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

    if [ "$is_ready" = true ]; then
        sleep 2 # Đợi mạch định tuyến ổn định
        
        # Lấy thông tin IP ban đầu
        ip_info=$(get_ip_info)
        ip_addr=$(echo "$ip_info" | cut -d'|' -f1)
        ip_loc=$(echo "$ip_info" | cut -d'|' -f2)
        
        # Bắt đầu đo tốc độ ngầm ngay lập tức
        test_speed_once
        
        local count=$sec
        local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        
        # Vòng lặp hiển thị kết quả và đếm ngược
        while [[ "$stop_flag" == "false" ]]; do
            clear
            echo -e "\n  ${GREEN}${TXT_READY}${NC}"
            echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "  ${WHITE} ${TXT_ADDR} :${NC} ${YELLOW}127.0.0.1:8118${NC}"
            echo -e "  ${WHITE} ${TXT_CTRY} :${NC} ${GREEN}${display_country}${NC}"
            echo -e "  ${WHITE} ${TXT_CYC} :${NC} ${BLUE}${minute_input} ${TXT_MIN}${NC} ${GREY}(${sec}s)${NC}"
            echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            
            # Phần hiển thị thông tin kết nối
            echo -e "\n  ${PURPLE}${TXT_CURR}${NC}"
            echo -e "  ${GREY}───────────────────────────────────────${NC}"
            echo -e "  ${WHITE} ${TXT_IP} :${NC} ${YELLOW}${ip_addr}${NC}"
            echo -e "  ${WHITE} ${TXT_LOC} :${NC} ${CYAN}${ip_loc}${NC}"
            
            # Logic hiển thị tốc độ mạng với hiệu ứng chờ
            if [ -f "$PREFIX/tmp/kanda_speed.tmp" ]; then
                ip_speed=$(cat "$PREFIX/tmp/kanda_speed.tmp")
                local speed_color=$GREEN
                if [[ "$ip_speed" =~ ^[0-9.]+$ ]]; then
                    if awk -v s="$ip_speed" 'BEGIN {exit !(s < 1.0)}'; then 
                        speed_color=$RED
                    elif awk -v s="$ip_speed" 'BEGIN {exit !(s < 5.0)}'; then 
                        speed_color=$YELLOW
                    fi
                else
                    ip_speed="0.00"
                    speed_color=$GREY
                fi
                echo -e "  ${WHITE} ${TXT_SPD} :${NC} ${speed_color}${ip_speed} Mbps${NC}"
            else
                printf "  ${WHITE} ${TXT_SPD} :${NC} ${ORANGE}%s${NC} ${GREY}${TXT_SPD_LOAD}${NC}\n" "${spin:$((count % 10)):1}"
            fi
            echo -e "  ${GREY}───────────────────────────────────────${NC}"
            
            # Phần thêm: Đồng hồ đếm ngược
            local mins=$((count / 60))
            local secs_left=$((count % 60))
            printf "\n  ${ORANGE}${TXT_COUNT}${NC} ${WHITE}%02d:%02d${NC}\n" "$mins" "$secs_left"
            
            echo -e "\n  ${GREY}» ${YELLOW}${TXT_KEY_R}${NC}"
            echo -e "  ${GREY}» ${YELLOW}${TXT_KEY_X}${NC}"
            echo -e "  ${GREY}» ${YELLOW}${TXT_KEY_E}${NC}\n"
            
            # Đọc phím trong 1 giây thay cho sleep 1
            read -t 1 -n 1 -s key </dev/tty
            if [[ "$key" == "r" || "$key" == "R" ]]; then
                stop_flag=true
                break
            elif [[ "$key" == "x" || "$key" == "X" ]]; then
                count=1 # Ép count về 1 để nhảy về 0 và xoay ngay
            elif [[ "$key" == "e" || "$key" == "E" ]]; then
                cleanup
                clear
                echo -e "\n  ${RED}${TXT_EXIT}${NC}\n"
                exit 0
            fi
            
            count=$((count - 1))
            
            # Khi hết giờ, xoay IP mới và gộp load tất cả thông tin
            if [ $count -le 0 ]; then
                clear
                echo -e "\n  ${CYAN}${TXT_ROT}${NC}"
                echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                
                # Chạy ngầm quá trình xoay, lấy IP và đo tốc độ gộp vào 1
                (
                    ( echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 ) > /dev/null 2>&1
                    sleep 3
                    new_ip_info=$(get_ip_info)
                    new_ip_addr=$(echo "$new_ip_info" | cut -d'|' -f1)
                    new_ip_loc=$(echo "$new_ip_info" | cut -d'|' -f2)
                    echo "${new_ip_addr}|${new_ip_loc}" > "$PREFIX/tmp/kanda_newip.tmp"
                    
                    speed_bytes=$(curl -s --max-time 15 -o /dev/null -w "%{speed_download}" --proxy 127.0.0.1:8118 "http://speedtest.tele2.net/1MB.zip")
                    if [ -z "$speed_bytes" ] || [ "$speed_bytes" == "0.000" ]; then
                        speed_mbps="0.00"
                    else
                        speed_mbps=$(awk -v s="$speed_bytes" 'BEGIN {printf "%.2f", (s * 8) / 1000000}')
                    fi
                    echo "$speed_mbps" > "$PREFIX/tmp/kanda_speed.tmp"
                ) &
                local load_pid=$!
                
                # Vòng lặp chờ tải xong
                local load_i=0
                while kill -0 $load_pid 2>/dev/null; do
                    printf "\r  ${ORANGE}%s${NC} ${GREY}${TXT_WAIT}${NC}" "${spin:$((load_i % 10)):1}"
                    load_i=$((load_i + 1))
                    sleep 0.1
                done
                printf "\r\033[K"
                
                # Cập nhật IP mới
                if [ -f "$PREFIX/tmp/kanda_newip.tmp" ]; then
                    ip_addr=$(cat "$PREFIX/tmp/kanda_newip.tmp" | cut -d'|' -f1)
                    ip_loc=$(cat "$PREFIX/tmp/kanda_newip.tmp" | cut -d'|' -f2)
                    rm -f "$PREFIX/tmp/kanda_newip.tmp"
                fi
                
                count=$sec
            fi
        done
    fi
}

main() {
    init_alias
    init_colors
    init_language
    clear
    
    echo -e "\n  ${CYAN}${TXT_SETUP}${NC}"
    echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}${TXT_WARN}${NC}"
    echo -e "  ${GREY}${TXT_CHKSYS}${NC}"
    
    install_services 

    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        
        echo -e "  ${PURPLE}${TXT_CFG_TITLE}${NC}"
        echo -e "  ${GREY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Fix lỗi buộc phải lấy total_nodes trước khi in ra
        total_nodes=$(curl -s "https://onionoo.torproject.org/summary?running=true" | jq '.relays | length')
        printf "\n  ${PURPLE}◈${NC} ${GREEN}${TXT_TOTAL}${NC} ${YELLOW}${total_nodes}${NC} ${GREY}IPs${NC}\n"
        
        select_country
        select_rotate_time
        
        echo -e "\n  ${GREY}${TXT_APPLY}${NC}"
        install_services
        config_privoxy
        config_tor
        run_tor
        
        while [[ "$stop_flag" == "false" ]]; do 
            sleep 0.5
        done
        trap - SIGINT
    done
}

main
