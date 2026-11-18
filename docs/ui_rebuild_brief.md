# Workshop Admin UI Rebuild — Design Brief & Reference Analysis

This document outlines the architectural and visual reference patterns adopted for the complete rebuild of the TrueReport Workshop Admin web application.

---

## 1. Reference Product Analysis

### A. Airbnb Host Dashboard
- **Problem Solved:** Overwhelming operational logistics made approachable and calm.
- **Key Patterns:**
  - High-confidence typographic scale: large greetings (`30px/700`) and prominent hero metrics (`40px`).
  - Generous spatial hierarchy (32–40px section gaps) where whitespace defines structure rather than heavy borders or card shadows.
  - "Next Up" hero framing: one focal operational action elevated above background lists, eliminating decision paralysis.

### B. Linear
- **Problem Solved:** Fast, high-density issue navigation for professional workflows.
- **Key Patterns:**
  - Quiet, low-contrast chrome: flat background surfaces with hairline borders (`1px solid #E8E4DD`), no decorative drop shadows.
  - Micro-interactions: 120–180ms ease-out transitions for hover, active tabs, and inline actions.
  - Keyboard-first productivity: instant command palette (`Ctrl+K` / `⌘K`), shortcut badges (`WorkshopKbd`), full-row hover/click targets with pointer cursors.

### C. Stripe Dashboard
- **Problem Solved:** Presenting high-stakes numerical and transactional data with absolute clarity and zero ambiguity.
- **Key Patterns:**
  - Unified Stat Strip: a single monolithic container divided into equal cells by hairline vertical dividers, pairing eyebrow labels with large tabular numbers (`40px/700`).
  - Monolithic single-surface tables: sticky column headers, subtle hover state transitions, and whole-row clicks rather than floating card-in-card nesting.
  - Clean segment tab bars with integrated count chips (`All 12`, `In progress 4`).

### D. Vercel
- **Problem Solved:** Developer tool sophistication with strict monochrome restraint and pristine geometry.
- **Key Patterns:**
  - Restrained palette: `#FAF8F5` warm off-white canvas, `#FFFFFF` crisp surfaces, `#111418` near-black ink, with a single deep green accent (`#0F5C4A`).
  - Strict absence of fluff: no marketing slogans, fake security badges, or arbitrary pill styling.
  - Consistent 8-point spatial rhythm with precise corner radiuses (14px cards, 10px controls, 6px tags).

---

## 2. Adopted Visual & Structural Architecture

1. **Typographic Scale & Contrast:**
   - Hero numbers: `40px/700` tabular figures.
   - Screen titles: `30px/700` (`-0.02em` tracking).
   - Section headers: `18px/700`.
   - Body: `14px/400`. Meta: `12.5px/500`.
2. **Surface & Separation Rules:**
   - At most **one** bordered container per logical module. Tables and KPI strips are single surfaces with internal hairline dividers.
   - 32–40px vertical breathing room between major rows; no orphan boxes.
3. **App Shell:**
   - 256px desktop sidebar with workshop switcher and deterministic initials avatar. Workshop name appears **only once** in this block; top-bar breadcrumbs show page hierarchy only.
   - Tablet collapses to 72px icon rail with hover tooltips. Mobile utilizes top bar + bottom navigation dock with modal sheets for secondary destinations.
4. **Desktop Dashboard Layout (12-col grid, 1280x800 optimized):**
   - **Row 1:** Confident greeting (`30px/700`) + humanized date (left) and single primary action `[+ New job]` (right).
   - **Row 2:** Unified 5-cell Stat Strip with 40px tabular numbers deep-linking to filtered views.
   - **Row 3:** 8-col "Next Up" hero card (tinted background, vehicle 22/700, plate & job code mono, customer, technician avatar, primary CTA) + 4-col "Pipeline" stage progress breakdown with proportional bars.
   - **Row 4:** "Recent jobs" single table surface with hover highlights and full-row navigation.
   - **Row 5:** Compact outlined quick action tiles.
5. **Sign-In Experience:**
   - 50/50 desktop split: Left deep-green panel with subtle geometric grid pattern, headline "Inspections your customers can trust.", supporting copy, and realistic product preview card mock. Right panel: clean 400px centered authentication card.
