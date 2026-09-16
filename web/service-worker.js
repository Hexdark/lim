// Cache only the static shell. NEVER cache Supabase responses or photos.
// A network-first shell lets new releases replace old assets without sticky caches.
const CACHE = 'blisko-shell-v1';
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll([
    './', './index.html', './manifest.json', './icons/Icon-192.png'
  ])));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(
    keys.filter(k => k.startsWith('blisko-shell-') && k !== CACHE).map(k => caches.delete(k))
  )));
});
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) return;
  const isShell = event.request.mode === 'navigate' ||
    /\.(?:js|wasm|json|png|woff2|ttf)$/.test(url.pathname);
  if (!isShell) return;
  event.respondWith(fetch(event.request).then(response => {
    if (response.ok) {
      const copy = response.clone();
      event.waitUntil(caches.open(CACHE).then(cache => cache.put(event.request, copy)));
    }
    return response;
  }).catch(async () => {
    const cached = await caches.match(event.request);
    if (cached) return cached;
    if (event.request.mode === 'navigate') {
      const shell = await caches.match('./index.html');
      if (shell) return shell;
    }
    return Response.error();
  }));
});
