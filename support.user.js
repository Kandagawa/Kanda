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

    // 1. CSS Giao diện (Tối ưu cho cả Mobile và PC)
    const css = `
        #kanda-panel {
            position: fixed; top: 15px; right: 15px; width: 280px;
            background: #fff; border: 2px solid #2ea44f; border-radius: 12px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.2); z-index: 1000000;
            font-family: -apple-system, sans-serif; padding: 15px; display: none;
        }
        #kanda-panel h3 { margin: 0 0 10px; font-size: 16px; color: #2ea44f; text-align: center; }
        .kanda-input {
            width: 100%; padding: 10px; margin-bottom: 10px;
            border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; font-size: 14px;
        }
        #kanda-search-btn {
            width: 100%; padding: 12px; background: #2ea44f; color: white;
            border: none; border-radius: 8px; cursor: pointer; font-weight: bold; font-size: 14px;
        }
        #kanda-toggle {
            position: fixed; bottom: 20px; right: 20px; width: 45px; height: 45px;
            background: #2ea44f; color: white; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; z-index: 1000000; box-shadow: 0 4px 12px rgba(0,0,0,0.3); font-size: 20px;
        }
        @media (max-width: 600px) { #kanda-panel { width: 90%; left: 5%; top: 10%; } }
    `;
    const s = document.createElement('style'); s.innerHTML = css; document.head.appendChild(s);

    // 2. Tạo UI
    const panel = document.createElement('div');
    panel.id = 'kanda-panel';
    panel.innerHTML = `
        <h3>Kanda Auto Finder</h3>
        <input type="text" id="kanda-link-input" class="kanda-input" placeholder="Link bị che (abc.com)">
        <input type="text" id="kanda-title-input" class="kanda-input" placeholder="Tiêu đề cần tìm y hệt">
        <button id="kanda-search-btn">TÌM VÀ ẤN NGAY</button>
    `;
    document.body.appendChild(panel);

    const toggle = document.createElement('div');
    toggle.id = 'kanda-toggle';
    toggle.innerHTML = '🎯';
    document.body.appendChild(toggle);

    // 3. Logic đóng mở
    toggle.onclick = () => panel.style.display = (panel.style.display === 'none' ? 'block' : 'none');

    // 4. Logic tìm và click
    document.getElementById('kanda-search-btn').onclick = function() {
        const urlPart = document.getElementById('kanda-link-input').value.trim().replace(/\*/g, '').toLowerCase();
        const textPart = document.getElementById('kanda-title-input').value.trim().toLowerCase();

        if (!urlPart && !textPart) return alert('Nhập thông tin đã bạn ơi!');

        // Lấy tất cả các thẻ có thể click (link, button)
        const items = Array.from(document.querySelectorAll('a, button, [role="button"]'));
        let found = false;

        for (let el of items) {
            const elText = el.innerText.toLowerCase();
            const elHref = (el.href || '').toLowerCase();

            const isTextMatch = textPart && elText.includes(textPart);
            const isUrlMatch = urlPart && elHref.includes(urlPart);

            // Kiểm tra: nếu nhập cả 2 thì phải khớp cả 2, nếu nhập 1 thì khớp 1
            if ((textPart && urlPart && isTextMatch && isUrlMatch) || (!urlPart && isTextMatch) || (!textPart && isUrlMatch)) {
                el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                el.style.outline = "5px solid red";
                el.style.backgroundColor = "yellow";
                
                setTimeout(() => {
                    el.click();
                    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
                }, 400);

                found = true;
                break;
            }
        }

        if (!found) {
            alert('Không tìm thấy link khớp trên trang này. Thử mở Google tìm nhé?');
            window.open(`https://www.google.com/search?q=${encodeURIComponent(textPart + " " + urlPart)}`, '_blank');
        }
    };

    document.addEventListener('keydown', (e) => { if (e.altKey && e.key.toLowerCase() === 's') toggle.click(); });

