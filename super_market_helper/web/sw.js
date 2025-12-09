// SuperMart Manager Service Worker
// Provides offline functionality and background sync

const CACHE_NAME = 'supermart-manager-v1.0.0';
const STATIC_CACHE_NAME = 'supermart-static-v1.0.0';
const DYNAMIC_CACHE_NAME = 'supermart-dynamic-v1.0.0';
const API_CACHE_NAME = 'supermart-api-v1.0.0';

// Files to cache immediately
const STATIC_FILES = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter_service_worker.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
  // Add other essential static assets
];

// API endpoints to cache
const CACHEABLE_API_PATTERNS = [
  /\/api\/products\//,
  /\/api\/categories\//,
  /\/api\/reports\//
];

// Install event - cache static files
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: Caching static files');
        return cache.addAll(STATIC_FILES);
      })
      .then(() => {
        console.log('Service Worker: Static files cached');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('Service Worker: Cache installation failed', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE_NAME && 
                cacheName !== DYNAMIC_CACHE_NAME && 
                cacheName !== API_CACHE_NAME) {
              console.log('Service Worker: Deleting old cache', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log('Service Worker: Activated');
        return self.clients.claim();
      })
  );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Handle different types of requests
  if (request.destination === 'document') {
    // HTML documents - Network first, fallback to cache
    event.respondWith(networkFirstStrategy(request, STATIC_CACHE_NAME));
  } else if (isStaticAsset(request)) {
    // Static assets - Cache first
    event.respondWith(cacheFirstStrategy(request, STATIC_CACHE_NAME));
  } else if (isAPIRequest(request)) {
    // API requests - Network first with cache fallback
    event.respondWith(networkFirstAPIStrategy(request));
  } else {
    // Other requests - Stale while revalidate
    event.respondWith(staleWhileRevalidateStrategy(request, DYNAMIC_CACHE_NAME));
  }
});

// Background Sync event
self.addEventListener('sync', (event) => {
  console.log('Service Worker: Background sync triggered', event.tag);
  
  if (event.tag === 'product-sync') {
    event.waitUntil(syncProducts());
  } else if (event.tag === 'analytics-sync') {
    event.waitUntil(syncAnalytics());
  }
});

// Push notification event
self.addEventListener('push', (event) => {
  console.log('Service Worker: Push notification received');
  
  const options = {
    body: 'You have new inventory updates!',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      url: '/'
    },
    actions: [
      {
        action: 'open',
        title: 'Open App'
      },
      {
        action: 'close',
        title: 'Close'
      }
    ]
  };

  if (event.data) {
    try {
      const payload = event.data.json();
      options.body = payload.message || options.body;
      options.title = payload.title || 'SuperMart Manager';
      options.data = payload.data || options.data;
    } catch (e) {
      console.error('Service Worker: Error parsing push payload', e);
    }
  }

  event.waitUntil(
    self.registration.showNotification('SuperMart Manager', options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('Service Worker: Notification clicked');
  
  event.notification.close();

  if (event.action === 'open' || !event.action) {
    event.waitUntil(
      clients.matchAll({ type: 'window' })
        .then((clientList) => {
          // Check if app is already open
          for (const client of clientList) {
            if (client.url === '/' && 'focus' in client) {
              return client.focus();
            }
          }
          // Open new window if app is not open
          if (clients.openWindow) {
            return clients.openWindow('/');
          }
        })
    );
  }
});

// Message event - communication with main thread
self.addEventListener('message', (event) => {
  console.log('Service Worker: Message received', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  } else if (event.data && event.data.type === 'CACHE_PRODUCT') {
    cacheProductData(event.data.productData);
  } else if (event.data && event.data.type === 'CLEAR_CACHE') {
    clearAllCaches();
  }
});

// Caching Strategies

function networkFirstStrategy(request, cacheName) {
  return fetch(request)
    .then((response) => {
      // Clone response before caching
      const responseClone = response.clone();
      
      if (response.status === 200) {
        caches.open(cacheName)
          .then((cache) => cache.put(request, responseClone));
      }
      
      return response;
    })
    .catch(() => {
      // Network failed, try cache
      return caches.match(request)
        .then((cachedResponse) => {
          if (cachedResponse) {
            return cachedResponse;
          }
          
          // Return offline page or default response
          return createOfflineResponse();
        });
    });
}

function cacheFirstStrategy(request, cacheName) {
  return caches.match(request)
    .then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      
      // Not in cache, fetch from network
      return fetch(request)
        .then((response) => {
          if (response.status === 200) {
            const responseClone = response.clone();
            caches.open(cacheName)
              .then((cache) => cache.put(request, responseClone));
          }
          
          return response;
        });
    });
}

function staleWhileRevalidateStrategy(request, cacheName) {
  const fetchPromise = fetch(request)
    .then((response) => {
      if (response.status === 200) {
        const responseClone = response.clone();
        caches.open(cacheName)
          .then((cache) => cache.put(request, responseClone));
      }
      return response;
    });

  return caches.match(request)
    .then((cachedResponse) => {
      return cachedResponse || fetchPromise;
    });
}

