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

window.addEventListener('load', function(ev)
{
    const list = document.getElementById('namespacesList');

    refreshView(list);
});

function refreshView(list)
{
    fetch('/api/v1/namespaces/list', {
        'credentials': 'include'
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("Couldn't fetch namespaces");
        }
        return response.json();
    }).then((object) =>
    {
        let newHTML = '';
        object.forEach((namespace) => {
            const p = namespace.projects.map(p => {
                return `<div class="list-group-item">
                            <div class="row">
                                <div class="col">
                                    <a href="/~/${namespace.ns.name}/${p.name}">${namespace.ns.name} / ${p.name} </a>
                                </div>
                                <div class="col">
                                    ${p.summary}
                                </div>
                            </div>
                        </div>`;
            }).join("");
            newHTML += `
                <div class="col-6">
                    <div class="card shadow-sm">
                        <div class="card-header">
                            <h3 class="card-title"><a href="/~/${namespace.ns.name}">${namespace.ns.name}</a> - <span class="text-muted">${namespace.ns.summary}</span></h3>
                        </div>
                        <div class="card-body">
                            <div class="markdown text-center">${namespace.ns.description}</div>
                        </div>
                        <div class="list-group list-group-flush justify-text-center">
                            <div class="list-group-header">Projects</div>
                            ${p}
                        </div>
                    </div>
                </div>`;
        });
        list.innerHTML = newHTML;
    }).catch((error) => console.log(error));
}