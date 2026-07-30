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
    GREY='\033[1;38;5;240m'; BLUE='\033[1;34m'; NC='\033[0m'
    ORANGE='\033[1;38;5;209m'; PINK='\033[1;38;5;198m'
}

spinner() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r\033[K      ${ORANGE}${spin:$i:1}${NC} ${GREY}${msg}...${NC}"
        i=$(( (i+1) % 10 ))
        sleep 0.08
    done
    printf "\r\033[K"
}

render_bar() {
    local label=$1
    local percent=$2
    local w=25
    local filled=$((percent*w/100))
    local empty=$((w-filled))
    
    printf "\r\033[K  ${GREY}${label} ${NC}"
    printf "${CYAN}"
    for ((j=0; j<filled; j++)); do printf "▰"; done
    printf "${GREY}"
    for ((j=0; j<empty; j++)); do printf "▱"; done
    printf " ${WHITE}%d%%${NC}" "$percent"
}

cleanup() {
    pkill -9 tor > /dev/null 2>&1
    pkill -9 privoxy > /dev/null 2>&1
    pkill -f "SIGNAL NEWNYM" > /dev/null 2>&1
    pkill -P $$ > /dev/null 2>&1
    rm -rf $PREFIX/var/lib/tor/* > /dev/null 2>&1
    rm -f "$PREFIX/tmp/progress_kanda" > /dev/null 2>&1
}

# Hàm lấy thông tin IP, Vị trí và Tốc độ mạng
get_ip_info() {
    local start_time end_time latency json ip country code
    start_time=$(date +%s.%N)
    json=$(curl -s --max-time 10 --proxy 127.0.0.1:8118 "http://ip-api.com/json")
    end_time=$(date +%s.%N)
    
    if [[ -z "$json" || "$(echo "$json" | jq -r '.status' 2>/dev/null)" != "success" ]]; then
        echo "Lỗi kết nối|Không xác định|0"
        return
    fi
    
    ip=$(echo "$json" | jq -r '.query')
    country=$(echo "$json" | jq -r '.country')
    code=$(echo "$json" | jq -r '.countryCode')
    latency=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN {t = (e - s) * 1000; printf "%.0f", t}')
    
    echo "${ip}|${country} (${code})|${latency}"
}

# Hàm vẽ bảng điều khiển trực tiếp
display_status() {
    local ip=$1
    local loc=$2
    local ping=$3
    local countdown=$4
    
    # Định dạng thời gian đếm ngược MM:SS
    local mins=$((countdown / 60))
    local secs=$((countdown % 60))
    
    # Đổi màu tốc độ mạng theo độ trễ
    local ping_color=$GREEN
    if [[ $ping -gt 500 ]]; then 
        ping_color=$RED; 
    elif [[ $ping -gt 200 ]]; then 
        ping_color=$YELLOW; 
    fi
    
    clear
    echo -e "  ${GREEN}╭─── ${WHITE}✅ HỆ THỐNG ĐANG HOẠT ĐỘNG${NC}"
    echo -e "  ${GREEN}│"
    echo -e "  ${GREEN}│${NC}  ${WHITE}◈ Cổng Proxy:${NC} ${YELLOW}127.0.0.1:8118${NC}"
    echo -e "  ${GREEN}│${NC}  ${WHITE}◈ Vùng chọn  :${NC} ${CYAN}${display_country}${NC}"
    echo -e "  ${GREEN}│${NC}  ${WHITE}◈ Chu kỳ XOAY:${NC} ${BLUE}${minute_input} phút${NC}"
    echo -e "  ${GREEN}╰──────────────────────────────────────────${NC}"
    
    echo -e "  ${PURPLE}╭─ ${WHITE}📡 THÔNG TIN KẾT NỐI HIỆN TẠI${NC}"
    echo -e "  ${PURPLE}│${NC}  ${WHITE}Địa chỉ IP :${NC} ${YELLOW}${ip}${NC}"
    echo -e "  ${PURPLE}│${NC}  ${WHITE}Vị trí     :${NC} ${CYAN}${loc}${NC}"
    echo -e "  ${PURPLE}│${NC}  ${WHITE}Tốc độ     :${NC} ${ping_color}${ping} ms${NC}"
    echo -e "  ${PURPLE}╰──────────────────────────────────────────${NC}"
    
    echo -e "  ${ORANGE}⏳ Đếm ngược xoay IP:${NC} ${WHITE}%02d:%02d${NC}" "$mins" "$secs"
    
    echo -e "\n  ${GREY}╭─ HƯỚNG DẪN${NC}"
    echo -e "  ${GREY}├─▸${NC} ${RED}[CTRL+C]${GREY}           : Đặt lại cấu hình${NC}"
    echo -e "  ${GREY}└─▸${NC} ${RED}[CTRL+C]+[CTRL+Z]${GREY}  : Dừng hoàn toàn${NC}\n"
}

select_country() {
    echo -e "  ${CYAN}╭─ ${WHITE}🌐 VÙNG QUỐC GIA${NC}"
    while true; do
        printf "  ${CYAN}├─▸${NC} ${GREY}Mã vùng (us, jp, vn, sg... | all):${NC} ${YELLOW}"
        read input </dev/tty
        clean_input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        
        if [[ "$clean_input" == "all" ]]; then
            display_country="TOÀN CẦU 🌍"
            country_code=""
            echo -e "  ${CYAN}╰─▸${NC} ${GREEN}✓ Đã chọn toàn cầu.${NC}"
            break
        elif [[ "$clean_input" =~ ^[a-z]{2}$ ]]; then
            country_code="$clean_input"
            
            ( curl -s "https://onionoo.torproject.org/summary?search=country:$country_code&running=true" | jq '.relays | length' > /tmp/kanda_nodes.tmp 2>/dev/null ) &
            local pid=$!
            spinner $pid "Đang kiểm tra node cho ${country_code^^}"
            wait $pid
            
            country_nodes=$(cat /tmp/kanda_nodes.tmp 2>/dev/null)
            rm -f /tmp/kanda_nodes.tmp
            
            if [[ -z "$country_nodes" || "$country_nodes" == "null" ]]; then
                country_nodes=0
            fi

            if [[ "$country_nodes" -lt 3 ]]; then
                echo -e "  ${CYAN}├─▸${NC} ${RED}✗ Node quá ít (${country_nodes} node). Vui lòng chọn quốc gia khác!${NC}"
            else
                display_country="${country_code^^}"
                echo -e "  ${CYAN}╰─▸${NC} ${GREEN}✓ Tìm thấy ${YELLOW}${country_nodes}${GREEN} node đang hoạt động.${NC}"
                break
            fi
        else
            echo -e "  ${CYAN}├─▸${NC} ${RED}✗ Mã không hợp lệ! Vui lòng nhập lại.${NC}"
        fi
    done
}

select_rotate_time() {
    echo -e "\n  ${BLUE}╭─ ${WHITE}⏱ THỜI GIAN XOAY IP${NC}"
    while true; do
        printf "  ${BLUE}├─▸${NC} ${GREY}Số phút (1 đến 9):${NC} ${YELLOW}"
        read minute_input </dev/tty
        if [[ "$minute_input" =~ ^[1-9]$ ]]; then
            sec=$((minute_input * 60))
            echo -e "  ${BLUE}╰─▸${NC} ${GREEN}✓ Cấu hình xoay IP mỗi ${YELLOW}${minute_input}${GREEN} phút.${NC}"
            break
        else
            echo -e "  ${BLUE}├─▸${NC} ${RED}✗ Chỉ nhập số từ 1 đến 9!${NC}"
        fi
    done
}

install_services() {
    cleanup
    if ! command -v tor &>/dev/null || ! command -v privoxy &>/dev/null || ! command -v jq &>/dev/null; then
        render_bar "⚙ Cài đặt   " 20
        ( pkg update -y -o Dpkg::Options::="--force-confold" > /dev/null 2>&1 && \
          pkg install tor privoxy curl jq netcat-openbsd openssl -y -o Dpkg::Options::="--force-confold" > /dev/null 2>&1 ) &
        local pid=$!
        spinner $pid "Đang cài đặt gói dịch vụ"
        wait $pid
        hash -r 
        render_bar "⚙ Cài đặt   " 100
    else
        render_bar "⚙ Hệ thống  " 100
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
    render_bar "🛡 Kết nối   " 0
    local is_ready=false
    while read -r line; do
        [[ "$stop_flag" == "true" ]] && break
        if [[ "$line" == *"Bootstrapped"* ]]; then
            percent=$(echo "$line" | grep -oP "\d+%" | head -1 | tr -d '%')
            render_bar "🛡 Kết nối   " "$percent"
            if [ "$percent" -eq 100 ]; then
                is_ready=true
                break
            fi
        fi
    done < <(stdbuf -oL tor -f "$TORRC" 2>/dev/null)

    if [ "$is_ready" = true ]; then
        sleep 2 # Đợi mạch định tuyến ổn định
        return 0
    else
        return 1
    fi
}

main() {
    init_alias
    init_colors
    clear
    
    echo -e "\n  ${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "  ${PURPLE}║${NC}  ${CYAN}░K░A░N░D░A░ ${WHITE}P R O X Y${NC}  ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo -e "  ${YELLOW}! Đảm bảo kết nối mạng ổn định${NC}"
    
    ( curl -s "https://onionoo.torproject.org/summary?running=true" | jq '.relays | length' > /tmp/kanda_total.tmp 2>/dev/null ) &
    local pid=$!
    spinner $pid "Đang đồng bộ hệ thống"
    wait $pid
    total_nodes=$(cat /tmp/kanda_total.tmp 2>/dev/null)
    rm -f /tmp/kanda_total.tmp
    
    install_services 

    while true; do
        stop_flag=false
        trap 'stop_flag=true' SIGINT
        cleanup
        clear
        
        echo -e "  ${PURPLE}╭─── ${WHITE}🛠 CẤU HÌNH HỆ THỐNG${NC}"
        echo -e "  ${PURPLE}│"
        echo -e "  ${PURPLE}│${NC}  ${WHITE}🌐 Tổng Node:${NC} ${CYAN}${total_nodes:-N/A}${NC} ${GREY}đang chạy${NC}"
        echo -e "  ${PURPLE}╰──────────────────────────────────────────${NC}"
        
        select_country
        select_rotate_time
        
        echo -e "\n  ${GREY}╭─ ${WHITE}KHỞI ĐỘNG${NC}"
        echo -e "  ${GREY}│${NC}"
        install_services
        config_privoxy
        config_tor
        
        if run_tor; then
            # Lấy thông tin IP ban đầu
            IFS='|' read -r ip_addr ip_loc ip_ping <<< "$(get_ip_info)"
            
            local count=$sec
            while [[ "$stop_flag" == "false" ]]; do
                display_status "$ip_addr" "$ip_loc" "$ip_ping" "$count"
                sleep 1
                count=$((count - 1))
                
                if [[ $count -le 0 ]]; then
                    # Xoay IP mới
                    ( echo -e "AUTHENTICATE \"\"\nSIGNAL NEWNYM\nQUIT" | nc 127.0.0.1 9051 ) > /dev/null 2>&1
                    sleep 5 # Đợi tạo mạch mới
                    # Lấy thông tin IP mới
                    IFS='|' read -r ip_addr ip_loc ip_ping <<< "$(get_ip_info)"
                    count=$sec
                fi
            done
        fi
        trap - SIGINT
    done
}

main
