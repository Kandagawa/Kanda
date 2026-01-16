// ==UserScript==
// @name         Kanda Proxy Control - Minimal
// @namespace    https://github.com/Kandagawa/
// @version      5.0.0
// @description  Bật/Tắt Proxy và Hiển thị trạng thái IP xoay 1 phút
// @author       Kanda
// @match        *://*/*
// @icon         https://www.google.com/s2/favicons?domain=torproject.org
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @connect      ipapi.co
// ==/UserScript==

(function() {
    'use strict';

    const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);

    // 1. CSS Giao diện tối giản cực hạn
    const css = `
        #kanda-panel {
            position: fixed !important; 
            top: ${isMobile ? '20%' : '20px'} !important; 
            right: ${isMobile ? '5%' : '20px'} !important; 
            width: ${isMobile ? '90%' : '240px'} !important;
            background: #ffffff !important; border-radius: 20px !important;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2) !important; z-index: 2147483647 !important;
            font-family: sans-serif !important; padding: 20px !important; display: none;
            border: 1px solid #eee !important; text-align: center !important;
        }
        #kanda-panel h3 { margin: 0 0 10px !important; font-size: 16px !important; color: #7D4698 !important; }
        .ip-status {
            font-size: 12px !important; color: #666 !important; margin-bottom: 20px !important;
            background: #f8f9fa !important; padding: 10px !important; border-radius: 10px !important;
        }
        .kanda-btn {
            width: 100% !important; padding: 12px !important;
            border: none !important; border-radius: 12px !important; cursor: pointer !important;
            font-weight: bold !important; color: white !important; font-size: 15px !important;
            background: #007bff !important; transition: 0.2s !important;
        }
        .kanda-btn:hover { background: #0056b3 !important; }
        #kanda-toggle {
            position: fixed !important; bottom: 25px !important; right: 25px !important; 
            width: 50px !important; height: 50px !important;
            background: #7D4698 !important; color: white !important; border-radius: 50% !important;
            display: flex !important; align-items: center !important; justify-content: center !important;
            cursor: pointer !important; z-index: 2147483647 !important; font-size: 24px !important;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2) !important;
        }
    `;
    GM_addStyle(css);

    // 2. HTML Cấu trúc (Chỉ có trạng thái và nút Bật/Tắt)
    const panel = document.createElement('div');
    panel.id = 'kanda-panel';
    panel.innerHTML = `
        <h3>Kanda Proxy</h3>
        <div class="ip-status">
            <span id="dot" style="color:#ccc">●</span> <span id="txt">Đang kiểm tra...</span><br>
            <small style="color:#999">IP Xoay Mỗi 1 Phút</small>
        </div>
        <button id="btn-action" class="kanda-btn">BẬT/TẮT PROXY</button>
    `;
    document.body.appendChild(panel);

    const toggle = document.createElement('div');
    toggle.id = 'kanda-toggle';
    toggle.innerHTML = '🛡️';
    document.body.appendChild(toggle);

    // 3. Logic ẩn/hiện
    toggle.onclick = () => {
        panel.style.display = (panel.style.display === 'none' || panel.style.display === '') ? 'block' : 'none';
        if(panel.style.display === 'block') checkStatus();
    };

    // 4. Kiểm tra xem có đang dùng Proxy không
    function checkStatus() {
        GM_xmlhttpRequest({
            method: "GET",
            url: "https://ipapi.co/json/",
            timeout: 3000,
            onload: (res) => {
                const d = JSON.parse(res.responseText);
                document.getElementById('dot').style.color = "#28a745";
                document.getElementById('txt').innerHTML = "Đang kết nối (" + d.country_code + ")";
            },
            onerror: () => {
                document.getElementById('dot').style.color = "#dc3545";
                document.getElementById('txt').innerHTML = "Chưa kết nối";
            },
            ontimeout: () => {
                document.getElementById('dot').style.color = "#dc3545";
                document.getElementById('txt').innerHTML = "Timeout (Chưa bật)";
            }
        });
    }

    // 5. Nút Bật/Tắt (Mở cài đặt hệ thống)
    document.getElementById('btn-action').onclick = function() {
        if (isMobile) {
            alert("Ní vào Cài đặt Wi-Fi trên Android, chọn Proxy thủ công rồi điền 127.0.0.1 cổng 8118 nhé!");
        } else {
            // Mở trang cài đặt hệ thống của Chrome
            window.open('chrome://settings/system', '_blank');
        }
    };

    // Alt + P để mở nhanh
    document.addEventListener('keydown', (e) => {
        if (e.altKey && e.key.toLowerCase() === 'p') toggle.click();
    });

})();
