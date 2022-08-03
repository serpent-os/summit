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
    const button = document.getElementById('addBuilderButton');
    button.addEventListener('click', doAddBuilder);
 });

 function renderBuilder(element)
 {
    return `
<div class="list-group-item">
    <div class="row align-items-center">
        <div class="col-auto">
            <span class="status-indicator status-yellow status-indicator-animated">
                <span class="status-indicator-circle"></span>
                <span class="status-indicator-circle"></span>
                <span class="status-indicator-circle"></span>
            </span>
        </div>
        <div class="col-auto">
            <span class="avatar">${element.displayName[0]}</span>
        </div>
        <div class="col">
            <a href="#" class="text-reset d-block">${element.displayName}</a>
            <div class="text-muted">${element.uri}</div>
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
        console.log(object);
    }).catch((error) => console.log(error));
 }

function doAddBuilder(ev)
{
    const form = document.getElementById('addBuilderForm');
    ev.preventDefault();
    const submission = {
        'nick': document.querySelector('input[name="nick"').value,
        'hostname': document.querySelector('input[name="hostname"]').value
    };
    fetch('/api/v1/builders/add', {
        'credentials': 'include',
        'body': JSON.stringify(submission),
        'method': 'POST',
        'headers': {
            'Accepts': 'application/json',
            'Content-Type': 'application/json',
        }
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("Failed to add builder: " + response.statusText);
        }
        refreshBuildersView(document.getElementById('buildersList'));
        const md = bootstrap.Modal.getInstance(document.getElementById('addBuilderDialog'));
        md.hide();
    }).catch((error) => console.log(error));
}