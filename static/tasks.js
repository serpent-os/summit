/**
 * tasks.js
 *
 * Helpers for the task listing
 */

export const BuildStatus = Object.freeze({
    New: 0,
    Failed: 1,
    Building: 2,
    Publishing: 3,
    Completed: 4,
    Blocked: 5
});

function renderStatus(status)
{
    switch (status)
    {
        case BuildStatus.New: /* new */
            return `<span class="status status-sm status-yellow"><span class="status-dot"></span>Scheduled</span>`;
        case BuildStatus.Failed: /* failed */
            return `<span class="status status-red"><span class="status-dot status-dot-animated"></span>Failed</span>`;
        case BuildStatus.Building: /* building */
            return `<span class="status status-lime"><span class="status-dot status-dot-animated"></span>Building</span>`;
        case BuildStatus.Publishing: /* publishing */
            return `<span class="status status-teal"><span class="status-dot status-dot-animated"></span>Publishing</span>`
        case BuildStatus.Completed: /* completed */
            return `<span class="status status-purple"><span class="status-dot"></span>Completed</span>`;
        case BuildStatus.Blocked: /* blocked */
            return `<span class="status status-orange"><span class="status-dot"></span>Blocked</span>`
        default:
            return `<span class="status status-red"><span class="status-dot status-dot-animated"></span>ERROR IN JS</span>`;
    }
}

/**
 * Render a task as a list group item
 *
 * @param {JSON} task The task to be rendered
 * @returns
 */
export function renderTask(task)
{
    const hasEnded = task.tsEnded != 0;
    const start = new Date(task.tsStarted * 1000);
    const end = hasEnded ? new Date(task.tsEnded * 1000) : null;
    let duration = "--";

    if (hasEnded) {
        const difference = Math.abs(start.getTime() - end.getTime());
        const hours = Math.floor(difference / (1000 * 60 * 60));
        const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((difference % (1000 * 60)) / 1000);

        duration =
          (hours ? hours + "h " : "") +
          (minutes ? minutes + "m " : "") +
          seconds +
          "s";
    }

    const timestamp = hasEnded
      ? `Ended @ ${end.toLocaleString()} (${duration} on ${task.allocatedBuilder})`
      : `Started @ ${start.toLocaleString()} on ${task.allocatedBuilder}`;

    return `
<div class="list-group-item list-group-item-hoverable">
    <div class="row align-items-center">
        <div class="col-auto mx-2">
            <span class="avatar avatar-sm">#${task.id}</span>
        </div>
        <div class="col mx-2">
            <a class="d-block stretched-link" href="/tasks/${task.id}">${task.buildID}</a>
            <div class="d-block">${task.description}</div>
        </div>
        <div class="col-sm-12 col-lg-2 col-md-2">
            <small class="text-muted">${timestamp}</small>
        </div>
        <div class="col-auto">
            <span class="badge badge-outline text-secondary">${task.architecture}</span>
        </div>
        <div class="col-auto mx-2">${renderStatus(task.status)}</div>
        </div>
    </div>
</div>
`;
}
