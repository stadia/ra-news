# Al News — Design Token Reference

## Token Architecture

Three-tier hierarchy: **Primitive → Semantic → Component**

```
Primitive tokens     →  Raw OKLCH values (brand-primary, neutral-500)
Semantic tokens      →  Theme-aware mappings (color-bg-primary, color-text-muted)
Component aliases    →  Tailwind utility bindings (bg-background, text-foreground)
```

**Rule:** Components must NEVER consume primitive tokens directly. Always use semantic tokens via Tailwind utility classes.

## Token Files

| File | Purpose |
|------|---------|
| `app/assets/tailwind/tokens.css` | Primitives + semantic mappings (dark/light) |
| `app/assets/tailwind/application.css` | Component aliases via `@theme inline` |

## Color System

All colors use **OKLCH** (Lightness, Chroma, Hue) for perceptual uniformity.

### Brand Palette (Hue ~150, Green)

| Token | OKLCH | Usage |
|-------|-------|-------|
| `--brand-primary` | oklch(0.723 0.192 150) | Primary actions, links |
| `--brand-primary-hover` | oklch(0.627 0.170 149) | Hover states |
| `--brand-primary-light` | oklch(0.800 0.182 152) | Dark theme accents |
| `--brand-primary-dark` | oklch(0.527 0.137 150) | Light theme accents |
| `--brand-primary-deep` | oklch(0.448 0.108 151) | Solid backgrounds |

### Neutral Palette (Hue ~257, Slate)

11 steps from `--neutral-50` (L=0.984) to `--neutral-950` (L=0.129).

### Status Colors

| Token | OKLCH | Hue |
|-------|-------|-----|
| `--color-success` | oklch(0.648 0.175 132) | Green |
| `--color-warning` | oklch(0.769 0.165 70) | Amber |
| `--color-error` | oklch(0.637 0.208 25) | Red |
| `--color-info` | oklch(0.623 0.188 260) | Blue |

## Semantic Tokens (Theme-Aware)

These tokens resolve to different primitives in dark vs light mode:

| Semantic Token | Dark Value | Light Value |
|---------------|------------|-------------|
| `--color-bg-primary` | neutral-900 | neutral-50 |
| `--color-bg-secondary` | neutral-800 | neutral-100 |
| `--color-text-primary` | neutral-50 | neutral-950 |
| `--color-text-muted` | neutral-400 | neutral-600 |
| `--color-border` | neutral-700 | neutral-300 |

## Tailwind Usage

Use semantic Tailwind classes in Phlex components:

```ruby
# Correct — semantic tokens
"bg-background text-foreground border-border"
"bg-primary text-primary-foreground"
"bg-surface text-content"

# Wrong — hardcoded palette
"bg-green-500 text-white border-gray-700"
```

## Adding New Tokens

1. Add primitive value to `:root` in `tokens.css`
2. Add semantic mappings in `.theme-dark` and `.theme-light` blocks
3. Add Tailwind alias in `@theme inline` block in `application.css`
4. Use via Tailwind class in Phlex components

## Spacing Scale (Base-4)

| Token | Value |
|-------|-------|
| `--space-xs` | 0.25rem (4px) |
| `--space-sm` | 0.5rem (8px) |
| `--space-md` | 1rem (16px) |
| `--space-lg` | 1.5rem (24px) |
| `--space-xl` | 2rem (32px) |
| `--space-2xl` | 3rem (48px) |
| `--space-3xl` | 4rem (64px) |
| `--space-4xl` | 6rem (96px) |

## Contrast Requirements

APCA Lc 60+ for all text/background pairs. Verified:
- Dark: foreground (L=0.984) on background (L=0.145) → Lc ~95
- Light: foreground (L=0.129) on background (L=1.0) → Lc ~100
