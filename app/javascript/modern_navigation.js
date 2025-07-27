/**
 * Modern CSS Navigation Enhancements
 * Minimal JavaScript for features that require DOM interaction
 */

// Scroll progress indicator using CSS custom properties
function updateScrollProgress() {
  const scrollTop = window.pageYOffset;
  const docHeight = document.documentElement.scrollHeight - window.innerHeight;
  const scrollPercent = (scrollTop / docHeight) * 100;
  
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

// Keyboard navigation for mobile menu
document.addEventListener('keydown', function(event) {
  if (event.key === 'Escape') {
    const mobileToggle = document.getElementById('mobile-menu-toggle');
    if (mobileToggle && mobileToggle.checked) {
      mobileToggle.checked = false;
      // Focus the menu button for better UX
      document.querySelector('.mobile-menu-button')?.focus();
    }
  }
});

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

console.log('🚀 Modern CSS Navigation loaded - Using View Transitions API, CSS-only animations, and bfcache optimization');