# Phase 4 — Public Report

**Goal:** Render a fully dynamic, bilingual, snapshot-driven public report with no hardcoded content, plus verification, expiry, and media handling.

**Depends on:** Phase 1 config, Phase 2 publish/documents, Phase 3 assessments/evidence.

---

## 1. Scope

### Backend
- `GET /public/reports/{token}` JSON.
- Snapshot-only payload builder.
- Media endpoints (photo/video/document).
- Verification hash and page.
- Validity/expiry.
- Rate limiting, caching, security headers.
- Privacy redaction.
- EN/AR and direction.
- 404/expired/unpublished behavior.

### Frontend
- Reuse existing HTML/CSS/JS public page.
- Remove all hardcoded content.
- Render sections from API/snapshot.
- EN/AR/RTL toggle.
- Loading/404/expired/broken media/empty states.
- Accessibility, print, PDF.
- Responsive/adaptive layout (CSS).

---

## 2. Backend Deliverables

### 2.1 Public JSON API

`GET /public/reports/{token}`

Payload:
- `report`: token, issuedAt, status, validity, workshop.
- `vehicle`: make, model, year, masked VIN, masked plate, odometer, transmission, fuel.
- `customer`: name only.
- `result`: overall score, grade, labels EN/AR, counts, applied caps.
- `categories`: code, names EN/AR, score, weight, items.
- `items`: code, labels EN/AR, result, result label, score, measurement, standard spec, issue values, media, safety flag.
- `findings`: attention/fail sorted by severity/safety, urgency.
- `videos`: all video evidence with captions/duration/poster.
- `documents`: document types with EN/AR names and URLs.
- `verification`: hash, issuedAt, validUntil, workshop.
- `lang`, `dir`, `labels` where needed.

Rules:
- Built only from snapshot.
- Always both languages.
- No internal IDs, technician personal data, customer phone/email, sensor serials.
- Unknown/unpublished/revoked → same neutral 404.
- Expired → explicit expired state or neutral read-only page, configured.
- Cache-Control policy documented.
- Token path only; no tokens in logs/analytics.

### 2.2 Media

- `GET /public/reports/{token}/photo/{id}`
- `GET /public/reports/{token}/video/{id}`
- `GET /public/reports/{token}/document/{id}?lang=en|ar`
- `GET /public/reports/{token}/pdf?lang=en|ar`
- Token-scoped capability URLs; no public bucket.
- Proper content types, ranges for video, no-store/private caching.
- Broken/missing media returns safe fallback, not 500.

### 2.3 Verification/validity

- Verification page/section with hash and QR.
- `valid_until` from snapshot.
- Expired/revoked status handling.
- Hash verification uses stored snapshot hash.

### 2.4 Security

- Rate limiting with eviction and trusted proxy config.
- CSP with no unsafe-inline where possible.
- Referrer-Policy, X-Robots-Tag, X-Content-Type-Options, frame-ancestors none.
- No PII leakage in errors, logs, or payloads.
- Token hashing; constant-time comparison where applicable.

---

## 3. Frontend Deliverables

### 3.1 Reuse
- Keep existing `public-report.html`, `report.css`, `report.js`, fonts, visual design.
- Do not redesign.
- Replace hardcoded content with data from the server payload.

### 3.2 Sections
- Hero/vehicle card.
- Score ring + grade + counts + caps explanation.
- Key findings.
- Categories accordions and items.
- Photos/gallery.
- Videos (HTML5 video, poster, preload=metadata).
- Documents.
- Tyres/multi-point measurements.
- Damage map from location/measurement data (hide if unavailable).
- Verification/validity.
- Not-checked list.

### 3.3 Dynamic behavior
- Score ring from payload.
- Grade/bands from payload.
- Filters from data.
- Media galleries.
- Video dialog.
- Copy hash/share.
- Language toggle EN/AR with `dir=rtl`.
- No hardcoded category labels, scores, documents, photo totals, hotspots, or grade bands.

### 3.4 States
- Loading skeleton for client-side hydration (if used).
- 404/unavailable.
- Expired.
- Broken media fallback.
- Empty findings.
- Empty sections hidden.

### 3.5 Accessibility/responsive
- Semantic headings, alt text from captions.
- Status by text + colour.
- Keyboard navigation and focus management.
- Contrast.
- Responsive CSS: fluid grids, clamp(), minmax(), flex-wrap, no fixed widths.
- Print CSS and PDF.
- RTL layout.

---

## 4. Tests

### Backend
- JSON payload shape and both languages.
- Snapshot-only: master edits after publish do not change output.
- Unknown/unpublished/revoked → 404.
- Expired → correct state.
- Redaction: no customer phone/email, technician name, internal IDs, sensor serials.
- Media access requires valid token.
- Rate limiting and headers.
- EN/AR params.
- Document language selection.

### Frontend
- Renders entirely from payload; no hardcoded content.
- Score ring/grade/counts/caps.
- Categories/items/findings.
- Photos/videos/documents.
- EN/AR/RTL.
- 404/expired/empty/broken media.
- Print layout.
- Accessibility checks.
- Responsive at mobile/tablet/desktop.

---

## 5. Acceptance Criteria

1. Public page renders entirely from `GET /public/reports/{token}`.
2. No hardcoded categories, items, scores, grades, documents, videos, photos, or report text.
3. EN/AR with correct RTL and both-language content.
4. Grade/score/caps come from the snapshot.
5. Findings sorted by severity/safety.
6. Videos/documents link to actual stored artifacts.
7. Unknown/unpublished/revoked tokens return the same neutral 404.
8. Expired reports handled clearly.
9. No private customer/internal data exposed.
10. Broken media and empty sections handled.
11. Public report is responsive, accessible, print-friendly.
12. Tests pass.

---

## 6. Implementation Order

1. Snapshot public payload builder.
2. JSON API + media endpoints + verification/validity.
3. Security/caching/rate limiting.
4. Backend tests.
5. Replace hardcoded HTML/JS with payload rendering.
6. EN/AR/RTL + states + accessibility.
7. Responsive/print/PDF.
8. Frontend tests/browser checks.
9. Final review.
