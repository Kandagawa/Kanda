// ==UserScript==
// @name         Kanda Support Script
// @namespace    https://github.com/Kandagawa/
// @version      1.0.1
// @description  Script hỗ trợ đa năng - Chạy trên mọi trang web
// @author       Kanda
// @match        *://*/*
// @icon         Https://lottiefiles.com/free-animation/sandy-loading-o4VygOMtb8
// @grant        none
// @downloadURL  https://raw.githubusercontent.com/Kandagawa/Kanda/main/support.user.js
// @updateURL    https://raw.githubusercontent.com/Kandagawa/Kanda/main/support.user.js
// @supportURL   https://github.com/Kandagawa/Kanda/issues
// ==/UserScript==

(function() {
    'use strict';

    // --- CẤU HÌNH THÔNG BÁO KHI SCRIPT CHẠY ---
    console.log("%c[Kanda Support]%c Script đã được tải thành công từ GitHub!", "color: #00ff00; font-weight: bold;", "color: default;");

    // --- NƠI BẠN THÊM CODE CỦA BẠN DƯỚI ĐÂY ---
    
    // Ví dụ: Nhấn Alt + S để kiểm tra script có đang hoạt động hay không
    document.addEventListener('keydown', function(e) {
        if (e.altKey && e.key.toLowerCase() === 's') {
            alert('Kanda Script đang hoạt động tại: ' + window.location.hostname);
        }
    });

    // Code của bạn bắt đầu từ đây:

})();
