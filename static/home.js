/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * home.js - helpers for the landing page
 */

let timelineWidget;

import { BuildStatus } from "./tasks.js";

window.addEventListener('load', function(ev)
{
    timelineWidget = document.getElementById('summit-events');
    refreshTimeline();
});

/**
 * Render failure
 */
function renderOops()
{
    timelineWidget.innerHTML = 'oops'
}

function renderIcon(element)
{
    switch (element.status)
    {
        case BuildStatus.Failed:
            return `
<div class="timeline-event-icon bg-red-lt">
    <svg class="icon" width="24" height="24">
        <use xlink:href="/static/tabler/tabler-sprite.svg#tabler-x" />
    </svg>
</div>`;
        case BuildStatus.Completed:
            return `
<div class="timeline-event-icon bg-purple-lt">
    <svg class="icon" width="24" height="24">
        <use xlink:href="/static/tabler/tabler-sprite.svg#tabler-check" />
    </svg>
</div>`;
        default:
            return `
            <div class="timeline-event-icon">
            <svg class="icon" width="24" height="24">
                <use xlink:href="/static/tabler/tabler-sprite.svg#tabler-reload" />
            </svg>
        </div>`;
    }
}
function renderElement(element)
{
    const started = new Date(element.tsStarted * 1000).toLocaleString();

    const buildString = element.allocatedBuilder === "" ? 
        `Build #${element.id} ${element.sourcePath}` :
        `Building #${element.id} ${element.sourcePath} on ${element.allocatedBuilder}`;
    return `
<li class="timeline-event">
    ${renderIcon(element)}
    <div class="card timeline-event-card">
        <div class="card-body">
            <div class="text-muted float-end">${started}</div>
            <h4>${buildString}</h4>
            <p class="text-muted">${element.description}</p>
        </div>
    </div>
</li>
`
}

async function refreshTimeline()
{
    const response = await fetch('/api/v1/tasks/enumerate');
    if (!response.ok)
    {
        renderOops();
        return;
    }
    const json = await response.json();
    const nItems = json.items.length > 10 ? 10 : json.items.length;
    const items = json.items.slice(0, nItems);
    console.log(items);

    let html = items.map((elem) => renderElement(elem)).join("");
    timelineWidget.innerHTML = `
<ul class="timeline">
    ${html}
</ul>`
}
