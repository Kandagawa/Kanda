// ==UserScript==
// @name         Kanda Support Script
// @namespace    https://github.com/Kandagawa/
// @version      1.0.6
// @description  Bảng điều khiển tìm kiếm link đa năng cho Mobile & PC
// @author       Kanda
// @match        *://*/*
// @icon         https://github.githubassets.com/favicons/favicon.svg
// @grant        GM_addStyle
// @grant        GM_openInTab
// @downloadURL  https://raw.githubusercontent.com/Kandagawa/Kanda/main/support.user.js
// @updateURL    https://raw.githubusercontent.com/Kandagawa/Kanda/main/support.user.js
// ==/UserScript==

(function() {
    'use strict';

    // 1. CSS để tạo giao diện (UI) đẹp và phản hồi tốt trên Mobile/PC
    const css = `
        #kanda-panel {
            position: fixed; top: 10px; right: 10px; width: 280px;
            background: #ffffff; border: 1px solid #ddd; border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2); z-index: 999999;
            font-family: sans-serif; padding: 15px; display: none;
        }
        #kanda-panel h3 { margin: 0 0 10px; font-size: 16px; color: #333; text-align: center; }
        .kanda-input {
            width: 100%; padding: 8px; margin-bottom: 10px;
            border: 1px solid #ccc; border-radius: 6px; box-sizing: border-box; font-size: 14px;
        }
        #kanda-search-btn {
            width: 100%; padding: 10px; background: #2ea44f; color: white;
            border: none; border-radius: 6px; cursor: pointer; font-weight: bold;
        }
        #kanda-search-btn:hover { background: #2c974b; }
        #kanda-toggle {
            position: fixed; bottom: 20px; right: 20px; width: 40px; height: 40px;
            background: #24292e; color: white; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; z-index: 999999; box-shadow: 0 2px 10px rgba(0,0,0,0.3);
        }
        @media (max-width: 600px) { #kanda-panel { width: 90%; left: 5%; right: 5%; top: 20%; } }
    `;
    if (typeof GM_addStyle !== 'undefined') { GM_addStyle(css); } else {
        let style = document.createElement('style'); style.innerHTML = css; document.head.appendChild(style);
    }

    // 2. Tạo cấu trúc HTML cho bảng
    const panel = document.createElement('div');
    panel.id = 'kanda-panel';
    panel.innerHTML = `
        <h3>Kanda Finder</h3>
        <input type="text" id="kanda-link-input" class="kanda-input" placeholder="Nhập link bị che (***abc.com)">
        <input type="text" id="kanda-title-input" class="kanda-input" placeholder="Nhập tiêu đề trang">
        <button id="kanda-search-btn">TÌM KIẾM LINK</button>
    `;
    document.body.appendChild(panel);

    // 3. Nút tròn nhỏ để ẩn/hiện bảng (Dễ dùng trên cảm ứng điện thoại)
    const toggle = document.createElement('div');
    toggle.id = 'kanda-toggle';
    toggle.innerHTML = '🔍';
    document.body.appendChild(toggle);

    // 4. Logic xử lý
    toggle.onclick = () => {
        panel.style.display = (panel.style.display === 'none' || panel.style.display === '') ? 'block' : 'none';
    };

    document.getElementById('kanda-search-btn').onclick = function() {
        const linkPattern = document.getElementById('kanda-link-input').value.trim();
        const title = document.getElementById('kanda-title-input').value.trim();

        if (!linkPattern && !title) {
            alert('Vui lòng nhập thông tin để tìm kiếm!');
            return;
        }

        // Xử lý linkPattern: Loại bỏ các dấu sao (*) để lấy từ khóa sạch
        const cleanLink = linkPattern.replace(/\*/g, '');
        
        // Tạo câu lệnh tìm kiếm trên Google để tìm link khớp nhất
        const searchQuery = encodeURIComponent(`${title} "${cleanLink}"`);
        const searchURL = `https://www.google.com/search?q=${searchQuery}`;

        console.log('Đang tìm kiếm:', searchURL);
        
        // Mở tab mới
        if (typeof GM_openInTab !== 'undefined') {
            GM_openInTab(searchURL, { active: true });
        } else {
            window.open(searchURL, '_blank');
        }
    };

    // Alt + S để ẩn/hiện nhanh trên PC
    document.addEventListener('keydown', (e) => {
        if (e.altKey && e.key.toLowerCase() === 's') toggle.click();
    });

})();

