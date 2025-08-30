// ==UserScript==
// @name         Remove Recaptcha (for test only)
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Hide recaptcha widget for testing
// @author       You
// @match        *://your-website.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Ẩn iframe và container reCAPTCHA
    const style = document.createElement('style');
    style.innerHTML = `
        .g-recaptcha,
        #recaptcha,
        iframe[src*="recaptcha"] {
            display: none !important;
            visibility: hidden !important;
        }
    `;
    document.head.appendChild(style);

    // Nếu form yêu cầu response, tự chèn "fake token"
    Object.defineProperty(window, "grecaptcha", {
        value: {
            getResponse: () => "FAKE_TEST_TOKEN",
            execute: () => Promise.resolve("FAKE_TEST_TOKEN")
        },
        configurable: true
    });
})();
