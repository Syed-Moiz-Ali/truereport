# Design System

**Project:** TrueReport  
**Document:** 10-design-system.md  
**Status:** Phase 1 proposal. Brand colours and fonts are not final; tokens are the contract.

---

## 1. Design intent

- **Calm, trustworthy, practical.** A workshop tool, not a marketing site.
- **One-hand first** on the technician phone; **keyboard first** on the Platform Admin web.
- **Safety is visible.** Severity and status always use colour + icon + text.
- **No false reassurance.** Never use a green “pass” badge that implies the vehicle is perfect.
- **Arabic is a first-class layout**, not a mirrored afterthought.
- **Low-end Android performance matters.** Avoid heavy blur, large shadows, decorative animation and giant images.

---

## 2. Tokens

Tokens are the only approved source of colour, spacing, type and motion. Feature code uses semantic tokens, not raw hex values.

### 2.1 Colour (light theme proposal)

| Token | Value | Use |
|---|---|---|
| `color.brand.900` | `#0B3B4A` | Primary brand, headers, primary buttons |
| `color.brand.700` | `#0F5B63` | Hover/pressed |
| `color.brand.100` | `#DCEBED` | Selected/soft brand background |
| `color.accent.600` | `#0F6B6F` | Links, focus ring, progress |
| `color.surface` | `#FFFFFF` | Cards, sheets |
| `color.surface.subtle` | `#F7FAFA` | Page background |
| `color.surface.raised` | `#FFFFFF` + elevation 1 | Modals, popovers |
| `color.ink` | `#17212B` | Primary text |
| `color.ink.muted` | `#4D6670` | Secondary text |
| `color.ink.disabled` | `#7A8890` | Disabled text |
| `color.line` | `#D5E3E6` | Borders/dividers |
| `color.focus` | `#0B63CE` | Visible focus ring |
| `color.overlay` | `rgba(11,59,74,0.40)` | Modal scrim |

### 2.2 Status colours

| Token | Value | Use |
|---|---|---|
| `status.neutral.fg` | `#3F4A54` | Draft, not started, not applicable |
| `status.neutral.bg` | `#EDF1F3` | Neutral chip background |
| `status.info.fg` | `#1D5C8A` | Scheduled, in progress, assigned |
| `status.info.bg` | `#E5F0F8` | Info chip background |
| `status.success.fg` | `#1F6B45` | Received, finalized, verified |
| `status.success.bg` | `#E6F3EC` | Success chip background |
| `status.warning.fg` | `#8A5A00` | Attention, retry pending, consent missing |
| `status.warning.bg` | `#FFF4D6` | Warning chip background |
| `status.danger.fg` | `#A3231F` | Defect, failed, revoked, error |
| `status.danger.bg` | `#FBE9E7` | Danger chip background |
| `status.critical.fg` | `#7F1D1D` | Safety-critical |
| `status.critical.bg` | `#F7DADA` | Critical chip background |

**Contrast rule:** every foreground/background pair must meet WCAG 2.2 AA (4.5:1 for normal text, 3:1 for large text and UI components). Verify with a contrast tool, not by eye.

### 2.3 Severity colours

| Severity | Foreground | Background | Icon |
|---|---|---|---|
| Minor | `#5B6570` | `#EEF1F3` | small dot / info circle |
| Moderate | `#8A5A00` | `#FFF4D6` | warning triangle |
| Major | `#A3231F` | `#FBE9E7` | filled warning |
| Safety-critical | `#7F1D1D` | `#F7DADA` | stop/octagon + “Do not drive” guidance |

Severity is **not** a condition score. Do not sum severities into a single number.

### 2.4 Typography

| Token | Size / line height | Use |
|---|---|---|
| `type.display` | 28 / 34 | Public report title, large empty-state heading |
| `type.h1` | 24 / 30 | Screen title |
| `type.h2` | 20 / 26 | Section title |
| `type.h3` | 16 / 22 | Card title |
| `type.body` | 15 / 22 | Default UI text |
| `type.body.arabic` | 15 / 26 | Arabic body; allow diacritics/descenders |
| `type.label` | 13 / 18 | Field labels, chips |
| `type.caption` | 12 / 16 | Helper text, footers |

- Font families are **Pending licence verification**. Candidates include a Latin+Arabic family and a CJK fallback; do not bundle until licences and coverage are checked.
- Use tabular numerals for tables, IDs, odometer and measurements.
- Do not letter-space Arabic.
- Support text scaling to 200% without clipping.

### 2.5 Spacing

`4, 8, 12, 16, 24, 32, 48, 64` logical pixels. Use a 4 px base grid.

- Screen padding: 16 px phone, 24 px tablet, 32 px desktop.
- Card padding: 16 px; dense table cells: 8–12 px.
- Gap between form fields: 16 px; between sections: 24–32 px.

### 2.6 Radius and elevation

