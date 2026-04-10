# Al News — Theming Guide

## Theme System

Class-based theme switching using `.theme-dark` / `.theme-light` classes on the `<body>` element, powered by a custom Stimulus controller.

### How It Works

1. CSS custom properties are defined for both themes in `tokens.css`
2. The `@custom-variant dark` in `application.css` maps to `.theme-dark *` and `.dark *`
3. A Stimulus controller toggles the theme class and persists the choice

### Theme CSS Structure

```
:root, .theme-dark, .dark {
  /* Dark theme values (default) */
  --color-bg-primary: var(--neutral-900);
  --color-text-primary: var(--neutral-50);
  ...
}

.theme-light, .light {
  /* Light theme values */
  --color-bg-primary: var(--neutral-50);
  --color-text-primary: var(--neutral-950);
  ...
}
```

### Components

Theme-aware components use semantic Tailwind classes that automatically adapt:

```ruby
# These automatically respond to theme changes
"bg-background"     # → dark: neutral-900, light: white
"text-foreground"   # → dark: neutral-50, light: neutral-950
"border-border"     # → dark: oklch(1 0 0 / 10%), light: neutral-300
```

### Theme Toggle Component

```ruby
# ThemeToggle renders both icons, CSS handles visibility
render RubyUI::ThemeToggle.new
```

The `SetDarkMode` and `SetLightMode` components use `dark:hidden` / `hidden dark:inline-block` for icon visibility toggling.

### Adding a New Theme

1. Add a new CSS block in `tokens.css` with your theme class (e.g., `.theme-custom`)
2. Define all semantic token values for the new theme
3. Add the theme option to the Stimulus controller's toggle cycle

### Dark Mode Tailwind Usage

Use the custom variant for dark-mode-only overrides:

```ruby
# Only when the semantic token system doesn't cover the case
"dark:prose-invert"  # Tailwind Typography plugin integration
```

**Avoid:** Don't use `dark:` prefix for colors that have semantic tokens. Use the token instead.

```ruby
# Wrong
"bg-neutral-900 dark:bg-neutral-50"

# Correct
"bg-background"
```
