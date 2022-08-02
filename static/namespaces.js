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
    /**
     * Try to find the namespaces list
     */
    const list = document.getElementById('namespacesList');
    const purpose = list.getAttribute('summit:namespaceList');

    switch (purpose)
    {
        case 'all':
            refreshNamespacesView(list);
            break;
        case 'individual':
            refreshProjectsView(list, list.getAttribute('summit:namespaceName'));
            break;
        default:
            break;
    }
});

const colors = [
    "bg-azure-lt",
    "bg-purple-lt",
    "bg-red-lt",
    "bg-teal-lt",
    "bg-pink-lt",
    "bg-lime-lt",
];

function renderProject(element, projectID)
{
    const col = colors[Math.floor(Math.random() * colors.length)];
    return `<div class="list-group-item">
        <div class="row align-items-center">
            <div class="col-auto">
                <span class="avatar ${col}">${element.name[0]}</span>
            </div>
            <div class="col">
                <a href="/~/${projectID}/${element.slug}" class="text-reset d-block">${element.name}</a>
                <div class="d-block text-muted">${element.summary}</div>
            </div>
        </div>
</div>
    `;
}

function refreshProjectsView(list, projectID)
{
    fetch('/api/v1/namespaces/' + projectID + '/projects', {
        'credentials': 'include'
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("Couldn't fetch projects");
        }
        return response.json();
    }).then((object) => {
        let newHTML = '';
        object.forEach((element) =>
        {
            newHTML += renderProject(element, projectID);
        });
        list.innerHTML = newHTML;
    }).catch((error) => console.log(error));
}

function refreshNamespacesView(list)
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
                                    <a href="/~/${namespace.ns.slug}/${p.name}">${namespace.ns.name} / ${p.name} </a>
                                </div>
                                <div class="col">
                                    ${p.summary}
                                </div>
                            </div>
                        </div>`;
            }).join("");
            newHTML += `
                <div class="col-10 col-md-6">
                    <div class="card shadow-sm">
                        <div class="card-header">
                            <h3 class="card-title"><a href="/~/${namespace.ns.slug}">${namespace.ns.name}</a></h3>
                        </div>
                        <div class="card-body">
                            <div class="markdown text-wrap">${namespace.ns.description}</div>
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