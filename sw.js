// Service Worker for Mustagro PWA
// Cache Version: mustagro-v29.1-grocery-withdrawals-fix
const CACHE_NAME = 'mustagro-v29.1-grocery-withdrawals-fix';

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
            console.log('[SW] Purging old cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);

  // NEVER cache or intercept Supabase database requests
  if (url.hostname.includes('supabase.co') || url.hostname.includes('supabase.in')) {
    return;
  }

  // Network-First for HTML navigation so updates appear IMMEDIATELY
  if (event.request.mode === 'navigate' || event.request.destination === 'document' || url.pathname.endsWith('index.html')) {
    event.respondWith(
      fetch(event.request, { cache: 'no-cache' })
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const resClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, resClone));
          }
          return networkResponse;
        })
        .catch(() => caches.match(event.request).then(cached => cached || caches.match('./index.html')))
    );
    return;
  }

  // Cache First with Network Fallback for static assets
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) return cachedResponse;
      return fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const resClone = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, resClone));
        }
        return networkResponse;
      });
    })
  );
});

// =========================================================================
// معالجة النقر على الإشعارات وفتح التطبيق حتى لو كان مغلقاً (Notification Click)
// =========================================================================
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetSection = event.notification.data ? event.notification.data.targetSection : '';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes('index.html') && 'focus' in client) {
          if (targetSection) {
            client.postMessage({ action: 'NAVIGATE_SECTION', targetSection: targetSection });
          }
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('./index.html' + (targetSection ? '#' + targetSection : ''));
      }
    })
  );
});

// =========================================================================
// استقبال إشعارات الـ Web Push السحابية الموجهة في الخلفية
// =========================================================================
self.addEventListener('push', (event) => {
  let data = { title: '🌱 إشعار مشروع كسمور (Mustagro)', body: 'تم تسجيل عملية جديدة في بيانات المشروع' };
  try {
    if (event.data) {
      data = event.data.json();
    }
  } catch (e) {
    if (event.data) data.body = event.data.text();
  }

  const options = {
    body: data.body || data.details || 'تحديث جديد في مشروع كسمور',
    icon: './assets/icon-192.png',
    badge: './assets/icon-192.png',
    tag: data.tag || ('mustagro-' + Date.now()),
    renotify: true,
    data: { targetSection: data.targetSection || 'section-dashboard' }
  };

  event.waitUntil(
    self.registration.showNotification(data.title || 'Mustagro: تنبيه سحابي', options)
  );
});
