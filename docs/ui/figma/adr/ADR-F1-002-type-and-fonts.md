# ADR-F1-002 — Type scale and font stack

- **Status:** accepted
- **Date:** 5 November 2026
- **Phase:** F1
- **Deciders:** product owner; integration lead

## Context

The Figma exports use Plus Jakarta Sans for 1,849 of 1,876 text nodes. Plus Jakarta Sans is OFL 1.1 and covers Latin/Latin-ext only; it has no Arabic, no Cyrillic and no CJK glyphs. The only Arabic in the design is three nodes in `FreeSerif` and eight nodes tagged Plus Jakarta Sans that must have used an implicit fallback. The Flutter apps currently bundle no fonts and rely on OS fonts. The product must display Arabic, Cyrillic and Chinese names.

## Decision

1. Bundle **Plus Jakarta Sans** static weights 400, 500, 600, 700 and 800 for Latin/Latin-ext.
2. Bundle **Noto Sans Arabic** and **IBM Plex Sans Arabic** as Arabic candidates. The gallery shows both; the native reviewer chooses later. The first default is Noto Sans Arabic.
3. Bundle **Noto Sans SC** for the `zh-Hans` locale only. It is large; the size impact is recorded and it is not used for other locales.
4. Bundle **Noto Sans Regular** as the Cyrillic (and general non-Latin) fallback.
5. No runtime font downloads and no `google_fonts` fetch.
6. Minimum text sizes: labels 12 px, body 14 px, technician body 16 px. No 11 px text.
7. Arabic text must not be letter-spaced. The theme exposes an Arabic-aware build path and the gallery tests RTL.
8. All font files ship with their licence notices; sources and versions are recorded in `fonts-and-licences-final.md`.

## Consequences

- The app asset size increases. The exact size is measured after bundling; Noto Sans SC is the dominant cost.
- Font families must be declared in `client/packages/design_system/pubspec.yaml`.
- The public report/PDF already use Noto Sans/Naskh Arabic/SC; the app and HTML font stacks must be documented together.
- A native Arabic reviewer is still required; this ADR does not claim native approval.

## Rejected alternatives

- **Plus Jakarta Sans alone:** cannot render Arabic, Cyrillic or CJK.
- **FreeSerif for Arabic:** wrong style, GPL implications, and not the design's intended face.
- **Runtime Google Fonts:** prohibited by the offline requirement.
