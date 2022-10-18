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

 window.addEventListener('load', function(ev)
 {
     integrateList();
     ev.preventDefault();
 });

 
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
 * Enum of our widgets
 */
const SummitWidgets = Object.freeze(
    {
        /**
         * Creation form dialog
         */
        CreationDialog: 'creationDialog',

        /**
         * Submit button on the dialog
         */
        CreationDialogSubmit: 'creationButton',

        /**
         * Form for creation events
         */
        CreationDialogForm: 'creationForm',

        /**
         * Renderable items
         */
        ItemList: 'summitList',
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

/**
 * Integrate the context list
 */
function integrateList()
{
    let list = document.getElementById(SummitWidgets.ItemList)
    if (list === null)
    {
        return;
    }
    const summitContext = list.getAttribute('summit:context');
    const summitMode = list.getAttribute('summit:mode');

    refreshList(summitContext, summitMode);
}

/**
 * Render the default placeholder
 */
function renderPlaceholder()
{
    const html = `
<div class="empty">
    <div class="empty-icon">
        <svg class="logo text-muted">
            <use xlink:href="/static/tabler/tabler-sprite.svg#tabler-mood-suprised" />
        </svg>
    </div>
    <p class="empty-title">This page has intentionally been left blank</p>
    <p class="empty-subtitle text-muted">
        How does that work, though? Like, clearly it isn't blank.
    </p>
</div>`;
    document.getElementById(SummitWidgets.ItemList).innerHTML = html;
}

/**
 * Lets get the list updated
 */
function refreshList(context, mode)
{
    const uri = `${Endpoint[context]}/${mode}`;
    fetch(uri, {
        credentials: 'include',
        method: 'GET',
        headers: {
            Accept: 'application/json'
        }
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("refreshList failed: " + response.statusText);
        }
        return response.json();
    }).then((obj) => {
        renderList(context, mode, obj);
    }).catch((error) => console.log(error));
}

/**
 * Render the list when successful
 * @param {string} context Summit Context (i.e. collections)
 * @param {string} mode Summit mode (i.e. enumerate)
 * @param {JSON} obj Summit object response (ListItem)
 */
function renderList(context, mode, obj)
{
    // No items, set up the placeholder
    if (obj.length == 0)
    {
        renderPlaceholder();
        return;
    }
    console.log(`${context} : ${obj}`)
}