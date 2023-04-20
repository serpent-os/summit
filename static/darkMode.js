/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * darkMode.js
 *
 * Enable dark mode in Serpent OS websites
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

/**
 * Enum for our theme variants
 */
const ThemeVariant = Object.freeze({
    System: 'system',
    Dark: 'dark',
    Light: 'light',
});

/**
 * Returns the current theme preference
 */
function currentThemePref()
{
    let prefs = window.sessionStorage.getItem('theme-pref');
    if (prefs === null)
    {
        return ThemeVariant.System;
    }
    return prefs;
}

/**
 * Compute the next theme preference in the cycle
 *
 * @param {string} currentThemePref Current theme preference
 * @returns The next theme preference
 */
function nextThemePref(currentThemePref)
{
    switch (currentThemePref)
    {
        case ThemeVariant.System:
            return ThemeVariant.Dark;
        case ThemeVariant.Dark:
            return ThemeVariant.Light;
        case ThemeVariant.Light:
        default:
            return ThemeVariant.Dark;
    }
}

/**
 * Updates the body element with the applicable theme class
 * 
 * @param {string} themePref New theme preference
 */
function updateBody(themePref)
{
    switch (themePref)
    {
        case 'system':
            this.document.body.classList.remove('theme-dark');
            this.document.body.classList.remove('theme-light');
            this.document.body.classList.add('theme-dark-auto');
            break;
        case 'light':
            this.document.body.classList.remove('theme-dark');
            this.document.body.classList.remove('theme-dark-auto');
            this.document.body.classList.add('theme-light');
            break;
        case 'dark':
            this.document.body.classList.remove('theme-dark-auto');
            this.document.body.classList.remove('theme-light');
            this.document.body.classList.add('theme-dark');
            break;
        default:
            break;
    }
}

/**
 * Activate the theme preference
 * 
 * @param {string} themePref New theme preference
 */
function activateTheme(themePref)
{
    updateBody(themePref);

    const svg = document.getElementById('themeSwitcherIcon');
    if (svg === null)
    {
        return;
    }
    const useIcon = svg.getElementsByTagName('use').item(0);
    switch (themePref)
    {
        case 'system':
            useIcon.setAttribute('xlink:href', '/static/tabler/tabler-sprite.svg#tabler-moon');
            break;
        case 'light':
            useIcon.setAttribute('xlink:href', '/static/tabler/tabler-sprite.svg#tabler-moon');
            break;
        case 'dark':
            useIcon.setAttribute('xlink:href', '/static/tabler/tabler-sprite.svg#tabler-sun');
            break;
        default:
            break;
    }
}

/**
 * On load we'll activate the theme and hook up 
 * the #themeSwitcher button for swaps
 */
window.addEventListener('DOMContentLoaded', function(ev) {
    const themePref = currentThemePref();
    activateTheme(themePref);

    const switcher = document.getElementById('themeSwitcher');
    if (switcher === null)
    {
        return;
    }
    switcher.addEventListener('click', function(ev) {
        const themePref = currentThemePref();
        const newPref = nextThemePref(themePref);
        window.sessionStorage.setItem('theme-pref', newPref);
        activateTheme(newPref);
    })
});

/**
 * Forcibly apply the theme in non-async fashion
 */
const themePref = currentThemePref();
activateTheme(themePref);
