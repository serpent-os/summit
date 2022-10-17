/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * summit.js
 *
 * List/interaction code
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

/**
 * Current context
 */
 const SummitContext = Object.freeze(
    {
        Collections: 'collections',
        Repositories: 'repositories',
        Groups: 'groups',
        Users: 'users',
    }
);

/**
 * Map context to endpoint
 */
const Endpoint = Object.freeze(
    {
        'collections': '/api/v1/collections',
        'repositories': '/api/v1/repos',
        'groups': '/api/v1/groups',
        'users': '/api/v1/users',
    }
);

window.addEventListener('load', function(ev)
{
    integrateList();
    ev.preventDefault();
});

/**
 * Integrate the context list
 */
function integrateList()
{
    let list = document.getElementById('summitList')
    if (list === null)
    {
        return;
    }
    const summitContext = list.getAttribute('summit:context');
    const summitMode = list.getAttribute('summit:mode');

    refreshList(summitContext, summitMode);
}

function refreshList(context, mode)
{
    console.log(`Not yet implemented: '${mode}' of '${context}'`)
    console.log(`Endpoint: ${Endpoint[context]}`)
}