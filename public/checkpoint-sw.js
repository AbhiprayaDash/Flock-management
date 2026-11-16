// Retirement stub for previously registered Shed checkpoint notifications.
self.addEventListener('install',event=>event.waitUntil(self.skipWaiting()));
self.addEventListener('activate',event=>event.waitUntil((async()=>{const subscription=await self.registration.pushManager?.getSubscription().catch(()=>null);if(subscription)await subscription.unsubscribe().catch(()=>{});const notifications=await self.registration.getNotifications?.().catch(()=>[])??[];notifications.forEach(notification=>notification.close());await self.registration.unregister()})()));