| Token | Value | Use |
|---|---|---|
| `radius.sm` | 4 | Inputs, chips |
| `radius.md` | 8 | Cards, buttons |
| `radius.lg` | 12 | Sheets, large cards |
| `radius.pill` | 999 | Status pills |
| `elevation.0` | none | Flat surfaces |
| `elevation.1` | subtle 1 px border + light shadow | Cards |
| `elevation.2` | stronger shadow | Modals/popovers only |

Avoid heavy shadows; they are expensive on low-end Android.

### 2.7 Motion

| Token | Duration | Use |
|---|---|---|
| `motion.fast` | 120 ms | Hover, chip state |
| `motion.normal` | 180 ms | Screen transitions, list item reveal |
| `motion.slow` | 240 ms | Sheet/modal |
| `motion.reduced` | 0 ms | When `MediaQuery.disableAnimations` is true |

Rules:

- No decorative motion on checklist screens.
- Never delay data entry for an animation.
- Respect the OS “reduce motion” setting centrally.
- No parallax, autoplay or looping animation.

### 2.8 Breakpoints

| Token | Width | Target |
|---|---|---|
| `bp.phone` | < 600 | Technician, public report |
| `bp.phablet` | 600–899 | Large phone/small tablet |
| `bp.tablet` | 900–1199 | Admin tablet/small laptop |
| `bp.desktop` | ≥ 1200 | Admin web |

### 2.9 Touch and focus

- Minimum touch target 44×44 logical px; preferred 48×48.
- Focus ring: 2 px `color.focus` with 2 px offset; never remove focus without a replacement.
- Hover is optional; do not rely on it for actions.

---

## 3. Status and severity indicators

### 3.1 Rule: colour + icon + text

Every status or severity indicator has:

1. a text label,
2. an icon (not the only cue),
3. a colour that meets contrast,
4. an accessible name for screen readers.

Do not use colour alone. Do not use an icon alone for a destructive or safety-critical action.

### 3.2 Inspection status chips

| Status | Label EN | Label AR (draft) | Icon | Colour |
|---|---|---|---|---|
| `DRAFT` | Draft | مسودة | pencil | neutral |
| `SCHEDULED` | Scheduled | مجدول | calendar | info |
| `ASSIGNED` | Assigned | مُسند | person | info |
| `IN_PROGRESS` | In progress | قيد الفحص | progress | info |
| `READY_TO_FINALIZE` | Ready to finalize | جاهز للاعتماد | check circle outline | brand/teal |
| `FINALIZED` | Finalized | معتمد نهائياً | lock/check | success |
| `CANCELLED` | Cancelled | ملغى | slash | neutral/danger |

Do not add `PENDING_REVIEW`, `APPROVED`, `REJECTED` or `RESUBMITTED`.

### 3.3 Result indicators

| Result | Label EN | Icon | Colour |
|---|---|---|---|
| `NO_ISSUE_OBSERVED` | No issue observed in this check | check outline (not a “pass” seal) | neutral/success outline |
| `ATTENTION_RECOMMENDED` | Attention recommended | info/warning | warning |
| `DEFECT_FOUND` | Defect found | warning | danger |
| `NOT_CHECKED` | Not checked | minus circle | neutral |
| `NOT_APPLICABLE` | Not applicable | slash circle | neutral |
| `COULD_NOT_VERIFY` | Could not verify | question circle | warning/neutral |

`NO_ISSUE_OBSERVED` must never be labelled “Pass”, “Perfect” or “Certified”.

### 3.4 Severity badge

- Shape: pill or badge with icon + `Minor/Moderate/Major/Safety-critical`.
- Safety-critical includes explicit text such as “Do not drive — immediate attention” where the master item supports it; do not invent safety advice beyond approved content.
- In tables, keep the badge compact but keep the text; do not reduce to a colour dot.

### 3.5 Sync indicators

| State | Label | Icon | Colour |
|---|---|---|---|
| `LOCAL_ONLY` | Saved on this phone | phone | neutral |
| `QUEUED` | Waiting to send | clock | neutral/info |
| `UPLOADING` | Sending… | arrow up | info |
| `RECEIVED` | Received by server | cloud check | success |
| `FAILED` | Not sent — retry | alert | danger |
| `CONFLICT` | Needs review | branch/alert | warning |

“Submitted” and “Finalized” are distinct; do not use them interchangeably.

---

## 4. Components

### 4.1 Core

- Button: primary, secondary, tertiary, destructive; loading state; disabled with reason; min 44 px.
- Icon button: tooltip + accessible label.
- Text field: label, hint, error, prefix/suffix, direction toggle, character count, keyboard type.
- Search field: debounced, clear button, result count, no-results state.
- Select / combobox: searchable, keyboard, empty, loading, “Other”.
- Checkbox / radio / switch: label is part of the tap target; never colour-only.
- Chip: filter, status, severity; removable where appropriate.

### 4.2 Structure

- Card; section header; list item; divider; accordion.
- App bar / top bar; bottom navigation; side navigation; breadcrumbs.
- Tabs; stepper; progress header (no fake percentage).
- Empty state; error state; skeleton; offline banner.
- Modal/dialog: title, body, consequence, primary/secondary; destructive confirmation requires the action name.
- Bottom sheet: one-hand actions; drag handle; safe area.
- Toast/snackbar: non-blocking; never the only place a safety-critical message appears.

