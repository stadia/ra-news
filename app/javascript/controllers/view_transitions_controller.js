import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="view-transitions"
export default class extends Controller {
  connect() {
    // Check for View Transitions API support
    if (!document.startViewTransition) {
document.documentElement.classList.add('no-view-transitions');
    }

    // Enhanced bfcache compatibility
    this.boundHandlePageShow = this.handlePageShow.bind(this);
    window.addEventListener('pageshow', this.boundHandlePageShow);
  }

  disconnect() {
    window.removeEventListener('pageshow', this.boundHandlePageShow);
  }

  handlePageShow(event) {
    if (event.persisted) {
      // Page was restored from bfcache
      // Find and hide any active page loader
      const pageLoaderController = this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller~="page-loader"]'),
        'page-loader'
      );

      if (pageLoaderController && pageLoaderController.hide) {
        pageLoaderController.hide();
      }
    }
  }
}
