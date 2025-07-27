/**
 * Modern CSS Navigation Enhancements
 * Minimal JavaScript for features that require DOM interaction
 */

// Scroll progress indicator using CSS custom properties
function updateScrollProgress() {
  const scrollTop = window.pageYOffset;
  const docHeight = document.documentElement.scrollHeight - window.innerHeight;
  const scrollPercent = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
  
  document.documentElement.style.setProperty('--scroll-progress', `${scrollPercent}%`);
}

// Passive scroll listener for better performance
window.addEventListener('scroll', updateScrollProgress, { passive: true });

// Update on page load
document.addEventListener('DOMContentLoaded', updateScrollProgress);

// Close mobile menu when clicking a link (accessibility improvement)
document.addEventListener('click', function(event) {
  if (event.target.matches('.nav-link')) {
    const mobileToggle = document.getElementById('mobile-menu-toggle');
    if (mobileToggle && mobileToggle.checked) {
      mobileToggle.checked = false;
    }
  }
});

// Update aria-expanded for accessibility
function updateAriaExpanded() {
  const toggle = document.getElementById('mobile-menu-toggle');
  const button = document.querySelector('.mobile-menu-button');
  if (toggle && button) {
    button.setAttribute('aria-expanded', toggle.checked);
  }
}

// Keyboard navigation for mobile menu
document.addEventListener('keydown', function(event) {
  if (event.key === 'Escape') {
    const mobileToggle = document.getElementById('mobile-menu-toggle');
    if (mobileToggle && mobileToggle.checked) {
      mobileToggle.checked = false;
      updateAriaExpanded();
      // Focus the menu button for better UX
      document.querySelector('.mobile-menu-button')?.focus();
    }
  }
});

// Listen for mobile menu toggle changes
document.addEventListener('change', function(event) {
  if (event.target.id === 'mobile-menu-toggle') {
    updateAriaExpanded();
  }
});

// Initialize aria-expanded on page load
document.addEventListener('DOMContentLoaded', updateAriaExpanded);

// View Transitions API integration for enhanced navigation
if ('startViewTransition' in document) {
  // Handle form submissions with view transitions
  document.addEventListener('submit', function(event) {
    const form = event.target;
    if (form.method === 'get') {
      event.preventDefault();
      
      document.startViewTransition(() => {
        form.submit();
      });
    }
  });
}

