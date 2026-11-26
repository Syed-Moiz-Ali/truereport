# Sign-in · Bay Door — audit proof set

The sign-in is the one **intentional brand exception** to the operational
Fieldwork language: a real technician photograph, a statement, and a glass
credential sheet. It was audited and kept, with six real defects fixed.

| State | 1440 | 390 EN | 390 RTL |
|---|---|---|---|
| Normal | `signin-1440.png` | `signin-390.png` | `signin-390-rtl.png` |
| Error | — | `signin-390-error.png` | — |
| 2FA challenge | — | `signin-390-challenge.png` | — |

Fixes:
1. Reveal control now announces the served **Show/Hide password** action.
2. Busy primary announces **“Signing in…”** in a live region.
3. RTL email hint is LTR-aligned with its caret.
4. The whole 56 px cell focuses the field (not only the 24 px glyph area).
5. Primary has a visible 2 px keyboard focus ring.
6. Status/nav icons are light over the dark photo (`AnnotatedRegion`).

Audit: persistent labels, 56 px controls, 48 px reveal, tab order
email → password → reveal → primary, double-submit guarded, error row reserved
above the primary, 130 % text does not overflow, 2FA locks email and shows the
code + Verify, RTL mirrors statement/sheet. No restyling.

The throwaway `lib/preview_auth` harness has been removed.
