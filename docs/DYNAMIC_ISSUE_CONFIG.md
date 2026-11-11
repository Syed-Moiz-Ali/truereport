# Dynamic Issue & Measurement Configuration

**Purpose:** Replace free-text issue descriptions with Platform-Admin-defined structured fields. Workshop Admin and Technician can only select from predefined options; they cannot create or edit configuration.

---

## 1. Core Idea

Every inspection item has a **dynamic issue form** defined by Platform Admin.

The technician does not type “what is the issue”. Instead, the app renders the item’s configured fields:

- What is the issue? → `ISSUE_TYPE`
- Where is it? → `LOCATION`
- Which part? → `COMPONENT`
- Which side/condition? → `CONDITION`
- How much? → `MEASUREMENT` (number + unit)
- How serious? → `SEVERITY`
- What should be done? → `ACTION`
- How soon? → `URGENCY`
- Optional note → only if `allow_free_text_note` is enabled on the item

All labels, options, units, ranges, dependencies, and required rules come from Platform Admin. Every user-facing label/option is entered manually in both English and Arabic by Platform Admin; no LLM or machine translation is used in V1 (D-041).

---

## 2. Configuration Objects

### 2.1 Option set

Reusable global list. Example:

```json
{
  "code": "ISSUE_TYPE",
  "nameEn": "Issue Type",
  "nameAr": "نوع العطل",
  "status": "ACTIVE",
  "values": [
    { "code": "WORN", "labelEn": "Worn", "labelAr": "متآكل", "sortOrder": 1 },
    { "code": "CRACKED", "labelEn": "Cracked", "labelAr": "متشقق", "sortOrder": 2 },
    { "code": "LEAKING", "labelEn": "Leaking", "labelAr": "يتسرب", "sortOrder": 3 },
    { "code": "BENT", "labelEn": "Bent", "labelAr": "منحني", "sortOrder": 4 },
    { "code": "LOOSE", "labelEn": "Loose", "labelAr": "مرتخي", "sortOrder": 5 },
    { "code": "CORRODED", "labelEn": "Corroded", "labelAr": "متآكل صدئياً", "sortOrder": 6 }
  ]
}
```

### 2.2 Item issue field

A field attached to one item version.

```json
{
  "fieldCode": "ISSUE_TYPE",
  "labelEn": "Issue Type",
  "labelAr": "نوع العطل",
  "inputType": "SELECT",
  "optionSetCode": "ISSUE_TYPE",
  "required": true,
  "requiredForStatuses": ["ATTENTION_RECOMMENDED", "DEFECT_FOUND"],
  "sortOrder": 1
}
```

Number field:

```json
{
  "fieldCode": "MEASUREMENT",
  "labelEn": "Measured Value",
  "labelAr": "القيمة المقاسة",
  "inputType": "NUMBER",
  "unitSetCode": "UNIT",
  "minValue": 0,
  "maxValue": 100,
  "decimalPlaces": 1,
  "required": true,
  "requiredForStatuses": ["NO_ISSUE_OBSERVED", "ATTENTION_RECOMMENDED", "DEFECT_FOUND"],
  "sortOrder": 4
}
```

Cascading field:

```json
{
  "fieldCode": "COMPONENT",
  "labelEn": "Component",
  "labelAr": "الجزء",
  "inputType": "SELECT",
  "optionSetCode": "COMPONENT",
  "dependsOnFieldCode": "LOCATION",
  "dependsOnValueCode": "FRONT_LEFT",
  "required": true,
  "sortOrder": 3
}
```

### 2.3 Per-item option subset

If an item should only allow some values of a global set:

```json
{
  "fieldCode": "LOCATION",
  "optionSetCode": "LOCATION",
  "allowedValues": ["FRONT_LEFT", "FRONT_RIGHT", "REAR_LEFT", "REAR_RIGHT"]
}
```

If no subset is configured, all active values are allowed.

### 2.4 Measurement bands

Bands map a numeric measurement to a result and default score.

