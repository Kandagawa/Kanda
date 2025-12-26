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

    // 1. ÉP CSS HIỂN THỊ (Dùng !important để không bị trang web đè)
    const css = `
        #kanda-panel {
            position: fixed !important; top: 20px !important; right: 20px !important; 
            width: 300px !important; background: white !important; 
            border: 2px solid #2ea44f !important; border-radius: 15px !important;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5) !important; z-index: 2147483647 !important;
            font-family: Arial, sans-serif !important; padding: 20px !important; 
            display: none; box-sizing: border-box !important;
        }
        #kanda-panel h3 { margin: 0 0 15px !important; font-size: 18px !important; color: #2ea44f !important; text-align: center !important; }
        .kanda-input {
            width: 100% !important; padding: 12px !important; margin-bottom: 12px !important;
            border: 1px solid #ddd !important; border-radius: 8px !important; 
            display: block !important; box-sizing: border-box !important; font-size: 14px !important; color: #333 !important;
        }
        #kanda-search-btn {
            width: 100% !important; padding: 12px !important; background: #2ea44f !important; 
            color: white !important; border: none !important; border-radius: 8px !important; 
            cursor: pointer !important; font-weight: bold !important; font-size: 14px !important;
        }
        #kanda-toggle {
            position: fixed !important; bottom: 30px !important; right: 30px !important; 
            width: 55px !important; height: 55px !important; background: #2ea44f !important; 
            color: white !important; border-radius: 50% !important;
            display: flex !important; align-items: center !important; justify-content: center !important;
            cursor: pointer !important; z-index: 2147483647 !important; 
            box-shadow: 0 4px 15px rgba(0,0,0,0.4) !important; font-size: 24px !important;
        }
        @media (max-width: 600px) { #kanda-panel { width: 90% !important; left: 5% !important; top: 50px !important; } }
    `;
    const s = document.createElement('style'); s.innerHTML = css; document.head.appendChild(s);

    // 2. TẠO UI (BẢNG VÀ KÍNH LÚP)
    const panel = document.createElement('div');
    panel.id = 'kanda-panel';
    panel.innerHTML = `
        <h3>Kanda Finder</h3>
        <input type="text" id="kanda-link-input" class="kanda-input" placeholder="Link bị che (ví dụ: abc.com)">
        <input type="text" id="kanda-title-input" class="kanda-input" placeholder="Tên link (ví dụ: Tải về)">
        <button id="kanda-search-btn">TÌM VÀ CLICK NGAY</button>
    `;
    document.body.appendChild(panel);

    const toggle = document.createElement('div');
    toggle.id = 'kanda-toggle';
    toggle.innerHTML = '🔍'; // Kính lúp ở đây
    document.body.appendChild(toggle);

    // 3. LOGIC ĐÓNG MỞ
    toggle.onclick = (e) => {
        e.preventDefault();
        panel.style.display = (panel.style.display === 'none' || panel.style.display === '') ? 'block' : 'none';
    };

    // 4. LOGIC TÌM KIẾM VÀ CLICK
    document.getElementById('kanda-search-btn').onclick = function() {
        const urlPart = document.getElementById('kanda-link-input').value.trim().replace(/\*/g, '').toLowerCase();
        const textPart = document.getElementById('kanda-title-input').value.trim().toLowerCase();

        if (!urlPart && !textPart) { alert('Nhập thông tin đã!'); return; }

        const items = Array.from(document.querySelectorAll('a, button, [role="button"]'));
        let found = false;

        for (let el of items) {
            const elText = el.innerText.toLowerCase();
            const elHref = (el.href || '').toLowerCase();

            const isTextMatch = textPart && elText.includes(textPart);
            const isUrlMatch = urlPart && elHref.includes(urlPart);

            if ((textPart && urlPart && isTextMatch && isUrlMatch) || (!urlPart && isTextMatch) || (!textPart && isUrlMatch)) {
                el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                el.style.setProperty('outline', '5px solid red', 'important');
                
                setTimeout(() => {
                    el.click();
                    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
                }, 400);

                found = true;
                break;
            }
        }

        if (!found) alert('Không tìm thấy link khớp trên trang này!');
    };

    // Alt + S để ẩn hiện nhanh
    document.addEventListener('keydown', (e) => { if (e.altKey && e.key.toLowerCase() === 's') toggle.click(); });
