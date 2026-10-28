---
name: KickPulse Mobile
colors:
  surface: '#10131a'
  surface-dim: '#10131a'
  surface-bright: '#363940'
  surface-container-lowest: '#0b0e14'
  surface-container-low: '#191c22'
  surface-container: '#1d2026'
  surface-container-high: '#272a31'
  surface-container-highest: '#32353c'
  on-surface: '#e0e2eb'
  on-surface-variant: '#bccbb9'
  inverse-surface: '#e0e2eb'
  inverse-on-surface: '#2d3037'
  outline: '#869585'
  outline-variant: '#3d4a3d'
  surface-tint: '#4ae176'
  primary: '#4be277'
  on-primary: '#003915'
  primary-container: '#22c55e'
  on-primary-container: '#004b1e'
  inverse-primary: '#006e2f'
  secondary: '#7bd0ff'
  on-secondary: '#00354a'
  secondary-container: '#00a6e0'
  on-secondary-container: '#00374d'
  tertiary: '#ffb5ab'
  on-tertiary: '#60130d'
  tertiary-container: '#ff8b7c'
  on-tertiary-container: '#76231b'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6bff8f'
  primary-fixed-dim: '#4ae176'
  on-primary-fixed: '#002109'
  on-primary-fixed-variant: '#005321'
  secondary-fixed: '#c4e7ff'
  secondary-fixed-dim: '#7bd0ff'
  on-secondary-fixed: '#001e2c'
  on-secondary-fixed-variant: '#004c69'
  tertiary-fixed: '#ffdad5'
  tertiary-fixed-dim: '#ffb4a9'
  on-tertiary-fixed: '#410001'
  on-tertiary-fixed-variant: '#7f2a21'
  background: '#10131a'
  on-background: '#e0e2eb'
  surface-variant: '#32353c'
  surface-base: '#0E1422'
  surface-elevated: '#161F33'
  surface-subtle: '#1D2840'
  border-subtle: '#1F2C44'
  border-strong: '#2D3F60'
  accent-live: '#EF4444'
  accent-warning: '#F59E0B'
  text-primary: '#F8FAFC'
  text-secondary: '#94A3B8'
  text-tertiary: '#64748B'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  stat-metric:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

# KickPulse Mobile Design System

## Visual Identity & Color Tokens
- Canvas Background: `#080B11`
- Surface Base (Cards, Header, Lists): `#0E1422`
- Surface Elevated (Chips, Popovers, Modals): `#161F33`
- Surface Subtle (Badges background, Hover): `#1D2840`
- Border Subtle: `#1F2C44`
- Border Strong: `#2D3F60`

### Accents & Semantic Signals
- Accent Primary (Pitch Green): `#22C55E`
- Accent Live (Pulse / Danger / Goals): `#EF4444`
- Accent Warning (Yellow cards, extra time): `#F59E0B`
- Accent Electric (xG, advanced analytics): `#38BDF8`

### Typography Tokens
- Text Primary: `#F8FAFC`
- Text Secondary: `#94A3B8`
- Text Tertiary: `#64748B`
- Font Family: system-ui, -apple-system, BlinkMacSystemFont, "Inter", sans-serif
- Numbers: tabular-nums lining-nums

## Component Patterns
- Mobile Card Radius: 16px
- Chip Radius: 12px
- Badge Radius: 9999px (full pill)
- Spacing: 8pt grid with 4px micro-adjustments
- Touch targets: Minimum 44x44px
