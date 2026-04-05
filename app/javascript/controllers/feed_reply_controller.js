import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="feed-reply"
export default class extends Controller {
  static values = {
    parentId: Number,
    authorName: String,
    bodyPreview: String
  }

  activate() {
    window.dispatchEvent(new CustomEvent("post-form:reply", {
      detail: {
        parentId: this.parentIdValue,
        authorName: this.authorNameValue,
        bodyPreview: this.bodyPreviewValue
      }
    }))
  }
}
