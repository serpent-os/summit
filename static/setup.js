/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * setup.js
 *
 * Helpers for setup mode
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

window.addEventListener('load', function(ev)
{
    const form = document.getElementById('setupForm');
    const submit = document.getElementById('submitButton');
    submit.addEventListener('click', function(ev) {
        ev.preventDefault();
        form.submit();
    });
});