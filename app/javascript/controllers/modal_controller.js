import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.modalId = this.element.dataset.modalId;
    this.modal = document.getElementById(this.modalId);
  }

  open() {
    if (this.modal) {
      this.modal.classList.remove("hidden");
    }
  }

  close() {
    if (this.modal) {
      this.modal.classList.add("hidden");
    }
  }
}