```json
{
  "fieldCode": "MEASUREMENT",
  "unitCode": "MM",
  "direction": "HIGHER_IS_BETTER",
  "bands": [
    { "minValue": 0, "maxValue": 2.99, "resultCode": "DEFECT_FOUND", "defaultScore": 0, "labelEn": "Below minimum", "labelAr": "أقل من الحد الأدنى" },
    { "minValue": 3.0, "maxValue": 5.49, "resultCode": "ATTENTION_RECOMMENDED", "defaultScore": 70, "labelEn": "Worn", "labelAr": "متآكل" },
    { "minValue": 5.5, "maxValue": 999, "resultCode": "NO_ISSUE_OBSERVED", "defaultScore": 100, "labelEn": "Within specification", "labelAr": "ضمن المواصفات" }
  ]
}
```

For items where lower is better (e.g. A/C vent temperature), use `"direction": "LOWER_IS_BETTER"` and define bands accordingly.

Validation rules:
- Bands are contiguous, non-overlapping, and cover the configured min–max.
- Every band has a canonical result code.
- Default score must be inside the item’s score band for that result.
- No gaps or overlaps.

---

## 3. Seed Option Sets

| Code | Purpose | Example values |
|---|---|---|
| `ISSUE_TYPE` | What is wrong | WORN, CRACKED, LEAKING, BENT, LOOSE, CORRODED, MISSING, NOISY, CONTAMINATED, DAMAGED, SEIZED, MISALIGNED |
| `LOCATION` | Where | FRONT_LEFT, FRONT_RIGHT, REAR_LEFT, REAR_RIGHT, FRONT, REAR, LEFT, RIGHT, UNDERBODY, ENGINE_BAY, CABIN, EXTERIOR |
| `COMPONENT` | Which part | PAD, ROTOR, CALIPER, HOSE, FLUID, BUSHING, BALL_JOINT, STRUT, SPRING, BELT, PULLEY, BATTERY, ALTERNATOR, SENSOR, LAMP, FILTER, GLASS, SEAL |
| `CONDITION` | Condition/side | INNER, OUTER, UPPER, LOWER, SURFACE, STRUCTURAL, ELECTRICAL, MECHANICAL |
| `SEVERITY` | Severity | MINOR, MODERATE, MAJOR, SAFETY_CRITICAL |
| `ACTION` | Recommended action | REPLACE, REPAIR, MONITOR, ADJUST, CLEAN, FLUSH, RECHARGE, ALIGN, CALIBRATE |
| `URGENCY` | How soon | IMMEDIATE, WITHIN_7_DAYS, NEXT_SERVICE, MONITOR |
| `CAUSE` | Likely cause | WEAR, IMPACT, CORROSION, LEAK, ELECTRICAL_FAULT, IMPROPER_REPAIR, AGE, CONTAMINATION |
| `UNIT` | Measurement units | MM, UM, V, PSI, DEG_C, PERCENT, A, CCA, RPM, NM, BAR, KM |
| `YES_NO` | Boolean choices | YES, NO |

---

## 4. Per-Item Issue Schema Examples

### 4.1 Brake pad thickness (`BRK-PAD-01`)

Fields:
1. `ISSUE_TYPE` (select, required for ATTENTION/FAIL)
2. `LOCATION` (multi-select FL/FR/RL/RR, required)
3. `COMPONENT` (select: PAD, ROTOR, CALIPER; required)
4. `MEASUREMENT` (number, unit MM, required)
5. `SEVERITY` (select, required for ATTENTION/FAIL)
6. `ACTION` (select, required for ATTENTION/FAIL)
7. `URGENCY` (select, required for ATTENTION/FAIL)
8. Optional note only if item allows it

Measurement bands: contiguous MM ranges mapping to PASS/ATTENTION/FAIL.

### 4.2 OBD scan (`OBD-SCN-01`)

Fields:
1. `ISSUE_TYPE` (select: e.g. ACTIVE_DTC, HISTORICAL_DTC, NO_FAULT)
2. `DTC_COUNT` (number, required when issue)
3. `DTC_CODE` (select from a DTC option set or text only if enabled)
4. `SEVERITY`
5. `ACTION`
6. `URGENCY`

Evidence: `DOCUMENT` required for ATTENTION/FAIL.

### 4.3 Tyre tread (`TYRE-SET-01`)

Fields:
1. `LOCATION` (multi-select: FL, FR, RL, RR)
2. `MEASUREMENT` (number, unit MM, one per corner)
3. `ISSUE_TYPE`
4. `SEVERITY`
5. `ACTION`
6. `URGENCY`

