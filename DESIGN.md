# Design System: Spotify Base for Ruby-News

> Base theme: Spotify-inspired dark interface
> Product adaptation: Ruby-News design tokens, Phlex, RubyUI, Tailwind v4
> Last updated: 2026-04-02

## 1. Design Direction

This document keeps the newly added Spotify-based design file as the visual foundation, then upgrades it with the actual rules, tokens, component usage, and accessibility conventions already established in Ruby-News.

The result is not a literal Spotify clone. It is a Ruby-News design system that borrows Spotify's strongest traits:

- immersive near-black depth
- compact, scan-friendly information density
- restrained accent usage
- rounded tactile controls
- content-first hierarchy

For this project, those traits must always be expressed through the existing semantic token architecture, Phlex views, RubyUI components, and Tailwind v4 utilities.

## 2. Visual Theme & Product Interpretation

Ruby-News should feel bold, modern, and dark-first. The interface lives in a near-black range similar to Spotify (`#121212`, `#181818`, `#1f1f1f`), but unlike a music player, the primary content is article metadata, summaries, tags, author identity, and discussion.

That means the system should preserve Spotify's immersive darkness while adjusting the source of emphasis:

- Spotify uses album art as the dominant color source
- Ruby-News uses typography, semantic accents, badges, and card hierarchy as the dominant source of emphasis

The atmosphere should be:

- professional, not playful
- dense, but still readable in Korean
- modern and tech-focused
- dark by default, with light theme compatibility maintained through semantic tokens

## 3. Core Principles

### Do

- Start from a near-black canvas and build depth through shade differences
- Prefer semantic tokens over raw palette classes in all UI code
- Keep information dense enough for fast scanning
- Use accent color functionally, not decoratively
- Favor rounded controls and soft panels over sharp, rigid blocks
- Use Phlex and RubyUI as the primary expression layer
- Maintain Korean-friendly typography and spacing
- Preserve dark/light compatibility through token mapping

### Do Not

- Do not hardcode Tailwind palette colors like `bg-slate-800` or `text-white`
- Do not add decorative accent colors outside the token system
- Do not introduce ERB for new UI work when Phlex is the project standard
- Do not bypass RubyUI if an equivalent component already exists
- Do not make the layout airy like a marketing site; this is a content product
- Do not rely on color alone to communicate state

## 4. Color Strategy

### Brand & Theme Roles

- **Near Black** (`#121212`): deepest page background
- **Dark Surface** (`#181818`): cards, panels, sections
- **Interactive Surface** (`#1f1f1f`): inputs, buttons, elevated UI
- **Accent Green** (`#1ed760`): conceptual base accent from the Spotify direction

In implementation, Ruby-News should not reference those raw values directly in component code. Use the project token system instead.

### Ruby-News Token Model

Ruby-News already uses a 3-tier token architecture:

1. Primitive tokens: absolute base values in `app/assets/tailwind/tokens.css`
2. Semantic tokens: theme-aware usage tokens in `.theme-dark` and `.theme-light`
3. Component aliases: Tailwind-facing aliases in `app/assets/tailwind/application.css`

This is the required bridge between the visual direction and the production UI.

### Required Semantic Classes

#### Background

- `bg-app`: page background
- `bg-surface`: standard cards and sections
- `bg-surface-muted`: inputs and subdued surfaces
- `bg-surface-elevated`: modals, overlays, dropdowns
- `bg-brand-solid`: primary brand action
- `bg-danger-solid`: destructive action
- `bg-info-solid`: informational action

#### Text

- `text-content`: primary text
- `text-content-secondary`: body text
- `text-content-muted`: metadata and helper copy
- `text-content-disabled`: disabled or de-emphasized text
- `text-accent-text`: branded emphasis
- `text-danger-text`: destructive emphasis
- `text-info-text`: informational emphasis
- `text-brand-foreground`: text on solid brand backgrounds

#### Border & Focus

- `border-border-strong`: standard border
- `border-border-muted`: hover or active border
- `border-border-subtle`: separators and quiet divisions
- `ring-brand`: focus ring
- `ring-offset-app`
- `ring-offset-surface`

## 5. Typography

### Typeface Direction

The visual reference uses SpotifyMixUI-like compact hierarchy. Ruby-News should translate that feel into a Korean-friendly system built on `Noto Sans KR`, with strong weight contrast and modest size variation.

### Typography Principles

- Use bold headings and regular body copy as the primary contrast system
- Keep sizes compact and functional
- Optimize for scan speed over editorial flourish
- Allow slightly more breathing room than Spotify for Korean readability

