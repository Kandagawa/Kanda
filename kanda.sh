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

render_bar() {
    local label=$1
    local percent=$2
    local w=30
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    
    printf "\r\033[K  ${CYAN}${label}${NC} ${GREY}[${NC}"
    printf "${GREEN}"
    for ((j=0; j<filled; j++)); do printf "█"; done
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "░"; done
    printf "${GREY}]${NC} ${YELLOW}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    pkill -P $$ > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
    rm -f "$PREFIX/tmp/progress_kanda" > /dev/null 2>&1
    rm -f "$PREFIX/tmp/kanda_ip_info.tmp" > /dev/null 2>&1
}

# Hàm lấy IP, Vị trí, Tốc độ (Mbps)
get_ip_info() {
    local json ip country code speed_bytes speed_mbps
    json=$(curl -s --max-time 10 --proxy 127.0.0.1:8118 "http://ip-api.com/json")
    
    if [ -z "$json" ]; then
        echo "Lỗi kết nối|Không xác định|0.00"
        return
    fi
    local status=$(echo "$json" | jq -r '.status' 2>/dev/null)
    if [ "$status" != "success" ]; then
        echo "Lỗi kết nối|Không xác định|0.00"
        return
    fi
    ip=$(echo "$json" | jq -r '.query')
    country=$(echo "$json" | jq -r '.country')
    code=$(echo "$json" | jq -r '.countryCode')
    
    # Đo tốc độ tải file 1MB qua proxy (tính bằng bytes/giây)
    speed_bytes=$(curl -s --max-time 15 -o /dev/null -w "%{speed_download}" --proxy 127.0.0.1:8118 "http://speedtest.tele2.net/1MB.zip")
    
    if [ -z "$speed_bytes" ] || [ "$speed_bytes" == "0.000" ]; then
        speed_mbps="0.00"
    else
        # Quy đổi sang Mbps (1 Byte = 8 bits, 1 Mbps = 1000000 bits)
        speed_mbps=$(awk -v s="$speed_bytes" 'BEGIN {printf "%.2f", (s * 8) / 1000000}')
    fi
    echo "${ip}|${country} (${code})|${speed_mbps}"
}

