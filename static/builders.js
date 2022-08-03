/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * namespaces.js
 *
 * Implements namespace client API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

 window.addEventListener('load', function(ev) {
    const builderList = this.document.getElementById('buildersList');
    refreshBuildersView(builderList);
 });

 function renderBuilder(element)
 {
    return `
<div class="list-group-item">
    <div class="row align-items-center">
        <div class="col">
            <a href="#" class="text-reset d-block">${element.nick}</a>
        </div>
    </div>
</div>
`;
 }

function renderPlaceholder(list)
{
    return `
<div class="empty">
    <div class="empty-icon">
    <svg><use xlink:href="/static/tabler/tabler-sprite.svg#tabler-mood-confuzed" /></svg>
    </div>
    <div class="empty-title">Look at all those <strike>chickens</strike> builders</div>
    <div class="empty-subtitle text-muted">Hey, where'd they go?</div>
</div>`;
}

 function refreshBuildersView(list)
 {
    fetch('/api/v1/builders/list', {
        'credentials': 'include',
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("Failed to refresh builders");
        }
        return response.json();
    }).then((object) => {
        let newHTML = '';
        if (object.length == 0)
        {
            list.innerHTML = renderPlaceholder(list);
            return;
        }
        object.forEach((element) => {
            newHTML += renderBuilder(element);
        });
        list.innerHTML = newHTML;
        console.log(newHTML);
    }).catch((error) => console.log(error));
 }