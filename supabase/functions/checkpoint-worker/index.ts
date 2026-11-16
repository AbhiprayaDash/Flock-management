// Shed checkpoints have been removed. Never send queued notifications.
Deno.serve(()=>new Response('Shed checkpoints have been removed.',{status:410}));