### 4.3 Data

- **Data table (web):** sticky header, sort, column chooser, row actions, keyboard navigation, responsive card fallback. Candidate library `data_table_2`/`pluto_grid` is Pending; do not pick before an accessibility review.
- **Tree (Platform Admin):** expand/collapse, search, filters, keyboard, virtualized. Candidate `flutter_fancy_tree_view` or custom; Pending Phase 3.
- **Checklist list:** virtualized, sticky progress, large result chips, next/previous.
- **Photo grid:** lazy thumbnails, captions, item link, zoom via `InteractiveViewer`; no full-resolution preload.
- **Upload queue:** per-item state, retry, storage warning, conflict entry.
- **Report renderer:** shared visual language between public report and internal read-only viewer; no edit controls.
- **Audit timeline:** actor, action, entity, time, reason; redacted.

### 4.4 Forms

- Labels above fields; required marked with text, not only an asterisk.
- Inline validation on blur and on submit; never validate aggressively while typing.
- Error summary at the top for long forms, linked to fields.
- Preserve entered values on error.
- Direction toggle for names/notes; fixed LTR for VIN/phone/email.
- Unsaved-change warning before leaving a dirty form.

### 4.5 Feedback

- Loading: skeleton for content; spinner for actions; progress for uploads.
- Success: inline confirmation + next step; finalization success only after server confirmation.
- Error: plain language, code, request ID, retry.
- Empty: what is empty + action.
- Offline: persistent banner + per-item states.

---

## 5. Accessibility (WCAG 2.2 AA target)

### 5.1 Requirements

- Contrast: 4.5:1 normal text; 3:1 large text and UI boundaries.
- Keyboard: every action reachable; visible focus; logical order; no traps; Escape closes overlays.
- Screen reader: semantic labels, headings, table headers, alt text, live-region announcements for async state changes.
- Text scaling: 200% without loss of content/function.
- Touch: 44×44 minimum; spacing between targets.
- Motion: respect reduce motion; no flashing.
- Forms: labels, instructions, error identification, suggestions.
- Language: `lang` attributes; Arabic screen-reader testing.
- Tables: header associations, captions, no layout tables.
- Images: alt text for guide images and evidence; decorative images marked.
- Charts: provide a table/text equivalent; no chart-only data.
- Timeouts: warn before session expiry; preserve work.

### 5.2 Screen-reader announcements

- Sync state changes: “Answer received by server.”
- Finalization: “Inspection finalized. Report is being generated.”
- Errors: assertive only for blocking failures; polite for background sync.
- Do not announce every autosave; batch or use a subtle status.

### 5.3 RTL accessibility

- Reading order follows the logical order; do not mirror the semantics tree.
- `lang` and `dir` are set on the document/route.
- Icons with direction are mirrored; icons with fixed meaning are not.
- Mixed-language labels are announced with the correct language where possible.

### 5.4 Testing

- Automated: `axe`/Flutter accessibility tests, contrast checks, golden tests EN/AR.
- Manual: TalkBack, VoiceOver, NVDA; keyboard-only; 200% zoom; high contrast; reduced motion.
- Public report: no-JS, text selection, browser find, print.

---

## 6. Content style

- Plain language; short sentences; no jargon unless the technician uses it.
- Explain consequences before destructive actions.
- Say “Not checked” and “Could not verify” explicitly; do not hide them.
- Never claim “certified”, “official”, “RTA approved”, “manager approved” or “independent review”.
- Use “inspection coverage”, not a condition score.
- Arabic and English reviewed by native speakers; keep a glossary for status/severity/result terms.

---

## 7. Dark theme (optional)

- Do not ship a dark theme until token contrast and Arabic rendering are tested.
- If added, define a parallel semantic token set; never invert colours automatically.
- Photos and PDFs are unaffected; the report uses a print-light theme.
- Public report should default to light for print and readability; respect `prefers-color-scheme` only after testing.

---

## 8. Design tokens in code

- Flutter: `ThemeExtension` with semantic tokens; no raw `Color(0x...)` in feature code.
- Web/SSR: CSS custom properties mirroring the same names.
- PDF: the same tokens compiled into print CSS; keep the report visual language consistent.
- Token changes are versioned and require an accessibility check.

---

## 9. Component acceptance checklist

- [ ] English and Arabic layouts both reviewed.
- [ ] RTL mirrors layout, not content.
- [ ] Keyboard and screen-reader pass.
- [ ] 200% text scale pass.
- [ ] Contrast pass.
- [ ] Loading, empty, error, success and offline states.
- [ ] No colour-only meaning.
- [ ] No dead end; every empty/error state has a next action.
- [ ] No manager/review/correction/payment action.
- [ ] Touch target ≥ 44 px.
- [ ] Reduced-motion behaviour.
- [ ] Performance check on a low-end Android device.
