// ==UserScript==
// @name         Kanda Support Script
// @namespace    https://github.com/Kandagawa/
// @version      1.0.9
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

    // 1. Giữ nguyên CSS của bạn (có thêm !important để chắc chắn hiển thị)
    const css = `
        #kanda-panel {
            position: fixed !important; top: 10px !important; right: 10px !important; width: 280px !important;
            background: #ffffff !important; border: 1px solid #ddd !important; border-radius: 12px !important;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2) !important; z-index: 2147483647 !important;
            font-family: sans-serif !important; padding: 15px !important; display: none;
        }
        #kanda-panel h3 { margin: 0 0 10px !important; font-size: 16px !important; color: #333 !important; text-align: center !important; }
        .kanda-input {
            width: 100% !important; padding: 8px !important; margin-bottom: 10px !important;
            border: 1px solid #ccc !important; border-radius: 6px !important; box-sizing: border-box !important; font-size: 14px !important;
        }
        #kanda-search-btn {
            width: 100% !important; padding: 10px !important; background: #2ea44f !important; color: white !important;
            border: none !important; border-radius: 6px !important; cursor: pointer !important; font-weight: bold !important;
        }
        #kanda-toggle {
            position: fixed !important; bottom: 20px !important; right: 20px !important; width: 45px !important; height: 45px !important;
            background: #24292e !important; color: white !important; border-radius: 50% !important;
            display: flex !important; align-items: center !important; justify-content: center !important;
            cursor: pointer !important; z-index: 2147483647 !important; box-shadow: 0 2px 10px rgba(0,0,0,0.3) !important; font-size: 20px !important;
        }
        @media (max-width: 600px) { #kanda-panel { width: 90% !important; left: 5% !important; right: 5% !important; top: 20% !important; } }
    `;
    const style = document.createElement('style'); style.innerHTML = css; document.head.appendChild(style);

    // 2. Cấu trúc HTML (Giữ nguyên giao diện của bạn)
    const panel = document.createElement('div');
    panel.id = 'kanda-panel';
    panel.innerHTML = `
        <h3>Kanda Finder</h3>
        <input type="text" id="kanda-link-input" class="kanda-input" placeholder="Link bị che (abc.com)">
        <input type="text" id="kanda-title-input" class="kanda-input" placeholder="Tiêu đề trang y hệt">
        <button id="kanda-search-btn">TÌM VÀ ẤN LINK</button>
    `;
    document.body.appendChild(panel);

    const toggle = document.createElement('div');
    toggle.id = 'kanda-toggle';
    toggle.innerHTML = '🔍'; // Kính lúp của bạn
    document.body.appendChild(toggle);

    // 3. Logic ẩn/hiện
    toggle.onclick = () => {
        panel.style.display = (panel.style.display === 'none' || panel.style.display === '') ? 'block' : 'none';
    };

    // 4. RUỘT XỬ LÝ MỚI: Tự tìm và Click
    document.getElementById('kanda-search-btn').onclick = function() {
        const linkKeyword = document.getElementById('kanda-link-input').value.trim().replace(/\*/g, '').toLowerCase();
        const titleText = document.getElementById('kanda-title-input').value.trim().toLowerCase();

        if (!linkKeyword && !titleText) {
            alert('Vui lòng nhập thông tin!');
            return;
        }

        // Tìm tất cả link và nút trên trang
        const elements = Array.from(document.querySelectorAll('a, button, [role="button"]'));
        let target = null;

        for (let el of elements) {
            const content = el.innerText.toLowerCase();
            const href = (el.href || '').toLowerCase();

            // Kiểm tra khớp chữ hoặc khớp link
            const matchText = titleText && content.includes(titleText);
            const matchLink = linkKeyword && href.includes(linkKeyword);

            if ((titleText && linkKeyword && matchText && matchLink) || (!linkKeyword && matchText) || (!titleText && matchLink)) {
                target = el;
                break;
            }
        }

        if (target) {
            // Cuộn tới và đánh dấu
            target.scrollIntoView({ behavior: 'smooth', block: 'center' });
            target.style.outline = "4px solid red";
            target.style.backgroundColor = "yellow";

            // Click ngay lập tức
            setTimeout(() => {
                target.click();
                // Dự phòng cho các nút bấm dạng code
                target.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
            }, 300);
        } else {
            alert('Không tìm thấy link nào khớp trên trang này!');
        }
    };

    // Phím tắt Alt + S
    document.addEventListener('keydown', (e) => {
        if (e.altKey && e.key.toLowerCase() === 's') toggle.click();
    });