### Recommended Hierarchy

| Role | Class Direction | Notes |
|------|-----------------|-------|
| Page title | `text-3xl md:text-4xl font-bold text-content leading-tight` | Top-level article/page headings |
| Section heading | `text-lg font-semibold text-content` | Section grouping |
| Body | `text-base text-content-secondary leading-relaxed` | Default readable content |
| Meta | `text-sm text-content-muted` | Timestamps, attribution, counts |
| Small UI | `text-sm font-medium` | Buttons, labels, controls |
| Fine print | `text-xs text-content-muted` | Hints, secondary metadata |

### Button Voice

Spotify's uppercase, wide-tracking button language is a useful reference for system controls, but it should be applied selectively in Ruby-News.

- Use stronger tracking and firmer weight for clear system actions
- Avoid excessive uppercase for long Korean labels
- Prefer clarity and rhythm over mimicry

## 6. Shape, Spacing, and Elevation

### Border Radius

Ruby-News should keep Spotify's rounded/tactile feel, but translate it into the project's existing card and control patterns:

- `rounded-lg`: default action and card radius
- `rounded-xl` to `rounded-2xl`: profile cards, prominent containers
- pill shapes: only where the interaction pattern benefits from it
- full circles: avatars, icon-only buttons, compact toggles

Avoid forcing pill geometry onto every control. That is a visual influence, not a hard rule.

### Spacing

- Base spacing should remain anchored to the existing 8px rhythm
- Dense lists and metadata blocks can use tighter spacing
- Long-form reading areas should loosen spacing slightly

### Elevation

Dark interfaces need visible separation. Use elevation through:

- surface contrast first
- border subtlety second
- shadow third

Heavy shadows are acceptable for overlays and important floating UI, but not every card should feel like a modal.

## 7. Component Rules

### Component Priority

1. RubyUI component
2. Phlex composition around RubyUI
3. Custom markup only when no suitable RubyUI component exists

### Buttons

#### Primary

```ruby
class: "px-4 py-2 text-sm font-medium bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground rounded-lg transition-colors cursor-pointer"
```

#### Secondary

```ruby
class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-surface text-content-secondary rounded-lg transition-colors cursor-pointer"
```

#### Danger

```ruby
class: "px-4 py-2 text-sm font-medium bg-surface-muted hover:bg-danger-solid text-content-secondary hover:text-danger-text rounded-lg transition-colors cursor-pointer"
```

#### Info

```ruby
class: "px-4 py-2 text-sm font-medium bg-info-solid hover:bg-info-solid-hover text-brand-foreground rounded-lg transition-colors cursor-pointer"
```

### Cards

#### Standard

```ruby
render RubyUI::Card.new(class: "bg-surface shadow-md hover:shadow-lg transition-shadow overflow-hidden border border-border-strong p-3 md:p-6")
```

#### Transparent / Profile

```ruby
render RubyUI::Card.new(class: "bg-app/40 border border-border-subtle rounded-2xl overflow-hidden shadow-2xl")
```

### Inputs

```ruby
render RubyUI::Input.new(
  class: "bg-surface-muted border-border-muted text-content placeholder:text-content-muted"
)
```

Inputs should feel soft, dark, and clearly focusable. The Spotify-style search pill can be used for search-heavy contexts, but standard form inputs should stay aligned with the broader system.

### Menus & Popovers

- Use `RubyUI::DropdownMenu` for compact action groups such as overflow menus, per-item actions, and mobile/secondary navigation clusters
- Use `RubyUI::Popover` for lightweight contextual UI such as inline help, metadata reveals, or compact filter panels
- Prefer these components over ad-hoc absolute-positioned menus or custom Stimulus-only overlays
- Keep menu surfaces on `bg-surface-elevated` semantics and avoid decorative color treatment

### Switch & Checkbox

- Use `RubyUI::Switch` for single boolean preferences such as theme, notifications, or feature toggles
- Use `RubyUI::Checkbox` for multi-select filters, consent, bulk actions, and settings lists
- Prefer `Switch` for immediate on/off state and `Checkbox` for selection state; do not interchange them casually
- Labels, descriptions, and disabled states should remain explicit and readable without depending on color alone

### Navigation

```ruby
nav(class: "bg-surface border-b border-border-strong border-t-4 border-t-brand")
```

Navigation should be strong, high-contrast, and easy to scan. Active state emphasis should come from type weight, contrast, and semantic accent usage rather than decorative effects.

### Avatar

```ruby
render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
  render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground font-bold") do
    plain initials
  end
end
```

