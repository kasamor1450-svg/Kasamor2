// Service Worker for Mustagro PWA
// Cache Version: mustagro-v30.0-treasury-balance-63003
const CACHE_NAME = 'mustagro-v30.0-treasury-balance-63003';

const PRECACHE_ASSETS = [
  './manifest.json',
  './frontend/css/styles.css',
  './assets/icon-192.png',
  './assets/icon-512.png'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_ASSETS))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('Purging old PWA Cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  // Always fetch fresh for API requests and index.html to ensure live cloud sync
  if (
    event.request.url.includes('supabase.co') || 
    event.request.url.includes('/rest/v1') || 
    event.request.url.endsWith('index.html') ||
    event.request.mode === 'navigate'
  ) {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      return cachedResponse || fetch(event.request);
    })
  );
});
