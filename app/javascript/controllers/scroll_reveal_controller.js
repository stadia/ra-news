import { Controller } from "@hotwired/stimulus"

// CSS 기반 스크롤 애니메이션 컨트롤러
// 기존 JavaScript 기반 애니메이션을 CSS로 대체
export default class extends Controller {
  static targets = ["item"]
  static values = { threshold: Number }

  connect() {
    this.thresholdValue = this.thresholdValue || 0.1
    this.createObserver()
    this.observeItems()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  createObserver() {
    if (!window.IntersectionObserver) {
      // 폴백: 모든 요소를 즉시 표시
      this.itemTargets.forEach(item => item.classList.add("revealed"))
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          // CSS 클래스만 추가하여 애니메이션 트리거
          entry.target.classList.add("revealed")
          this.observer.unobserve(entry.target)
        }
      })
    }, {
      threshold: this.thresholdValue,
      rootMargin: "0px 0px -50px 0px"
    })
  }

  observeItems() {
    this.itemTargets.forEach((item, index) => {
      this._setupItemForObservation(item, index);
    });
  }

  itemTargetConnected(item) {
    if (this.observer && item) {
      const index = this.itemTargets.indexOf(item);
      this._setupItemForObservation(item, index);
    }
  }

  _setupItemForObservation(item, index) {
    // Re-introduce staggering via CSS custom property used by application.css
    item.style.setProperty('--stagger-index', index);

    // Add base class for CSS animations if not present
    if (!item.classList.contains("scroll-reveal")) {
      item.classList.add("scroll-reveal");
    }
    this.observer.observe(item);
  }

  itemTargetDisconnected(item) {
    if (this.observer) {
      this.observer.unobserve(item)
    }
  }
}
