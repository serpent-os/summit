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

const colors = [
    "bg-blue-lt",
    "bg-azure-lt",
    "bg-indigo-lt",
    "bg-purple-lt",
    "bg-red-lt",
    "bg-orange-lt",
    "bg-yellow-lt",
    "bg-lime-lt",
    "bg-green-lt",
    "bg-teal-lt",
    "bg-cyan-lt"
];

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
        Recipes: 'recipes',
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

        /**
         * List paginator
         */
        Paginator: 'summitPaginator',
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
        'recipes': '/api/v1/recipes',
    }
);

function constructURI(mode)
{
    let list = document.getElementById(SummitWidgets.ItemList);
    let summitContext = list.getAttribute('summit:context');
    let summitParent = list.getAttribute('summit:parent');
    if (summitParent === null)
    {
        return `${Endpoint[summitContext]}/${mode}`;
    }
    return `${Endpoint[summitContext]}/${mode}/${summitParent}`;
}

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

    refreshList(summitContext, summitMode, 0);
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
    const uri = constructURI('create');
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
function refreshList(context, mode, pageNumber=0)
{
    console.log(context, mode, pageNumber);
    let uri = constructURI('enumerate');
    if (pageNumber != 0)
    {
        uri += `?pageNumber=${pageNumber}`;
    }
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
function renderElement(context, element, idx)
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
            const color = isNaN(element.id) ?  colors[idx % colors.length] : colors[parseInt(element.id) % colors.length];
            return `
<div class="list-group-item list-group-hoverable">
    <div class="row align-items-center">
        <div class="col-auto">
            <span class="avatar ${color}">${element.title[0]}</span>
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
    let idx = 0;
    if (obj['items'] !== undefined)
    {
        /* Paginated */
        obj.items.forEach(element => {
            completeHTML += renderElement(context, element, idx);
            idx+=1;
        });
        document.getElementById(SummitWidgets.Paginator).innerHTML = renderPaginator(context, obj);
    } else {
        /* Non paginated */
        obj.forEach(element => {
            completeHTML += renderElement(context, element, idx);
            idx+=1;
        })
    }

    // Update the DOM
    document.getElementById(SummitWidgets.ItemList).innerHTML = completeHTML;
}

/**
 * Render the paginator object
 * 
 * @param {String} context Current rendering context
 * @param {JSON} obj The returned JSON object, must be Paginator!ListItem
 */
function renderPaginator(context, obj)
{
    console.log(obj);
    var pageHTML = Array(obj.numPages).fill(0).map(
        (_, i) => {
            let pageClass = "page-item";
            let aria = '';
            if (i == obj.page)
            {
                pageClass += " active";
            }
            return `<li class="${pageClass}">
                <a class="page-link" ${aria} href="#${SummitWidgets.Paginator}" onclick="javascript:refreshList('${context}', 'enumerate', ${i});">${i+1}</a>
            </li>`;
        });
    const nextClass = obj.hasNext ? "" : "disabled";
    const nextAria = obj.hasNext ? "" : "aria-disabled='true'";
    const prevClass = obj.hasPrevious ? "" : "disabled";
    const prevAria = obj.hasPrevious ? "" : "aria-disabled='true'";
    return `
<ul class="pagination justify-content-center border-top pt-3">
    <li class="page-item ${prevClass}">
        <a class="page-link" ${prevAria} href="#${SummitWidgets.Paginator}" onclick="javascript:refreshList('${context}', 'enumerate', ${obj.page-1});">
            <svg class="icon">
                <use xlink:href="/static/tabler/tabler-sprite.svg#tabler-chevron-left" />
            </svg>
        Previous
        </a>
    </li>
    ${pageHTML.join("")}
    <li class="page-item ${nextClass}">
        <a class="page-link" ${nextAria} href="#${SummitWidgets.Paginator}" onclick="javascript:refreshList('${context}', 'enumerate', ${obj.page+1});">
            <svg class="icon">
                <use xlink:href="/static/tabler/tabler-sprite.svg#tabler-chevron-right" />
            </svg>
        Next
        </a>
    </li>
</ul>`;
}