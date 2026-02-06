import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "guest_comment_name"
const MAX_NAME_LENGTH = 100

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.loadSavedName()
  }

  loadSavedName() {
    if (!this.hasInputTarget) return

    try {
      const savedName = localStorage.getItem(STORAGE_KEY)
      if (savedName && !this.inputTarget.value) {
        const sanitizedName = this.sanitizeName(savedName)
        if (sanitizedName) {
          this.inputTarget.value = sanitizedName
        }
      }
    } catch (e) {
      console.warn("Failed to load guest name from localStorage:", e)
    }
  }

  save() {
    if (!this.hasInputTarget) return

    try {
      const name = this.inputTarget.value.trim()
      if (name && name.length <= MAX_NAME_LENGTH) {
        localStorage.setItem(STORAGE_KEY, name)
      }
    } catch (e) {
      console.warn("Failed to save guest name to localStorage:", e)
    }
  }

  sanitizeName(name) {
    // 길이 제한 및 HTML 태그 제거
    if (!name || name.length > MAX_NAME_LENGTH) return ""
    return name.replace(/<[^>]*>/g, "").trim()
  }
}