### Badge

```ruby
render RubyUI::Badge.new(variant: :green) { "팔로잉" }
render RubyUI::Badge.new(variant: :amber) { "요청 중" }
```

## 8. Accessibility Baseline

Accessibility is not optional. The current design system work already established several baseline requirements, and `DESIGN.md` should treat them as part of the default design language.

### Required

- keyboard navigable controls
- visible focus styles
- skip link support
- ARIA labels on meaningful navigation and toggles
- reduced motion support
- acceptable contrast in dark mode

### Focus Utility

```css
.focus-visible-ring {
    @apply focus-visible:outline-none focus-visible:ring-2
           focus-visible:ring-brand focus-visible:ring-offset-2
           focus-visible:ring-offset-app;
}
```

### Skip Link Pattern

```ruby
a(
  href: "#main-content",
  class: "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-brand-solid focus:text-brand-foreground focus:rounded-lg focus:shadow-lg"
) { "본문으로 건너뛰기" }
```

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Contrast Baseline

Dark theme contrast should continue meeting the existing targets already validated in the previous system documentation:

- `text-content` on `bg-app`
- `text-content-secondary` on `bg-app`
- `text-content-muted` on `bg-app`
- `text-accent-text` on `bg-app`

## 9. Responsive Behavior

The Spotify reference helps define dark density and control shape, but Ruby-News layout behavior should stay content-driven.

### Responsive Intent

- article cards and metadata must remain scannable
- navigation should simplify cleanly on smaller screens
- reading views must preserve line length and hierarchy
- touch targets must remain comfortable on mobile

### Practical Rules

- dense grids on desktop
- simplified stacking on tablet
- single-column reading and action flow on mobile
- no decorative complexity that harms content retrieval

## 10. Migration Rules

When updating old UI, treat the following as mandatory replacements:

| Before | After |
|---|---|
| `bg-gray-800`, `bg-slate-800` | `bg-surface` |
| `bg-slate-900` | `bg-app` |
| `text-white`, `text-slate-50` | `text-content` |
| `text-gray-300`, `text-slate-200` | `text-content-secondary` |
| `text-gray-400`, `text-slate-400` | `text-content-muted` |
| `text-gray-500`, `text-slate-600` | `text-content-disabled` |
| `border-gray-700`, `border-slate-700` | `border-border-strong` |
| `border-slate-600` | `border-border-muted` |
| `border-slate-800` | `border-border-subtle` |
| `text-green-400` | `text-accent-text` |
| `bg-green-600 hover:bg-green-500` | `bg-brand-solid hover:bg-brand-solid-hover` |
| `bg-blue-600 hover:bg-blue-500` | `bg-info-solid hover:bg-info-solid-hover` |
| `ring-green-500` | `ring-brand` |
| `ring-offset-slate-900` | `ring-offset-app` |

## 11. Implementation Notes

### Source of Truth

Use these files as the implementation source of truth:

- `app/assets/tailwind/tokens.css`
- `app/assets/tailwind/application.css`
- `app/assets/tailwind/site.css`
- `app/assets/tailwind/pagy-tailwind.css`

This document defines design intent and usage guidance. Token values and theme wiring belong in the CSS token files.

### Theme Status

Already established:

- dark theme foundation
- light theme token mapping
- semantic token migration across major views/components
- accessibility utilities such as skip link and reduced motion support

Still future-facing:

- explicit theme switcher UI
- persisted theme preference
- more complete admin-side semantic token migration
- automated accessibility verification

## 12. Quick Prompt Guide for Future Design Work

When generating or reviewing UI, use prompts like:

- "Use a dark, Spotify-inspired content surface, but implement it strictly with Ruby-News semantic tokens."
- "Prioritize scan-friendly metadata hierarchy with `bg-app`, `bg-surface`, `text-content`, and `text-content-muted`."
- "Use RubyUI first, then wrap with Phlex. Avoid hardcoded Tailwind palette colors."
- "Keep the interface compact, rounded, and dark-first, with accent color reserved for important actions."

## 13. Summary

The base identity of this design system remains the newly added Spotify-inspired document:

- near-black immersion
- compact hierarchy
- restrained accent usage
- rounded controls
- content-first rhythm

What this upgrade adds is the missing production layer:

- Ruby-News token architecture
- semantic Tailwind class mapping
- Phlex and RubyUI component rules
- accessibility baseline
- migration conventions
- theme-aware implementation guidance

Use Spotify as the visual north star, and Ruby-News tokens as the implementation contract.
