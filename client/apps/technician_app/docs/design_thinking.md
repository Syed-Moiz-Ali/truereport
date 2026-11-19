# Sign-in design thinking (Phase 3a)

Three directions follow. This block is the shared brief; the direction agents
must not see each other's work.

## 1. The job

Get a technician from "app opened" to "my assigned jobs" in seconds — on a
phone, often one-handed, in a bright noisy bay, in English or Arabic — without
ever making them wonder whether the app is broken.

## 2. What today's screen gets wrong

Not "it looks dated". Structurally:

1. **It is a phone drawing stretched to every size.** Above 900 px the only
   change is a 350 px max-width column centred in whitespace; tablet and
   desktop get a phone screen with a huge empty margin.
2. **The identity area is a void.** A 222 px hero exists to hold an 80 px box
   that draws a blurred glow and no mark, then the product name and a tagline.
   It spends the most valuable area on nothing.
3. **The form has no visible labels.** The hint *is* the label; once the field
   is filled the label disappears. There is no persistent structure for the eye.
4. **Feedback is an afterthought.** A validation failure is silent to assistive
   tech, does not focus the bad field, and the error text is a centred line
   between the password row and the button.
5. **Two dead affordances.** "Password help" has no handler and no endpoint;
   "Get help" is styled like a link but is plain text. The screen promises
   support it cannot deliver.
6. **The 2FA state is bolted on.** A third field is appended to the same column
   and the primary label flips to "Verify", with no explanation of what
   happened. (It is also effectively unreachable for technicians — see below.)
7. **The footer is a Figma slot, not a layout.** Fixed pixel widths for two
   strings, then a security caption; a copy-fit test pins those exact widths.
8. **The language switch floats above everything** with no relationship to the
   content below it.

## 3. Constraints that actually bind

| Constraint | Consequence |
|---|---|
| **No pre-auth workshop identity** — the workshop name exists only after login (`memberships[]`) | No branded workshop header, no "Bay 04", no fake tenant. Identity must come from the product, not invented data |
| **Fixed copy set, no new ARB keys this wave** | The only words available are listed in §4. No invented steps, pills, stats or promises |
| **Light-only** (`AppTheme.build` asserts light) | No dark direction; contrast work happens on light surfaces |
| **Bundled fonts only** (`Plus Jakarta Sans`, `Noto Sans Arabic`, …) | Real-font previews; no new families |
| **Behaviour preserved** | Email → password → submit; 2FA path preserved; 8 widget keys preserved; router untouched |
| **2FA is effectively unreachable for technicians** | Design it as a calm secondary state, never the signature |
| **Phone-first, one-handed, gloves possible** | Primary action in the thumb zone; ≥56 px controls; 16 px minimum body |
| **Arabic is first-class** | Layout must mirror cleanly; numbers/latin identifiers stay LTR |
| **No fake product chrome** | No disabled nav, no tabs, no counters, no "example job" |

## 4. The entire available copy set (exact EN)

`TrueReport` · "Vehicle inspection reports for partner workshops." ·
"Use your workshop account." · `Email` · `Password` · "Authentication code" ·
`Sign in` / `Verify` · "Need technician login?" · "Get help" ·
"Authorised workshop staff only" · `English` / `العربية` ·
"Email or password is incorrect." · "Cannot reach the server. Check your
connection." · "Something went wrong. Try again." · "This field is required." ·
"Enter a valid email address."

Anything else — section labels, step counts, feature blurbs — needs a new ARB
key and is **out of scope**. Structure must come from layout, type, rules,
spacing and the security line, not from invented words.

## 5. Axes we vary (colour is not an axis)

| Axis | Direction A | Direction B | Direction C |
|---|---|---|---|
| Layout logic | editorial column on a baseline grid | one bounded document (work order) | full-bleed canvas + docked action bar |
| Hierarchy | task-led, flat | object-led (the sheet is the hero) | statement-led (the headline is the hero) |
| Density | airy, ruled | dense, tabular | spacious top, dense action band |
| Nav shell | none; utility strip | none; perforated header | none; command strip |
| Motion verb | settle (180 ms) | stamp (120 ms) | rise (240 ms) |
| Desktop stance | masthead left, form right on a 12-col grid | sheet left-of-centre, stamp column right | band across the bottom, statement top-left |

Each direction must be recognisably different **in structure at 1440 and 390**
before any colour is considered.

## 6. Non-negotiable behaviour for every direction

- Fields keep `sign-in-email`, `sign-in-password`, `sign-in-submit`,
  `sign-in-language-en/ar`; the access and security lines keep
  `sign-in-access-prompt` and `sign-in-security-line`.
- Email: LTR, email keyboard, `AutofillHints.email`.
- Password: obscured by default, reveal control with an accessible name and a
  ≥44 px target, `AutofillHints.password`, Enter submits.
- One primary action per screen; nothing else is filled.
- An error region that is a `liveRegion` and never shifts the layout.
- 2FA: a code field appears after the challenge; it must accept 6 digits **or**
  an 11-character recovery code, and the primary label becomes "Verify".
- Language switch writes `localeProvider`; typed text persists across the swap.
- No string outside §4. No fake data. No invented logo.

## 7. Evidence each direction must produce

1. `docs/concepts/<a|b|c>/wireframe.md` — structural ASCII at 1440 and 390,
   departure list, type/colour character, trade-off.
2. `test/preview/directions/<a|b|c>/` — a preview widget + a capture test that
   renders with `loadF2AFonts()` at 1440×900 and 390×844, plus a style tile
   (type scale, colour chips, control samples) at 1200×620. Captures go to the
   system temp dir (never `docs/`); report the absolute paths.
3. A short trade-off paragraph: what this direction makes harder.

The main session copies the PNGs into `docs/evidence/signin_directions/<a|b|c>/`
and presents them at Gate 3.
