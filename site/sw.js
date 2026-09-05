// Tuck's service worker. Keeps the page and its files so it opens with no signal.
// Bump CACHE whenever any file below changes, or people keep seeing the old page.
const CACHE = 'tuck-v2';
const FILES = [
  '/',
  '/index.html',
  '/css/tuck.css?v=1',
  '/fonts/fraunces.woff2',
  '/fonts/inter.woff2',
  '/images/favicon.svg?v=1',
  '/images/icon-192.png?v=1',
  '/images/icon-512.png?v=1',
  '/site.webmanifest?v=1',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

// Network first, cache as the fallback: a fresh page when there is signal, the last one when there is not.
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET' || new URL(event.request.url).origin !== location.origin) return;
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request).then((hit) => hit || caches.match('/')))
  );
});
