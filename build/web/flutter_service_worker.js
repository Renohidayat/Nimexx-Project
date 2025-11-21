'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"googleb2becdde516fe6e9.html": "abea8df9c1a70f5329d62c652bce732c",
"manifest.json": "ef932f46509e7829d8f01d0d6b2272ad",
"version.json": "4684f1d58b112d8d7ff3dbe919b73fca",
"favicon.png": "62baa01e5529316011991f3a72073d7a",
"assets/AssetManifest.bin.json": "d0f5237ac57ceecee68ae2c09e342efc",
"assets/AssetManifest.json": "4417f34ae0c7433104821b12c94728c0",
"assets/og-image.jpg": "07ce5a7f1bcd69fea55edafcb9d3a618",
"assets/NOTICES": "dbe5c2cada9b73ed0fa0695dc0341f71",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "da0d99f115a26e76597e09a3975a5b96",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/images/h4.png": "dbf68963bd70c3f65dd5b2d486cdec10",
"assets/assets/images/86.jpg": "29792602922b2a45517d0aefde07a550",
"assets/assets/images/one_punch.jpg": "b65870bc43766b602bed1237521b074f",
"assets/assets/images/sao.jpg": "bc825b914fdbd4961f2586653751e2ba",
"assets/assets/images/vinlan.jpg": "3a26ab668f3218113e15aeeee02da9c7",
"assets/assets/images/h3.png": "3a221e9445d3ec3d70f3867d4a30ace7",
"assets/assets/images/love-anime.gif": "be47939dee183b8241b518915d51821a",
"assets/assets/images/bleach.jpg": "6b6f9d044ae4c35a3fbfc4fdf1b6bbea",
"assets/assets/images/logo.png": "0700219e04bf2c0170c3244f878bcd31",
"assets/assets/images/monster.jpg": "c4a265538d96ff058c12916c40158dce",
"assets/assets/images/kny.jpg": "a3ce1dfc67f4351d4782ae5222701a5a",
"assets/assets/images/vivy.jpg": "0ef8c129c33826a8f83a1a12b847728c",
"assets/assets/images/boruto.jpg": "86aea7857f9399a31cfec74f74a55fc3",
"assets/assets/images/wibu.png": "8933b3aecb9e6649bbf7c7af70b76db6",
"assets/assets/images/jujutsu.jpg": "da53f2b75c1c36fb9fb917977476feda",
"assets/assets/images/teror.jpg": "f683ef43654d2353b8ece0df31214e32",
"assets/assets/images/default_profile.png": "62baa01e5529316011991f3a72073d7a",
"assets/assets/images/h2.png": "36d68f2cfcb4fe2686903ca2e10367cb",
"assets/assets/images/one_piece.jpg": "33bd24601185678a3137eba16adb9738",
"assets/assets/images/tensei.jpg": "bdcae4cab33d8d36d3c1c1c11e9a3d5c",
"assets/assets/images/solo.jpg": "6a5da798e3736f2f37f0d36a825dba58",
"assets/assets/images/dororo.jpg": "c05e8f34e7aed63a2a7732f2a8b96657",
"assets/assets/images/zero.jpg": "810bf889edc6392e3acd728bb6e286f1",
"assets/web/assets/og-image.jpg": "07ce5a7f1bcd69fea55edafcb9d3a618",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "4e88e7489f2a2caddc59ed1756e5a657",
"index.html": "886edfc51f2153daff3f9bea9f53472f",
"/": "886edfc51f2153daff3f9bea9f53472f",
"browser.html": "74a663e2640a04b5ce0e8a67ffd0c7fc",
"main.dart.js": "27ec0b4c785e241e6243e7f3db02a6fe",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"privacy.html": "3e12acb82294a4a48384dfb06c146883",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"flutter_bootstrap.js": "7c3f7a2cd39204f70d5c41c43914c91b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
