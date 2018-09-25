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

// self.addEventListener('install', function(event) {
//     event.waitUntil(
//         caches.open(CACHE_NAME).then(function(cache) {
//             let cachePromises = PRE_CACHED_ASSETS.map(function(asset) {
//                 var url = new URL(asset, location.href);
//                 var request = new Request(url);
//                 return fetch(request).then(function(response) {
//                     return cache.put(asset, response);
//                 });
//             });

//             return Promise.all(cachePromises);
//         })
//     );
// });

importScripts('/cache-polyfill.js');


self.addEventListener('install', function(e) {
    e.waitUntil(
        caches.open(CACHE_NAME).then(function(cache) {
            return cache.addAll(PRE_CACHED_ASSETS);
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

self.addEventListener('fetch', function(event) {
    console.log(event.request.url);
    event.respondWith(
        caches.match(event.request).then(function(response) {
            return response || fetch(event.request);
        })
    );
});