select_country() {
    echo -e "\n  ${CYAN}┌─ ${WHITE}🌐 VÙNG QUỐC GIA${NC}"
    while true; do
        printf "  ${CYAN}└─▸${NC} ${GREY}Mã vùng (us, jp, vn, sg... | all):${NC} ${YELLOW}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        
        if [[ "$clean_input" == "all" ]]; then
            display_country="TOÀN CẦU 🌍"
            country_code=""
            echo -e "      ${GREEN}✓ Đã chọn toàn cầu.${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            
            # Kiểm tra số lượng node của quốc gia vừa nhập
            printf "      ${GREY}⏳ Đang kiểm tra node cho ${YELLOW}${country_code^^}${GREY}...${NC}"
            country_nodes=$(curl -s "https://onionoo.torproject.org/summary?search=country:$country_code&running=true" | jq '.relays | length // 0' 2>/dev/null)
            
            # Xóa dòng "Đang kiểm tra..." và in kết quả
            printf "\r\033[K"
            
            if [[ -z "$country_nodes" || "$country_nodes" == "null" ]]; then
                country_nodes=0
            fi

            if [[ "$country_nodes" -lt 3 ]]; then
                echo -e "      ${RED}✗ Quốc gia ${YELLOW}${country_code^^}${RED} chỉ có ${YELLOW}${country_nodes}${RED} node (Quá ít). Vui lòng chọn quốc gia khác!${NC}"
            else
                display_country="${country_code^^}"
                echo -e "      ${GREEN}✓ Quốc gia ${YELLOW}${country_code^^}${GREEN} có ${YELLOW}${country_nodes}${GREEN} node đang hoạt động.${NC}"
                break
            fi
        else
            echo -e "      ${RED}✗ Mã không hợp lệ! Vui lòng nhập lại.${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n  ${BLUE}┌─ ${WHITE}⏱ THỜI GIAN XOAY IP${NC}"
    while true; do
        printf "  ${BLUE}└─▸${NC} ${GREY}Số phút (1 đến 9):${NC} ${YELLOW}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            echo -e "      ${GREEN}✓ Đã đặt chu kỳ xoay: ${YELLOW}${minute_input} phút${NC}"
            break
        else
            echo -e "      ${RED}✗ Chỉ nhập số từ 1 đến 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    echo -e "\n  ${GREY}⚙️  Đang kiểm tra hệ thống...${NC}"
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
        
        # Lấy thông tin IP và tốc độ mạng ngầm
        ( get_ip_info > "$PREFIX/tmp/kanda_ip_info.tmp" ) &
        local pid=$!
        
        local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0
        while kill -0 $pid 2>/dev/null; do
            printf "\r\033[K  ${GREY}${spin:$((i % 10)):1} Đang kiểm tra IP và tốc độ mạng...${NC}"
            i=$((i + 1))
            sleep 0.1
        done
        printf "\r\033[K"
        
        ip_info=$(cat "$PREFIX/tmp/kanda_ip_info.tmp" 2>/dev/null)
        ip_addr=$(echo "$ip_info" | cut -d'|' -f1)
        ip_loc=$(echo "$ip_info" | cut -d'|' -f2)
        ip_speed=$(echo "$ip_info" | cut -d'|' -f3)
        
        local count=$sec
        
        # Vòng lặp hiển thị kết quả và đếm ngược
        while [[ "$stop_flag" == "false" ]]; do
            clear
            echo -e "\n  ${GREEN}╭───────────────────────────────────────────╮${NC}"
            echo -e "  ${GREEN}│${NC}      ${WHITE}✅ HỆ THỐNG ĐÃ SẴN SÀNG${NC}            ${GREEN}│${NC}"
            echo -e "  ${GREEN}╰───────────────────────────────────────────╯${NC}"
            
            echo -e "  ${GREY}───────────────────────────────────────────${NC}"
            echo -e "  ${WHITE} 🔑 Địa chỉ  :${NC} ${YELLOW}127.0.0.1:8118${NC}"
            echo -e "  ${WHITE} 🌍 Quốc gia :${NC} ${GREEN}${display_country}${NC}"
            echo -e "  ${WHITE} ⏱ Chu kỳ    :${NC} ${BLUE}${minute_input} phút${NC} ${GREY}(${sec}s)${NC}"
            echo -e "  ${GREY}───────────────────────────────────────────${NC}"
            
            # Phần hiển thị thông tin kết nối
            echo -e "  ${PURPLE}╭─ ${WHITE}📡 KẾT NỐI HIỆN TẠI${NC}"
            echo -e "  ${PURPLE}│${NC}  ${WHITE}🌐 IP thực   :${NC} ${YELLOW}${ip_addr}${NC}"
            echo -e "  ${PURPLE}│${NC}  ${WHITE}📍 Vị trí    :${NC} ${CYAN}${ip_loc}${NC}"
            
            # Đổi màu tốc độ mạng (Mbps)
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
            echo -e "  ${PURPLE}│${NC}  ${WHITE}⚡ Tốc độ    :${NC} ${speed_color}${ip_speed} Mbps${NC}"
            echo -e "  ${PURPLE}╰───────────────────────────────────────────${NC}"
            
            # Phần thêm: Đồng hồ đếm ngược (Sử dụng printf để fix lỗi %02d:%02d)
            local mins=$((count / 60))
            local secs_left=$((count % 60))
            printf "\n  ${ORANGE}⏳ Đếm ngược xoay IP:${NC} ${WHITE}%02d:%02d${NC}\n" "$mins" "$secs_left"
            
            echo -e "\n  ${GREY}» ${RED}[CTRL+C]${GREY}           : Đặt lại cấu hình${NC}"
            echo -e "  ${GREY}» ${RED}[CTRL+C]+[CTRL+Z]${GREY}  : Dừng hoàn toàn${NC}\n"
            
            sleep 1
            count=$((count - 1))
            
            # Khi hết giờ, xoay IP mới
            if [ $count -le 0 ]; then
                clear
                echo -e "\n  ${CYAN}⏳ Đang xoay IP mới, vui lòng đợi...${NC}"
                ( echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 ) > /dev/null 2>&1
                sleep 3 # Đợi tạo mạch mới
                
                # Lấy thông tin IP và tốc độ mạng ngầm
                ( get_ip_info > "$PREFIX/tmp/kanda_ip_info.tmp" ) &
                local pid=$!
                
                local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
                local i=0
                while kill -0 $pid 2>/dev/null; do
                    printf "\r\033[K  ${GREY}${spin:$((i % 10)):1} Đang cập nhật IP và tốc độ mới...${NC}"
                    i=$((i + 1))
                    sleep 0.1
                done
                printf "\r\033[K"
                
                # Cập nhật IP mới
                ip_info=$(cat "$PREFIX/tmp/kanda_ip_info.tmp" 2>/dev/null)
                ip_addr=$(echo "$ip_info" | cut -d'|' -f1)
                ip_loc=$(echo "$ip_info" | cut -d'|' -f2)
                ip_speed=$(echo "$ip_info" | cut -d'|' -f3)
                count=$sec
            fi
        done
    fi
}

main() {
    init_alias
    init_colors
    clear
    
    echo -e "\n  ${PURPLE}╭───────────────────────────────────────────╮${NC}"
    echo -e "  ${PURPLE}│${NC}      ${CYAN}⚙️  KANDA PROXY SYSTEM${NC}         ${PURPLE}│${NC}"
    echo -e "  ${PURPLE}╰───────────────────────────────────────────╯${NC}"
    echo -e "  ${YELLOW}! Đảm bảo kết nối mạng ổn định${NC}"
    echo -e "  ${GREY}[*] Đang kiểm tra hệ thống...${NC}"
    
    install_services 

    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        
        echo -e "  ${PURPLE}╭───────────────────────────────────────────╮${NC}"
        echo -e "  ${PURPLE}│${NC}     ${WHITE}🛠  CẤU HÌNH HỆ THỐNG${NC}            ${PURPLE}│${NC}"
        echo -e "  ${PURPLE}╰───────────────────────────────────────────╯${NC}"
        
        # Fix lỗi buộc phải lấy total_nodes trước khi in ra
        total_nodes=$(curl -s "https://onionoo.torproject.org/summary?running=true" | jq '.relays | length')
        printf "\n  ${PURPLE}◈${NC} ${GREEN}Tổng số Node đang hoạt động:${NC} ${YELLOW}${total_nodes}${NC} ${GREY}nodes${NC}\n"
        
        select_country
        select_rotate_time
        
        echo -e "\n  ${GREY}Đang áp dụng cấu hình và khởi động Tor...${NC}"
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
