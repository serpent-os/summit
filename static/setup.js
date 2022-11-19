window.addEventListener('load', function(ev)
{
    const form = document.getElementById('setupForm');
    const submit = document.getElementById('submitButton');
    submit.addEventListener('click', function(ev) {
        ev.preventDefault();
        form.submit();
    });
});