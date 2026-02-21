self.addEventListener("push", (event) => {
  if (!event.data) return

  event.waitUntil(
    (async () => {
      const { title, options } = await event.data.json()
      await self.registration.showNotification(title, options)
    })()
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  event.waitUntil(
    (async () => {
      const path = event.notification.data?.path || "/"
      const targetPath = (new URL(path, self.location.origin)).pathname
      const currentClients = await clients.matchAll({ type: "window", includeUncontrolled: true })

      for (const client of currentClients) {
        const clientPath = (new URL(client.url)).pathname

        if (clientPath === targetPath && "focus" in client) {
          if (client.url !== new URL(path, self.location.origin).href) {
            await client.navigate(path)
          }
          return client.focus()
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(path)
      }
    })()
  )
})
