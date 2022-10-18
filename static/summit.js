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

let formSubmitting = false;

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

    integrateDialog(summitContext);

    refreshList(summitContext, summitMode);
}

/**
 * Integration the manipulation dialog
 */
function integrateDialog(context)
{
    let dialog = document.getElementById(SummitWidgets.CreationDialog);
    if (dialog === null)
    {
        return;
    }
    // When showing modal - reset it first
    dialog.addEventListener('show.bs.modal', function(ev)
    {
        resetDialog();
    });

    /* Prevent hide if busy. */
    dialog.addEventListener('hide.bs.modal', function(ev)
    {
        if (formSubmitting)
        {
            ev.preventDefault();
        }
    })

    // Hook up submission
    let submission = dialog.getElementsByClassName('summit-submit')[0];
    submission.addEventListener('click', function(ev)
    {
        ev.preventDefault();
        submitDialog(context, dialog);
    });
}

/**
 * Reset an async dialog
 */
function resetDialog()
{
    let dialog = document.getElementById(SummitWidgets.CreationDialog);
    if (dialog === null)
    {
        return;
    }
    let spinner = dialog.getElementsByClassName('summit-spinner')[0];
    let submission = dialog.getElementsByClassName('summit-submit')[0];
    let form = dialog.getElementsByClassName('summit-form')[0];
    form.reset();

    // Ensure spinner is invisible
    spinner.classList.add('d-none');

    // Fix sensitivity
    submission.disabled = false;
}

/**
 * Submit a dialog
 * 
 * @param {String} context Context used for submission
 * @param {Element} dialog The visible dialog element
 */
function submitDialog(context, dialog)
{
    formSubmitting = true;

    let spinner = dialog.getElementsByClassName('summit-spinner')[0];
    let submission = dialog.getElementsByClassName('summit-submit')[0];
    let form = dialog.getElementsByClassName('summit-form')[0];

    const fe = new FormData(form);
    const submissionBody = JSON.stringify({
        'request': Object.fromEntries(fe)
    });
    const uri = `${Endpoint[context]}/create`;
    console.log(uri);

    // Show spinner
    spinner.classList.remove('d-none');
    submission.disabled = true;

    fetch(uri, {
        body: submissionBody,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error("submitDialog: " + response.statusText);
        }
        console.log("Success");
        refreshList(context, 'enumerate');
    }).catch((error) => console.log(error))
    .finally(() => {
        formSubmitting = false;
        var modal = bootstrap.Modal.getInstance(dialog);
        modal.hide();
    });
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
 * Render an individual element
 * @param {String} context Rendering context (Collections, etc.)
 * @param {String} element The element to render
 * @returns new innerHTML for the summit list
 */
function renderElement(context, element)
{
    switch (context)
    {
        // Specialist Collection rendering
        case SummitContext.Collections:
            return `
<div class="mb-3 col-6 col-md-6 col-lg-6">
    <div class="card">
        <div class="card-header">
            <h5 class="card-title"><a href="${element.slug}" class="text-reset">${element.title}</a></h5>
        </div>
        <div class="card-body">
            <p>${element.subtitle}</p>
        </div>
    </div>
</div>`;

        // Default rendering
        default:
            return `
<div class="list-group-item list-group-hoverable">
    <div class="row align-items-center">
        <div class="col-auto">
            <span class="avatar">${element.id}</span>
        </div>
        <div class="col text-truncate">
            <a href="${element.slug}" class="text-reset d-block">${element.title}</a>
            <div class="d-block text-muted">${element.subtitle}</div>
        </div>
    </div>
</div>`;
    }
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
    let completeHTML = '';
    obj.forEach(element => {
        completeHTML += renderElement(context, element);
    });
    // Update the DOM
    document.getElementById(SummitWidgets.ItemList).innerHTML = completeHTML;
}