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
        case 'repos':
            refreshReposView(list, list.getAttribute('summit:namespaceName'), list.getAttribute('summit:projectName'));
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
                                    <a href="/~/${namespace.ns.slug}/${p.slug}">${namespace.ns.name} / ${p.name} </a>
                                </div>
                                <div class="col">
                                    ${p.summary}
                                </div>
                            </div>
                        </div>`;
            }).join("");
            newHTML += `
                <div class="col-md-6">
                    <div class="card shadow-sm">
                        <div class="card-body">
                            <h3 class="card-title"><a href="/~/${namespace.ns.slug}">${namespace.ns.name}</a></h3>
                            <div class="markdown text-wrap">${namespace.ns.summary}</div>
                        </div>
                        <div class="list-group list-group-flush justify-text-center">
                            <div class="list-group-header">Projects</div>
                            ${p}
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-teal-lt">
                        <div class="card-body">
                            <h3 class="card-title">Coming soon(ish) &trade;</h3>
                            <div class="markdown text-wrap">We plan to allow users to create their own namespaces!</div>
                        </div>
                    </div>
                </div>`;
        });
        list.innerHTML = newHTML;
    }).catch((error) => console.log(error));
}

function refreshReposView(list, namespaceID, projectID)
{
    fetch(`/api/v1/repositories/${namespaceID}/${projectID}/list`,
    {
        credentials: 'include',
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("Failed to fetch repository listing");
        }
        return response.json();
    }).then((object) => {
        /* Render a placeholder. */
        if (object.length < 1)
        {
            list.innerHTML = `
<div class="empty">
    <div class="empty-icon">
        <svg><use xlink:href="/static/tabler/tabler-sprite.svg#tabler-mood-crazy-happy" /></svg>
    </div>
    <div class="empty-title">Oh this is *so* new.</div>
    <div class="empty-subtitle text-muted">Time to add your first repository!</div>
</div>`;
            return;
        }

        /* TODO: Render each item.. */
        list.innerHTML = '';
    }).catch((error) => console.log(error));
}