Derived item status = worst corner status. Item score = worst corner score or average, configurable by scoring rule.

### 4.4 A/C vent temperature (`INT-AC-01`)

Fields:
1. `MEASUREMENT` (number, unit DEG_C)
2. `ISSUE_TYPE`
3. `SEVERITY`
4. `ACTION`
5. `URGENCY`

Measurement direction: `LOWER_IS_BETTER`.

---

## 5. Technician Submission

The technician submits structured values, not free text.

```json
{
  "baseVersion": 7,
  "clientRevision": 12,
  "resultCode": "ATTENTION_RECOMMENDED",
  "score": 70,
  "issueValues": [
    { "fieldCode": "ISSUE_TYPE", "optionValueCode": "WORN" },
    { "fieldCode": "LOCATION", "optionValueCode": "FRONT_LEFT", "valueIndex": "FL" },
    { "fieldCode": "LOCATION", "optionValueCode": "FRONT_RIGHT", "valueIndex": "FR" },
    { "fieldCode": "COMPONENT", "optionValueCode": "PAD" },
    { "fieldCode": "MEASUREMENT", "numericValue": 4.2, "unitCode": "MM", "valueIndex": "FL" },
    { "fieldCode": "MEASUREMENT", "numericValue": 4.4, "unitCode": "MM", "valueIndex": "FR" },
    { "fieldCode": "SEVERITY", "optionValueCode": "MODERATE" },
    { "fieldCode": "ACTION", "optionValueCode": "REPLACE" },
    { "fieldCode": "URGENCY", "optionValueCode": "NEXT_SERVICE" }
  ],
  "noteEn": "",
  "noteAr": ""
}
```

`noteEn`/`noteAr` are only accepted when the item version has `allow_free_text_note = true`.

---

## 6. Server Validation

On save and complete, the server validates:

1. `resultCode` exists and is allowed for the item.
2. Every provided field exists in the item’s issue schema.
3. Required fields for the chosen status are present.
4. Option value belongs to the field’s option set, is allowed for the item, and is `ACTIVE`.
5. Dependency condition is satisfied (e.g. component allowed for the selected location).
6. Numeric value is within field min/max and decimal precision.
7. Measurement maps to a configured band; the submitted status/score matches or is an allowed override inside the band.
8. Evidence rules for the chosen status are met.
9. Note length is met if the field is required.
10. Free-text values are rejected unless the item allows them.
11. Multi-point values are complete for all required locations; worst status is derived.

Error shape:

```json
{
  "type": "about:blank",
  "title": "Validation failed",
  "status": 422,
  "code": "ITEM_VALIDATION_FAILED",
  "errors": [
    {
      "field": "MEASUREMENT",
      "code": "MEASUREMENT_BAND_MISMATCH",
      "messageEn": "4.2 mm maps to ATTENTION; submitted result was PASS.",
      "messageAr": "4.2 مم يطابق حالة الانتباه؛ النتيجة المرسلة كانت ناجحة."
    }
  ]
}
```

On `complete`, all failing items are returned at once.

---

## 7. Technician UX Flow

1. Open job → category tabs generated from the server.
2. Item card shows instructions, standard spec, tool, unit, evidence checklist.
3. Technician enters measurement / selects result.
4. If `ATTENTION` or `FAIL`, dynamic issue form appears:
   - Issue type
   - Location (cascading, multi for multi-point)
   - Component (cascading)
   - Condition
   - Measurement + unit
   - Severity
   - Action
   - Urgency
   - Optional note only if enabled
5. System derives status and score from the measurement band. The technician cannot choose a contradictory status (D-029/T2).
6. Technician may adjust the score only inside the suggested band (D-029/T3).
7. Evidence checklist shows `2/2 photos, 1/1 video, 15/15 note chars`.
8. Every item requires at least 1 photo and 1 video for every result, including PASS (D-023). FAIL requires at least 2 photos and 1 video.
9. Evidence must be captured live via camera; gallery selection is blocked (D-029/T4).
10. Video evidence is 15–30 seconds and max 50 MB, compressed before upload (D-029/T10).
11. Save is disabled until the form and evidence rules pass.
12. Autosave draft; offline queue; retry on reconnect.
13. Items can only be skipped as `NOT_APPLICABLE` with a predefined reason, no free text (D-029/T5).
14. Finalization is not allowed offline; all queued items must sync first (D-029/T6).
15. Multi-point items use the worst corner for status and score (D-029/T9).
16. Complete requires all items valid and a signature (D-029/T7).

