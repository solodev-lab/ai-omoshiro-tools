const CACHE_NAME = 'tarot-v1';
const ASSETS = [
  './',
  './index.html',
  './style.css',
  './app.js',
  './cards.js'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // API calls and analytics: network only
  if (url.pathname.startsWith('/api/') ||
      url.hostname.includes('googlesyndication') ||
      url.hostname.includes('googletagmanager') ||
      url.hostname.includes('google-analytics')) {
    return;
  }

  // HTML: network first, fall back to cache
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Other assets: cache first, fall back to network
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
