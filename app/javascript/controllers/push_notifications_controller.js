import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static values = {
    publicKey: String,
    subscriptionUrl: String,
    serviceWorkerPath: String,
  }

  async connect() {
    if (!this.supported) return

    const registration = await navigator.serviceWorker.register(this.serviceWorkerPathValue)

    if (Notification.permission === "denied") {
      await this.removeSubscription(registration)
      return
    }

    const permission = Notification.permission === "granted"
      ? "granted"
      : await Notification.requestPermission()
    if (permission !== "granted") return

    const subscription = await this.ensureSubscription(registration)

    await this.saveSubscription(subscription)
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  async saveSubscription(subscription) {
    await fetch(this.subscriptionUrlValue, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify({
        push_subscription: {
          endpoint: subscription.endpoint,
          p256dh: this.encodeKey(subscription, "p256dh"),
          auth: this.encodeKey(subscription, "auth"),
          expiration_time: subscription.expirationTime,
        },
      }),
    })
  }

  async removeSubscription(registration) {
    const subscription = await registration.pushManager.getSubscription()
    if (!subscription) return

    await fetch(this.subscriptionUrlValue, {
      method: "DELETE",
      headers: this.headers,
      body: JSON.stringify({ endpoint: subscription.endpoint }),
    })

    await subscription.unsubscribe()
  }

  async ensureSubscription(registration) {
    const options = {
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.publicKeyValue),
    }

    try {
      return await registration.pushManager.subscribe(options)
    } catch (error) {
      if (error.name !== "InvalidStateError") throw error

      const current = await registration.pushManager.getSubscription()
      if (current) await current.unsubscribe()

      return registration.pushManager.subscribe(options)
    }
  }

  encodeKey(subscription, keyName) {
    const key = subscription.getKey(keyName)
    if (!key) return ""

    return btoa(String.fromCharCode(...new Uint8Array(key)))
  }

  get headers() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": this.csrfToken,
    }
  }

  get csrfToken() {
    const token = document.querySelector("meta[name='csrf-token']")
    return token ? token.content : ""
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = atob(base64)

    return Uint8Array.from(rawData, (char) => char.charCodeAt(0))
  }
}
