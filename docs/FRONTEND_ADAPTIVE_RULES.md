# Frontend Reuse & Adaptive Layout Rules

**Core rule:** Do not redesign the UI. Reuse the existing screens, components, tokens, and Figma-based visual identity. Adapt data wiring and layout behaviour only.

---

## 1. What May Change

- API clients, models, providers, state wiring.
- Mock/hardcoded data replaced with real API data.
- Navigation entries for screens that already exist.
- Layout constraints to make screens adaptive.
- Error/loading/empty states using existing components.
- EN/AR bindings and RTL behaviour.
- Tests.

## 2. What Must Not Change

- Visual language, colours, typography, iconography, spacing scale.
- Component structure and design-system patterns.
- Screen hierarchy and primary user flows.
- Figma-based layouts on the reference viewport.
- Existing reusable widgets (extend them instead of duplicating).

---

## 3. No Fixed Width/Height Rule

Avoid fixed container dimensions except for:

- Icons and avatar sizes defined by the design system.
- Minimum hit targets/accessibility sizes.
- Intrinsic media aspect ratios.
- Design tokens already approved.

### Do

- Use `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded`, `Spacer`.
- Use `ConstrainedBox` with `minWidth`/`maxWidth` instead of `SizedBox(width: fixed)`.
- Use `FractionallySizedBox` for proportional sizing.
- Use `Wrap` for chips/tags/actions.
- Use `AspectRatio` for images/video.
- Use `FittedBox` for labels that must not overflow.
- Use `SingleChildScrollView` / `ListView` for overflow.
- Use `GridView` with `SliverGridDelegateWithMaxCrossAxisExtent`.
- Use `IntrinsicHeight` only when necessary and measured.
- Use design tokens for spacing, radius, typography.
- Use `TextOverflow.ellipsis`, `maxLines`, and flex constraints.

### Don't

- `SizedBox(width: 320)` for page containers.
- `Container(width: ...)` for cards that should fill space.
- Fixed heights for text/list/dialog content.
- Fixed pixel widths copied from desktop Figma into mobile.
- Absolute positioning that breaks on resize.
- Horizontal overflow without a scroll strategy.
- Hardcoded font sizes outside tokens.

---

## 4. Responsive Breakpoints

Define shared breakpoints in the design system:

| Name | Width |
|---|---|
| compact | < 600 |
| medium | 600–1024 |
| expanded | > 1024 |

Rules:
- Sidebars collapse to drawers/bottom navigation on compact.
- Multi-column grids become single-column on compact.
- Tables become cards or horizontally scrollable on compact.
- Dialogs become full-screen sheets on compact.
- Action bars wrap or collapse into menus.
- Detail panels become stacked.

---

## 5. Component Adaptation

### Cards
- Fill available width.
- Use `ConstrainedBox` for max width on large screens.
- Height from content, not fixed.

### Lists and tables
- Use `ListView.builder` / `SliverList`.
- Tables: horizontal scroll or adaptive column hiding on compact.
- Keep header/action rows wrapping.

### Forms
- Single column on compact, two columns on expanded where appropriate.
- Inputs expand to available width.
- Validation messages wrap.
- Sticky action bar only where it does not cover content.

### Images and video
- Always use `AspectRatio` or intrinsic ratio.
- `BoxFit.cover` with clipping for cards; `BoxFit.contain` for previews.
- Lazy loading and placeholder/error widgets.
- Never fixed image height without aspect ratio.

### Dialogs/sheets
- Use `Dialog`/`showModalBottomSheet` with constraints.
- Full-screen on compact; max width on expanded.
- Scrollable content.

### Navigation
- Desktop sidebar → drawer on compact.
- Preserve active state and route names.

---

## 6. Text and RTL

- All strings from ARB (UI chrome) or API (dynamic content).
- No inline English/Arabic in widgets.
- Use `Directionality` from locale.
- Use start/end padding/margins, not left/right.
- Icons that imply direction flip in RTL where appropriate.
- Numbers remain Western digits (D-040).
- Test long Arabic and English labels; use `maxLines`/ellipsis.

---

## 7. Accessibility

- Minimum touch target 44x44.
- Semantic labels for icon buttons.
- Focus order and keyboard navigation.
- Dialog focus trapping and restore.
- Text contrast from design tokens.
- Status conveyed by text + icon, not colour alone.
- Alt text for evidence photos.
- Screen-reader labels for dynamic issue fields.

---

## 8. State Handling

- Loading: existing skeleton/spinner components, no layout shift.
- Empty: existing empty-state component.
- Error: existing inline error/banner; map structured API errors to fields.
- Offline: existing sync badge/queue status.
- Disabled actions explain why (tooltip/inline text).

---

## 9. Testing

- Widget tests at compact/medium/expanded sizes.
- Golden tests for key screens at phone/tablet/desktop.
- RTL and Arabic text overflow tests.
- No overflow exceptions in tests.
- Accessibility checks for new screens.
- Visual regression against existing design.

---

## 10. Review Checklist

- [ ] No new fixed page/card widths or heights.
- [ ] Layout works at 360, 600, 768, 1024, 1440 px.
- [ ] Portrait and landscape tested.
- [ ] EN and AR/RTL tested.
- [ ] No overflow exceptions.
- [ ] Existing components reused; no duplicate widgets.
- [ ] Design tokens used for spacing/typography.
- [ ] Loading/empty/error states present.
- [ ] All strings localized.
- [ ] Accessibility labels present.
