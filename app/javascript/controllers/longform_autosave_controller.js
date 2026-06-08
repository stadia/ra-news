import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  schedule() {
    if (this.timeout) clearTimeout(this.timeout)
    this.setStatus("저장 대기 중")
    this.timeout = setTimeout(() => this.save(), 800)
  }

  async save() {
    const formData = new FormData(this.element)
    this.setStatus("저장 중")

    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: formData
    })

    if (response.ok) {
      const payload = await response.json()
      this.setStatus(payload.saved_at ? `저장됨 ${payload.saved_at}` : "저장됨")
    } else {
      this.setStatus("저장 실패")
    }
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}
