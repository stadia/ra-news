import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "guest_comment_name"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.loadSavedName()
  }

  loadSavedName() {
    if (!this.hasInputTarget) return

    const savedName = localStorage.getItem(STORAGE_KEY)
    if (savedName && !this.inputTarget.value) {
      this.inputTarget.value = savedName
    }
  }

  save() {
    if (!this.hasInputTarget) return

    const name = this.inputTarget.value.trim()
    if (name) {
      localStorage.setItem(STORAGE_KEY, name)
    }
  }
}
