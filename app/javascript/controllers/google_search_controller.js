import { Controller } from "@hotwired/stimulus"

const SCRIPT_ID = "google-programmable-search-script"
const LOAD_TIMEOUT_MS = 10_000
const GNAME_PREFIX = "ruby-news-programming-search"

let googleSearchPromise
let gnameCounter = 0

function loadGoogleSearch(engineId) {
  if (window.google?.search?.cse?.element) return Promise.resolve()
  if (googleSearchPromise) return googleSearchPromise

  googleSearchPromise = new Promise((resolve, reject) => {
    window.__gcse = {
      parsetags: "explicit",
      callback: resolve
    }

    document.getElementById(SCRIPT_ID)?.remove()

    const script = document.createElement("script")
    script.id = SCRIPT_ID
    script.async = true
    script.src = `https://cse.google.com/cse.js?cx=${encodeURIComponent(engineId)}`
    script.addEventListener("error", reject, { once: true })
    document.head.appendChild(script)
  }).catch((error) => {
    googleSearchPromise = undefined
    document.getElementById(SCRIPT_ID)?.remove()
    throw error
  })

  return googleSearchPromise
}

export default class extends Controller {
  static targets = ["container", "loading", "error"]
  static values = {
    engineId: String,
    query: String,
    errorMessage: String
  }

  connect() {
    gnameCounter += 1
    this.gname = `${GNAME_PREFIX}-${gnameCounter}`
    this.load()
  }

  disconnect() {
    window.clearTimeout(this.timeoutId)
    this.cleanupElement()
  }

  cleanupElement() {
    const element = window.google?.search?.cse?.element?.getElement?.(this.gname)
    if (element && typeof element.cleanup === "function") {
      try {
        element.cleanup()
      } catch {
        // CSE 내부 상태가 이미 해제된 경우는 무시한다.
      }
    }
  }

  async load() {
    this.didTimeout = false
    this.timeoutId = window.setTimeout(() => {
      this.didTimeout = true
      this.showError()
    }, LOAD_TIMEOUT_MS)

    try {
      await loadGoogleSearch(this.engineIdValue)
      if (!this.element.isConnected || this.didTimeout) return

      window.google.search.cse.element.render({
        div: this.containerTarget,
        tag: "searchresults-only",
        gname: this.gname,
        attributes: { linkTarget: "_blank" }
      })

      if (this.queryValue) {
        window.google.search.cse.element.getElement(this.gname).execute(this.queryValue)
      }

      window.clearTimeout(this.timeoutId)
      this.loadingTarget.hidden = true
      this.errorTarget.hidden = true
    } catch {
      this.showError()
    }
  }

  showError() {
    window.clearTimeout(this.timeoutId)
    this.loadingTarget.hidden = true
    this.errorTarget.textContent = this.errorMessageValue
    this.errorTarget.hidden = false
  }
}