---

## 8. Workshop Admin View

- Read-only structured findings: item, issue type, location, component, measurement, severity, action, urgency, evidence.
- Cannot edit technician selections or Platform Admin configuration.
- No return-for-correction: either approve/publish or reject and require a new inspection (D-021).
- Can approve and publish once all rules pass. Approval is Workshop-Admin-only and the approver must not be the assigned technician (D-022).
- After publish, configured report documents are generated automatically and stored; no manual document upload gate (D-024).

---

## 9. Public Report Rendering

For each finding/item, render structured fields:

- Issue type label EN/AR
- Location label EN/AR
- Component label EN/AR
- Condition label EN/AR
- Measurement value + unit
- Severity badge
- Recommended action
- Urgency
- Evidence photos/videos/documents

No hardcoded sentences. Report payload includes both languages and display labels.

Example public item payload:

```json
{
  "code": "BRK-PAD-01",
  "labelEn": "Brake Pad Thickness (All 4 Corners)",
  "labelAr": "سمك أقمشة الفرامل (جميع العجلات)",
  "result": "ATTENTION_RECOMMENDED",
  "resultLabelEn": "Attention",
  "resultLabelAr": "انتباه",
  "score": 70,
  "isSafetyCritical": true,
  "measurement": {
    "fieldCode": "MEASUREMENT",
    "value": 4.2,
    "unit": "mm",
    "display": "4.2 mm"
  },
  "issue": [
    { "fieldCode": "ISSUE_TYPE", "labelEn": "Issue Type", "labelAr": "نوع العطل", "valueCode": "WORN", "valueEn": "Worn", "valueAr": "متآكل" },
    { "fieldCode": "LOCATION", "labelEn": "Location", "labelAr": "الموقع", "valueCode": "FRONT_LEFT", "valueEn": "Front Left", "valueAr": "أمامي أيسر" },
    { "fieldCode": "COMPONENT", "labelEn": "Component", "labelAr": "الجزء", "valueCode": "PAD", "valueEn": "Brake Pad", "valueAr": "قماش الفرامل" },
    { "fieldCode": "SEVERITY", "labelEn": "Severity", "labelAr": "الخطورة", "valueCode": "MODERATE", "valueEn": "Moderate", "valueAr": "متوسط" },
    { "fieldCode": "ACTION", "labelEn": "Recommended Action", "labelAr": "الإجراء الموصى به", "valueCode": "REPLACE", "valueEn": "Replace", "valueAr": "استبدال" },
    { "fieldCode": "URGENCY", "labelEn": "Urgency", "labelAr": "الأولوية", "valueCode": "NEXT_SERVICE", "valueEn": "Next Service", "valueAr": "الخدمة القادمة" }
  ],
  "subMeasurements": [
    { "location": "FL", "value": 4.2, "unit": "mm", "result": "ATTENTION_RECOMMENDED" },
    { "location": "FR", "value": 4.4, "unit": "mm", "result": "ATTENTION_RECOMMENDED" },
    { "location": "RL", "value": 6.1, "unit": "mm", "result": "NO_ISSUE_OBSERVED" },
    { "location": "RR", "value": 6.0, "unit": "mm", "result": "NO_ISSUE_OBSERVED" }
  ],
  "media": []
}
```

---

## 10. Permissions and Immutability

- Only `PLATFORM_ADMIN` can create/edit option sets, issue fields, measurement bands.
- Workshop Admin and Technician receive read-only published/pinned schemas.
- Published item versions and their issue schemas are immutable.
- Changing an item requires a new draft version; existing jobs keep the pinned version.
- Deactivating an option set/value is blocked if referenced by an active item version; retire with replacement mapping.

---

## 11. Why This Is More Foolproof Than Free Text

- No spelling/translation variation in findings.
- Consistent public report labels in EN/AR.
- Server can validate every selection.
- Enables filtering/analytics by issue type, location, severity.
- Enables automatic severity/urgency sorting.
- Prevents technicians from inventing causes or recommendations.
- Enables workshop quality review and platform-wide trends.
- Keeps legal/report wording controlled by Platform Admin.
