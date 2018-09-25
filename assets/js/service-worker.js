importScripts('cache-polyfill.js');
const CACHE_NAME = 'awmw-cache';
const PRE_CACHED_ASSETS = [
    '/assets/css/materialize.min.css',
    '/assets/css/style.css',
    '/assets/css/syntax1.css',
    '/assets/js/materialize.min.js',
    '/assets/js/particles.min.js',
    '/assets/js/init.js',
    '/index.html'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll([PRE_CACHED_ASSETS]).then(() => self.skipWaiting());
    })
  );
});

self.addEventListener('activate', function(event) {
    event.waitUntil(
        caches.keys().then(function(cacheNames) {
            return Promise.all(
                // delete old caches
                cacheNames.map(function(cacheName) {
                    if (cacheName !== CACHE_NAME) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});

// self.addEventListener('fetch', function(event) {
//     if (event.request.headers.get('accept').startsWith('text/html')) {
//         event.respondWith(
//             fetch(event.request).catch(error => {
//                 return caches.match('index.html');
//             })
//         );
//     }
// });

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.open(CACHE_NAME)
      .then(cache => cache.match(event.request, {ignoreSearch: true}))
      .then(response => {
      return response || fetch(event.request);
    })
  );
});
