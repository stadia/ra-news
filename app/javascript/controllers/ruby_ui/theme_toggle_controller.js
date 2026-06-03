import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    this.setTheme()
  }

  setTheme({ disableTransitions = false } = {}) {
    if (disableTransitions) this.disableTransitionsForThemeChange()

    const storedTheme = localStorage.theme
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    const dark = storedTheme === 'dark' || (storedTheme !== 'light' && prefersDark)
    document.documentElement.classList.toggle('dark', dark)
    document.documentElement.classList.toggle('light', !dark)
    document.documentElement.classList.toggle('theme-dark', dark)
    document.documentElement.classList.toggle('theme-light', !dark)
  }

  setLightTheme() {
    // Whenever the user explicitly chooses light mode
    localStorage.theme = 'light'
    this.setTheme({ disableTransitions: true })
  }

  setDarkTheme() {
    // Whenever the user explicitly chooses dark mode
    localStorage.theme = 'dark'
    this.setTheme({ disableTransitions: true })
  }

  disableTransitionsForThemeChange() {
    document.documentElement.classList.add('theme-transition-disabled')
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => {
        document.documentElement.classList.remove('theme-transition-disabled')
      })
    })
  }
}
