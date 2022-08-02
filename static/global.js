/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * global.js
 *
 * Very simple global helpers (i.e. system error alerts)
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

window.addEventListener('load', function(ev)
{
    var toasts = [].slice.call(document.querySelectorAll('.toast'));
    toasts.map(function(t) {
        return new bootstrap.Toast(t, {
            animation: true
        });
    }).forEach(element => {
        element.show();
    });
});