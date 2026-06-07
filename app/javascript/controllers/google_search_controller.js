import { Controller } from "@hotwired/stimulus"

const SCRIPT_ID = "google-programmable-search-script"
const LOAD_TIMEOUT_MS = 10_000
const ELEMENT_NAME = "ruby-news-programming-search"

let googleSearchPromise

function loadGoogleSearch(engineId) {
  if (window.google?.search?.cse?.element) return Promise.resolve()
  if (googleSearchPromise) return googleSearchPromise

  googleSearchPromise = new Promise((resolve, reject) => {
    window.__gcse = {
      parsetags: "explicit",
      callback: resolve
    }

    const existingScript = document.getElementById(SCRIPT_ID)
    if (existingScript) {
      existingScript.addEventListener("error", reject, { once: true })
      return
    }

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
    this.load()
  }

  disconnect() {
    window.clearTimeout(this.timeoutId)
  }

  async load() {
    this.timeoutId = window.setTimeout(() => this.showError(), LOAD_TIMEOUT_MS)

    try {
      await loadGoogleSearch(this.engineIdValue)
      if (!this.element.isConnected) return

      window.google.search.cse.element.render({
        div: this.containerTarget,
        tag: "search",
        gname: ELEMENT_NAME
      })

      if (this.queryValue) {
        window.google.search.cse.element.getElement(ELEMENT_NAME).execute(this.queryValue)
      }

      window.clearTimeout(this.timeoutId)
      this.loadingTarget.hidden = true
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
