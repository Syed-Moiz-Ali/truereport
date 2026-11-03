# ADR-0012: Localization, RTL and numeral defaults

- **Status:** Partially accepted: `zh-Hans` approved 3 November 2026; numeral default still Pending
- **Date:** 3 November 2026
- **Owner:** Product + design + Arabic reviewer

## Context

English and Arabic launch with genuine RTL; Russian and Chinese data entry must work before their interfaces are translated. Mixing scripts, digits, VINs and technical identifiers creates bidi errors. The OS controls the keyboard, so automatic keyboard switching cannot be promised.

## Options

1. One global direction inferred from app language for all fields (rejected — wrong for mixed data).
2. **Three separate settings: app language, per-field direction, report language** (chosen).
3. Arabic-Indic digits everywhere (rejected for identifiers/measurements).
4. Western digits for technical values, localized prose later (chosen).

## Decision

- Separate app language, per-field entry direction and report language.
- Use logical `start/end`; ban hardcoded left/right in feature code.
- Technical identifiers (VIN, plate, phone, email, report ID, dates, measurements) are **LTR isolates** and use **Western digits 0–9**.
- Names and notes preserve the exact entered script; optional direction toggle; no transliteration.
- Arabic/English required to publish master content; RU/ZH optional until their UI launches.
- Bundle fonts; no runtime font fetch for public report/PDF.
- The OS controls the keyboard; show help, do not build a custom keyboard.
- Native Arabic review is required before launch.

## Consequences

- More work per field, but correct mixed data.
- Western digits may be less “localized” for some Arabic readers; this is a deliberate readability/safety trade-off and is Pending confirmation.
- Font licensing and CJK size need Phase 2 work.
- Arabic review is a schedule dependency.

## Follow-ups

- Product owner confirms the numeral default.
- Native Arabic reviewer and automotive specialist approve glossary/wording.
- Golden tests EN/AR and mixed-direction unit tests.
- Real-device keyboard tests.
- Font licence verification.

## What was not proven

No native Arabic review, real-device keyboard test or font licence check was completed in Phase 1. The numeral preference is not user-tested.

