/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * jobs.js
 *
 * Implements BuildJobs client API
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

/**
 * Matches the D APi
 */
const JobStatus = Object.freeze({
    0: 'Pending',
    1: 'Accepted',
    2: 'Building',
    3: 'Syncing',
    4: 'Finished',
    5: 'Failed'
});

const StatusMap = Object.freeze({
    'Pending': `<div class="badge bg-info-lt">Pending</div>`,
    'Accepted': `<div class="badge">Accepted</div>`,
    'Building': `<div class="badge">Building</div>`,
    'Syncing': `<div class="badge">Syncing</div>`,
    'Finished': `<div class="badge bg-success-lt">Finished</div>`,
    'Failed': `<div class="badge bg-red-lt">Failed</div>`,
});

/**
 * Insert a placeholder on ready
 */
window.addEventListener('DOMContentLoaded', function(ev)
{
    const jobList = this.document.getElementById('listGroupBuilds');
    jobList.innerHTML = renderPlaceholder();
});

let timerInterval;

/**
 * Refresh job lists periodically
 */
window.addEventListener('load', function(ev)
{
    const jobList = this.document.getElementById('listGroupBuilds');
    const pkgList = this.document.getElementById('listGroupPackages');
    timerInterval = setInterval(ev => refreshJobs(jobList), 500);
    refreshJobs(jobList);
    refreshPackages(pkgList);
});

/**
 * Render an individual job
 */
function renderJob(job)
{
    const statusType = parseInt(job.status);
    const key = JobStatus[statusType];
    const status = StatusMap[key];
    return `
<div class="list-group-item">
    <div class="row align-items-center">
        <div class="col-auto">
            <code><a href="#">#${job.id}</a></code>
        </div>
        <div class="col-auto">
            <span class="avatar rounded-circle">S</span>
        </div>
        <div class="col">
            <div class="d-flex row">
                <div>
                    Some user pushed some build
                </div>
                <div class="text-muted">${job.resource} - ${job.reference}</div>
            </div>
        </div>
        <div class="col-auto">
            ${status}
        </div>
    </div>
</div>
    `;
}

/**
 * Render the joblist placeholder
 */
function renderPlaceholder()
{
    return `
<div class="empty">
    <div class="empty-img text-muted">
        <svg class="logo"><use xlink:href="/static/tabler/tabler-sprite.svg#tabler-mood-confuzed" /></svg>
    </div>
    <div class="empty-title">Huh, look at that.</div>
    <div class="empty-subtitle text-muted">I'd say we've been busy.. clearly we haven't.</a>
</div>
`
}

/**
 * Update the job list from the server
 */
function refreshJobs(jobList)
{
    fetch('/api/v1/buildjobs/list_active', {
        'credentials': 'include',
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error('Unable to load jobs');
        }
        return response.json();
    }).then((object) => {
        let newHTML = '';
        if (object.length < 1)
        {
            jobList.innerHTML = renderPlaceholder();
            return;
        }
        object.forEach((job) => {
            newHTML += renderJob(job);
            console.log(job);
        });
        jobList.innerHTML = newHTML;
    }).catch((error) => {
        console.log(error);
        clearInterval(timerInterval);
    });
}

/**
 * Refresh the new-packages list
 */
function refreshPackages(pkgList)
{
    pkgList.innerHTML = `
<div class="empty">
    <div class="empty-subtitle text-muted">Erm, no packages to speak of..</div>
</div>
`;
}