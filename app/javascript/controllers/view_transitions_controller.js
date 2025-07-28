import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="view-transitions"
export default class extends Controller {
  connect() {
    // Check for View Transitions API support
    if (!document.startViewTransition) {
      document.documentElement.style.setProperty('view-transition-name', 'none');
    }
    
    // Enhanced bfcache compatibility
    window.addEventListener('pageshow', this.handlePageShow.bind(this));
  }

  disconnect() {
    window.removeEventListener('pageshow', this.handlePageShow.bind(this));
  }

  handlePageShow(event) {
    if (event.persisted) {
      // Page was restored from bfcache
      // Find and hide any active page loader
      const pageLoaderController = this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller*="page-loader"]'), 
        'page-loader'
      );
      
      if (pageLoaderController && pageLoaderController.hide) {
        pageLoaderController.hide();
      }
    }
  }
}