function networkFirstAPIStrategy(request) {
  return fetch(request)
    .then((response) => {
      if (response.status === 200) {
        const responseClone = response.clone();
        caches.open(API_CACHE_NAME)
          .then((cache) => cache.put(request, responseClone));
      }
      return response;
    })
    .catch(() => {
      // Network failed, try API cache
      return caches.match(request, { cacheName: API_CACHE_NAME })
        .then((cachedResponse) => {
          if (cachedResponse) {
            // Add offline indicator to response headers
            const modifiedResponse = cachedResponse.clone();
            modifiedResponse.headers.set('X-Served-By', 'ServiceWorker-Cache');
            return modifiedResponse;
          }
          
          // No cache available, return error response
          return new Response(
            JSON.stringify({
              error: 'Offline',
              message: 'No network connection and no cached data available'
            }),
            {
              status: 503,
              statusText: 'Service Unavailable',
              headers: { 'Content-Type': 'application/json' }
            }
          );
        });
    });
}

// Helper Functions

function isStaticAsset(request) {
  const url = new URL(request.url);
  return url.pathname.includes('/assets/') ||
         url.pathname.includes('/icons/') ||
         url.pathname.includes('/images/') ||
         url.pathname.endsWith('.js') ||
         url.pathname.endsWith('.css') ||
         url.pathname.endsWith('.woff') ||
         url.pathname.endsWith('.woff2');
}

function isAPIRequest(request) {
  const url = new URL(request.url);
  return url.pathname.startsWith('/api/') ||
         CACHEABLE_API_PATTERNS.some(pattern => pattern.test(url.pathname));
}

function createOfflineResponse() {
  return new Response(
    `
    <!DOCTYPE html>
    <html>
      <head>
        <title>SuperMart Manager - Offline</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px;
            background-color: #f5f5f5;
          }
          .offline-container {
            max-width: 400px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          }
          .offline-icon {
            font-size: 64px;
            color: #ff9800;
            margin-bottom: 20px;
          }
        </style>
      </head>
      <body>
        <div class="offline-container">
          <div class="offline-icon">📱</div>
          <h2>SuperMart Manager</h2>
          <h3>You're offline</h3>
          <p>Please check your internet connection and try again.</p>
          <button onclick="location.reload()">Retry</button>
        </div>
      </body>
    </html>
    `,
    {
      status: 200,
      statusText: 'OK',
      headers: { 'Content-Type': 'text/html' }
    }
  );
}

async function syncProducts() {
  console.log('Service Worker: Syncing products...');
  
  try {
    // Get pending changes from IndexedDB or localStorage
    const pendingChanges = await getPendingChanges();
    
    if (pendingChanges.length === 0) {
      console.log('Service Worker: No pending changes to sync');
      return;
    }

    // Send changes to server
    for (const change of pendingChanges) {
      try {
        const response = await fetch('/api/products/sync/', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(change)
        });

        if (response.ok) {
          await removePendingChange(change.id);
          console.log('Service Worker: Synced change', change.id);
        }
      } catch (error) {
        console.error('Service Worker: Failed to sync change', change.id, error);
      }
    }
  } catch (error) {
    console.error('Service Worker: Sync failed', error);
  }
}

async function syncAnalytics() {
  console.log('Service Worker: Syncing analytics...');
  
  try {
    // Sync analytics data
    const analyticsData = await getAnalyticsData();
    
    if (analyticsData) {
      const response = await fetch('/api/analytics/sync/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(analyticsData)
      });

      if (response.ok) {
        await clearAnalyticsData();
        console.log('Service Worker: Analytics synced successfully');
      }
    }
  } catch (error) {
    console.error('Service Worker: Analytics sync failed', error);
  }
}

async function cacheProductData(productData) {
  try {
    const cache = await caches.open(API_CACHE_NAME);
    const url = `/api/products/${productData.id}/`;
    
    const response = new Response(JSON.stringify(productData), {
      headers: { 'Content-Type': 'application/json' }
    });
    
    await cache.put(url, response);
    console.log('Service Worker: Product data cached', productData.id);
  } catch (error) {
    console.error('Service Worker: Failed to cache product data', error);
  }
}

async function clearAllCaches() {
  try {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map(name => caches.delete(name)));
    console.log('Service Worker: All caches cleared');
  } catch (error) {
    console.error('Service Worker: Failed to clear caches', error);
  }
}

// IndexedDB helper functions (simplified placeholders)
async function getPendingChanges() {
  // In real implementation, this would read from IndexedDB
  return [];
}

async function removePendingChange(id) {
  // In real implementation, this would remove from IndexedDB
  console.log('Service Worker: Removing pending change', id);
}

async function getAnalyticsData() {
  // In real implementation, this would read analytics from storage
  return null;
}

async function clearAnalyticsData() {
  // In real implementation, this would clear analytics storage
  console.log('Service Worker: Analytics data cleared');
}

console.log('Service Worker: Loaded successfully');