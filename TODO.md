## TODO

We've reached an unavoidable point in Serpent OS development whereby we really need the live infrastructure. This document will be used for loose
organisation and planning beween development sessons.

### Distil build process

 - Create a Task for all missing builds, do not **start** them. Mark `Unchecked`
   - Plan build per task, mark as DepResolved (`Ready`) or DepIncomplete (`Pending`)
   - For unresolveable builds (unpromised), mark DepFailed (`Failed`)
 - Each time inputs change, re-evaluate all DepIncomplete
 - Construct a Build Queue from all `Ready` (DepSolved) builds, topologically sort it.
 - Build worker, when builders become available via reports, walk the queue from HEAD to pull `Ready` to `Started`. Fire job via appropriate Avalanche instance.

Build execution is controlled in a single-threaded manner and handed out to available workers. Thus, certain events will cause job delivery to be revaluated:

 - Build server becomes available
 - Inputs changed
 - Job cancelled

If an input has **changed** and has a live job (i.e. bumped to fix an issue), any existing jobs must be cancelled. To avoid race conditions in cancellation, we simply do not forward the completion status to Vessel to prevent invalid builds from being included in `volatile`.

The core functionality of handing out builds is basically:

```d
    if (haveJobs && buildersAvailable)
```