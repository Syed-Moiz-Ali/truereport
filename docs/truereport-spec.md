# TrueReport™ Complete Vehicle Inspection Checklist & Technician Assessment Specification

## Executive Overview

In the TrueReport vehicle certification platform, every data point displayed on the **Public Inspection Report** (`/report/:token` or `/r/:id`) originates from the rigorous, item-by-item physical inspection performed by the **Certified Technician**.

Every checklist item must be evaluated across **5 mandatory dimensions**:
1. **Inspection Status**: `PASS` (`NO_ISSUE_OBSERVED`), `ATTENTION` (`ATTENTION_RECOMMENDED`), or `FAIL` (`DEFECT_FOUND`).
2. **Item Score**: Numerical rating from `0` to `100` based on standardized physical thresholds.
3. **Diagnostic Metric**: Quantitative sensor/tool measurement (e.g. Paint depth in $\mu\text{m}$, Pad thickness in $\text{mm}$, Battery CCA in $\text{A}$, Voltage in $\text{V}$, OBD-II DTCs).
4. **Mandatory Technician Notes**: Qualitative professional observation in bilingual text (`en` & `ar`).
5. **Mandatory Digital Evidence**: High-resolution photos and HD/4K video clips proving the finding.

---

## 1. Complete Category & Item Checklist Matrix

The platform standardizes vehicles into **6 Master Inspection Categories** comprising **30 granular items**. Each item directly generates the cards, score bars, defect chips, and media galleries in the public report.

```
                    ┌────────────────────────────────────────────────────────┐
                    │            TrueReport™ Master Inspection Tree          │
                    └───────────────────────────┬────────────────────────────┘
         ┌───────────────┬──────────────────────┼─────────────────────┬────────────────┐
         ▼               ▼                      ▼                     ▼                ▼
   1. Powertrain   2. Suspension &        3. Brakes &           4. Electrical    5. Body, Glass   6. Road Test &
   & Mechanical      Underbody              Tyres                 & Battery        & Interior        Dynamics
    (6 items)        (5 items)              (5 items)             (5 items)        (5 items)         (4 items)
```

---

### Category 1: Powertrain & Mechanical (`POWERTRAIN_MECHANICAL`)
*Weight in Overall Score: 25% | Category Code: `CAT-ENG`*

| Code | Item Name (EN / AR) | Tool / Sensor | Standard Spec | PASS (85–100) | ATTENTION (60–84) | FAIL (0–59) | Mandatory Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ENG-OIL-01` | **Engine Oil Condition & Level**<br>*حالة ومستوى زيت المحرك* | Optical Refractometer / Dipstick | Oil level between MIN/MAX; amber/brown color; normal viscosity | Clean, translucent amber, proper level (100) | Darkened oil, near service interval or slightly low (70) | Sludge buildup, fuel contamination, milky oil (coolant leak), below MIN (20) | Photo of dipstick & oil cap; Video of engine running |
| `ENG-FLT-01` | **Engine Air Filter & Intake System**<br>*فلتر هواء المحرك ونظام السحب* | Visual / Airflow Gauge | Clean filter pleats; intact housing seals; clean MAF housing | White/cream filter element, zero debris (100) | Moderate dust buildup, replacement advised next service (75) | Heavily clogged, torn element, oil blowback in intake (30) | Macro photo of filter pleats |
| `TRN-FLU-01` | **Transmission Fluid & Drivetrain Health**<br>*سائل ناقل الحركة ونظام الدفع* | Dipstick / Sight Tube / Diagnostic Temp | Pink/red or clear fluid; no burnt odor; no gear shudder | Clean fluid at correct temp, smooth shift engagement (95) | Darkened fluid, slight oxidation, deferred maintenance (70) | Black/burnt fluid, metallic shavings on magnet, slipping gears (25) | Photo of fluid droplet on white paper; Video of gear shifts |
| `ENG-CLT-01` | **Cooling System, Radiator & Hoses**<br>*نظام التبريد والرادياتير والخراطيم* | Refractometer & Pressure Tester (15 psi) | Coolant freeze point $< -35^\circ\text{C}$, holds 15 psi for 5 min | Holds pressure, clean coolant, flexible hoses (100) | Slight external crusting at clamp, coolant age > 3 yrs (75) | Active coolant leak, blown radiator tank, collapsing hoses (10) | Photo of pressure gauge reading; Video of radiator neck |
| `ENG-BEL-01` | **Drive Belts, Pulleys & Tensioners**<br>*سيور المحرك والبكرات والشدادات* | Belt Wear Gauge & Stethoscope | $< 1\text{ crack per inch}$, no pulley chirp, tensioner aligned | Zero cracks, quiet idler pulleys, proper belt deflection (100) | Hairline micro-cracks on ribs, mild surface glazing (65) | Deep transverse cracks, chunking, pulley bearing whine (20) | Photo of belt underside; Video of spinning pulley with audio |
| `ENG-EXH-01` | **Exhaust System, Catalytic Converter & Emissions**<br>*نظام العادم والمحول الحفاز والانبعاثات* | Underbody Inspection & Thermal Gun | No exhaust leaks; catalyst delta-temp $> 50^\circ\text{C}$; clean tailpipe | Sealed joints, no soot leaks, normal tailpipe emissions (100) | Minor surface rust on resonator, hanger rubber aging (80) | Catalyst bypass/hollowed, perforated muffler, carbon black soot leak (0) | Photo of exhaust pipe & weld seams |

---

### Category 2: Suspension, Steering & Underbody (`SUSPENSION_STEERING`)
*Weight in Overall Score: 18% | Category Code: `CAT-SUS`*

| Code | Item Name (EN / AR) | Tool / Sensor | Standard Spec | PASS (85–100) | ATTENTION (60–84) | FAIL (0–59) | Mandatory Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `SUS-FRT-01` | **Front Shocks, Struts & Springs**<br>*المساعدات الأمامية واليايات* | Pry Bar & Hydraulic Bounce Tester | No hydraulic oil weeping; rebound dampens in 1.5 cycles; unbroken coil | Dry strut body, pristine bump stop, firm rebound (100) | Minor oil misting (sweating) without droplet accumulation (75) | Active hydraulic oil leak, broken spring coil, failed top mount (15) | Photo of strut tube & spring perch |
| `SUS-REA-01` | **Rear Dampers & Linkages**<br>*المساعدات الخلفية والوصلات* | Pry Bar & Visual Check | Bushings intact; no clunking; symmetrical ride height $\pm 5\text{mm}$ | Bushings supple, dampers dry, ride height balanced (100) | Minor rubber micro-cracking in non-critical subframe bushing (80) | Blown damper, torn multi-link rubber bushing, metal-on-metal play (20) | Photo of rear axle mounts |
| `STR-RCK-01` | **Steering Rack, Tie Rods & Boots**<br>*علبة الدركسون ومسامير التوجيه* | Dial Indicator & Manual Play Check | Inner/outer tie rod play $< 0.5\text{mm}$; boots sealed; electric power assist normal | Zero play, supple rubber bellows, silent steering lock-to-lock (98) | Slight sweat on rack end seals, surface corrosion on tie rod (75) | Torn steering boot, loose tie rod end, power steering fluid leak (10) | Photo of rack boots & outer ball joint; Video turning steering |
| `SUS-CTL-01` | **Control Arms & Ball Joints**<br>*أذرعة التحكم والركب* | Heavy-Duty Ball Joint Gauge & Pry Bar | Joint axial/radial play $< 1.0\text{mm}$; rubber boots intact | Tight ball joints, zero rubber extrusion on control arm bushings (100) | Minor hairline dry rot on outer edge of lower arm bushing (75) | Torn ball joint boot, excessive wheel wiggle (12-to-6 o'clock) (10) | Photo of lower ball joint boot |
| `BOD-UND-01` | **Chassis Rails, Subframe & Floor Pan**<br>*شاسيه السيارة والهيكل السفلي* | Ultrasonic Thickness / High-Lumen Inspection | Zero structural deformation, no frame straightening marks, factory pinch welds | Factory seam sealer intact, pristine crossmembers (100) | Minor plastic underbody undertray scrape, light splash shield crack (85) | Cracked subframe, kinked chassis rail, structural weld repairs, rust perforation (0) | Photo of front/rear frame rails; Video pan of full underbody |

---

### Category 3: Braking Systems & Tyres (`BRAKES_TYRES`)
*Weight in Overall Score: 20% | Category Code: `CAT-BRK`*

| Code | Item Name (EN / AR) | Tool / Sensor | Standard Spec | PASS (85–100) | ATTENTION (60–84) | FAIL (0–59) | Mandatory Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `BRK-PAD-01` | **Brake Pad Thickness (All 4 Corners)**<br>*سمك أقمشة الفرامل (جميع العجلات)* | Digital Vernier Brake Gauge | Friction material $> 3.0\text{mm}$ ($> 25\%$ remaining) | $\ge 7.0\text{mm}$ ($> 70\%$ life) (100) | $3.5\text{mm} - 6.5\text{mm}$ (30-60% life remaining) (70) | $< 3.0\text{mm}$ or backing plate contact (0) | Macro photo of pad gauge against friction material for all 4 corners |
| `BRK-ROT-01` | **Brake Disc Rotors & Runout**<br>*هوبات الفرامل ونسبة الاستواء* | Micrometer & Dial Indicator | Above MIN THICKNESS stamp; lateral runout $< 0.05\text{mm}$ | Smooth surface, no lip, thickness well above minimum (100) | Light surface grooving, small lip at edge but within thickness limits (75) | Below minimum stamped thickness, warped (pulsing), heavy heat cracks (10) | Photo of micrometer measuring rotor thickness |
| `BRK-HYD-01` | **Brake Fluid Moisture & Hydraulic Lines**<br>*سائل الفرامل ونظام الليات* | Digital Boiling Point / Moisture Pen | Fluid moisture $< 2.0\%$; steel lines free of rust; flexible hoses dry | Fluid moisture $< 1\%$, lines clean and dry (100) | Fluid moisture $2\% - 3\%$ (flush recommended) (70) | Fluid moisture $> 3\%$ or cracked flexible rubber brake hose (0) | Photo of moisture tester display in brake reservoir |
| `TYRE-SET-01` | **Tyre Tread Depth (FL, FR, RL, RR)**<br>*عمق مداس الإطارات (الأربعة)* | Digital Tyre Tread Depth Gauge | Legal minimum $> 1.6\text{mm}$; recommended replacement $< 3.0\text{mm}$ | $> 5.5\text{mm}$ on all four tyres (95) | $3.0\text{mm} - 5.0\text{mm}$ (moderate wear, uniform) (70) | $< 2.0\text{mm}$, bald shoulders, camber wear down to cord (0) | Photo of depth gauge on each tyre |
| `TYRE-CND-01` | **Tyre Age (DOT), Sidewall & Structural Integrity**<br>*عمر الإطارات والهيكل الخارجي* | Visual DOT Stamp & Sidewall Inspection | Age $< 5\text{ years}$ (Saudi SASO / GCC standard $< 2\text{ yrs}$); zero sidewall bulges | Same brand/model across axle, DOT $< 2\text{ yrs}$, pristine rubber (100) | DOT 3–4 years old, minor rubber crazing, no cords exposed (70) | Sidewall bubble/hernia, cut through casing, DOT $> 5\text{ yrs}$ (0) | Macro photo of DOT date code & sidewall condition |

---

### Category 4: Electrical, Battery & Diagnostics (`ELECTRICAL_BATTERY`)
*Weight in Overall Score: 17% | Category Code: `CAT-ELE`*

| Code | Item Name (EN / AR) | Tool / Sensor | Standard Spec | PASS (85–100) | ATTENTION (60–84) | FAIL (0–59) | Mandatory Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ELE-BAT-01` | **12V / High Voltage Battery Health & CCA**<br>*فحص بطارية 12 فولت / البطارية الهجينة* | Digital Battery Conductance Analyzer | State of Health $(\text{SOH}) \ge 80\%$; Voltage $\ge 12.6\text{V}$ rest; CCA $\ge 80\%$ rated | $\text{SOH} \ge 85\%$, $\text{SOC} \ge 85\%$, CCA in spec (100) | $\text{SOH } 70\% - 84\%$, moderate terminal corrosion (72) | $\text{SOH} < 60\%$, bad cell, swollen battery case (15) | Photo of battery analyzer receipt/screen with CCA & SOH % |
| `ELE-ALT-01` | **Alternator Charging Voltage & Diode Ripple**<br>*جهد شحن الدينامو واختبار الريبل* | Digital Multimeter / Oscilloscope | Idle charging $13.8\text{V} - 14.5\text{V}$; under load $\ge 13.5\text{V}$; ripple $< 0.5\text{V}$ | $14.1\text{V} - 14.4\text{V}$ stable with lights/AC on (100) | Slight voltage sag to $13.3\text{V}$ under full electrical load (75) | Charging $< 13.0\text{V}$ or overcharging $> 15.2\text{V}$ (diode failure) (0) | Photo of multimeter display across terminals at 2000 RPM |
| `OBD-SCN-01` | **Diagnostic Trouble Codes (OBD-II ECU Full Scan)**<br>*فحص كمبيوتر السيارة وأعطال المحرك* | Professional OBD-II Bi-Directional Scanner | 0 Active / Pending DTCs in Powertrain (P), Chassis (C), Body (B), Network (U) | Zero DTCs across all 32 ECUs; all readiness monitors set (100) | Historical non-critical codes (e.g. low key fob battery, radio memory) (80) | Active engine misfire, transmission slipping, SRS airbag faults (0) | Screenshot/PDF of full diagnostic ECU scan report |
| `ELE-LGT-01` | **Exterior & Interior Lighting Systems**<br>*الإضاءة الخارجية والداخلية* | Visual & Lux Meter | High/low beams, indicators, brake lights, reverse, DRL, ambient | 100% LED / bulb function, correct beam aiming, clear lenses (100) | One license plate bulb out, minor headlight lens haze (80) | Headlight inoperative, brake lights not triggering, smashed lens (20) | Video walk-around showing all lights cycling |
| `ELE-INF-01` | **Infotainment, Cameras, Radar & ADAS Sensors**<br>*الشاشات والكاميرات وحساسات الرادار* | Functional Testing & On-Screen Calibration | 360 camera active; parking sensors trigger; touchscreen responsive | All touch controls, cameras, radar cruise, lane keep functional (100) | Touchscreen sluggish, minor parking sensor intermittent chirp (75) | Blank navigation screen, ADAS camera fault, radar sensor blind (20) | Video demonstrating 360-degree reverse camera display |

---

### Category 5: Body, Glass & Interior (`BODY_INTERIOR`)
*Weight in Overall Score: 10% | Category Code: `CAT-BOD`*

| Code | Item Name (EN / AR) | Tool / Sensor | Standard Spec | PASS (85–100) | ATTENTION (60–84) | FAIL (0–59) | Mandatory Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `BOD-PNT-01` | **Paint Thickness & Body Panel Integrity**<br>*سماكة دهان الهيكل وسلامة الألواح* | Magnetic/Eddy Current Coating Thickness Gauge | Factory paint: $90\mu\text{m} - 150\mu\text{m}$; uniform readings across all 13 panels | All panels within factory spec ($100 - 135\mu\text{m}$), zero body filler (98) | Repainted panel (cosmetic clearcoat $160 - 240\mu\text{m}$) without filler (75) | Heavy body filler (bondo) $> 400\mu\text{m}$, misaligned panels, overspray (20) | Photo of digital paint gauge on measured panel |
| `BOD-GLS-01` | **Windshield, Windows & Mirror Glass**<br>*الزجاج الأمامي والنوافذ والمرايا* | Visual & Defroster Grid Tester | Zero cracks in driver's line of sight; OEM glass stamps match | Pristine glass, no chips, all power windows operate smoothly (100) | Bullseye stone chip $< 10\text{mm}$ outside driver wiper sweep (75) | Cracked windshield spreading across glass, non-functional window regulator (15) | Macro photo of glass chip or defect |
| `INT-AC-01` | **Air Conditioning & Climate Performance**<br>*أداء نظام التكييف والتحكم بالمناخ* | Digital Thermocouple / Anemometer | Vent temp $\le 7.0^\circ\text{C}$ after 5 mins; all actuators direct airflow | Rapid cooling to $5.5^\circ\text{C}$, strong blower, odorless cabin (100) | Cooling vent temp $9.0^\circ\text{C} - 11.0^\circ\text{C}$, slight cabin filter odor (70) | AC blows ambient/warm air ($> 16^\circ\text{C}$), blend door click/stuck (10) | Photo of digital thermometer probe inserted in central vent |
| `INT-SFT-01` | **Seat Belts, Airbags & Restraint Systems**<br>*أحزمة الأمان والوسائد الهوائية* | Belt Retraction Tester & OBD SRS Status | Belts lock on yank; pretensioners active; airbag covers uncut | Smooth retraction, clean webbing, zero SRS indicator lights (100) | Slow belt retraction on rear passenger belt (75) | Cut seat belt webbing, deployed/tampered airbag cover, airbag warning light (0) | Photo of seatbelt tags and buckle latching |
| `INT-ROF-01` | **Sunroof, Weatherstripping & Cabin Seals**<br>*فتحة السقف والعوازل المطاطية للكبينة* | Water Spray Test & Visual Drain Check | Seals supple; drains unclogged; sunroof glides without motor strain | Silent sunroof operation, zero moisture stains on headliner (100) | Slow sunroof track movement (grease dried), minor wind noise at highway speed (75) | Sunroof leaks water into cabin, soaked carpet, seized sunroof track (20) | Video of sunroof opening/closing; Photo of headliner |

---

### Category 6: Road Test & Dynamic Performance (`ROAD_TEST_DYNAMIC`)
*Weight in Overall Score: 10% | Category Code: `CAT-ROA`*

| Code | Item Name (EN / AR) | Tool / Sensor | Standard Spec | PASS (85–100) | ATTENTION (60–84) | FAIL (0–59) | Mandatory Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ROA-STR-01` | **Cold Start, Cranking & Idle Smoothness**<br>*التشغيل على البارد وانتظام دوران المحرك* | Engine RPM Log / Vibration Sensor | Quick start $< 1.5\text{s}$; smooth idle $650 - 750\text{ RPM}$; no smoke | Instant crank, whisper-quiet idle, zero exhaust smoke (100) | Slight extended crank (2-3 sec), minor vibration until engine warm (75) | Rough idle / misfire, severe engine shake, blue/white oil smoke (15) | Video of instrument cluster during engine cold start |
| `ROA-TRN-01` | **Transmission Shift Quality & Clutch Engagement**<br>*سلاسة تبديلات القير واستجابة الكلتش* | Road Acceleration Test | Smooth upshifts/downshifts; no flare; instant torque delivery | Seamless gear shifts, immediate kickdown response (100) | Mild shift hesitation or minor bump when selecting Reverse (70) | Severe transmission slip, delayed gear engagement ($> 2\text{s}$), metallic clunk (0) | Video showing speedometer & tachometer during 0-80 km/h acceleration |
| `ROA-ALN-01` | **Steering Centering, Straight-Line Tracking & Drift**<br>*استقامة المقود وثبات المسار* | Road Test at $80\text{ km/h}$ on Flat Surface | Vehicle tracks straight for $100\text{m}$ hands-off; steering wheel level | Dead-center steering wheel, true straight tracking (100) | Slight pull to right/left after 50m (wheel alignment required) (70) | Violent vehicle drift, off-center steering wheel by $> 15^\circ$, high-speed wobble (10) | Video of steering wheel centered while car is in motion |
| `ROA-BRK-01` | **Dynamic Emergency Braking & ABS Cycling**<br>*الفرملة الطارئة وتفعيل مانع الانغلاق ABS* | Deceleration Test at $60\text{ km/h}$ | Straight-line stop, no pedal pulsation under normal braking, ABS pulses on threshold | Firm pedal feel, rapid stop with zero pull or abnormal noise (100) | Minor steering vibration under high-speed braking (warped front rotor) (70) | Spongy pedal sinking to floor, severe pull across lane markings, ABS fault (0) | Video of high-speed deceleration stop |

---

## 2. Mandatory Technician Evaluation Schema

For **every single item** listed above, the technician’s device submits the following JSON payload into the inspection job:

```json
{
  "itemCode": "BRK-PAD-01",
  "categoryCode": "CAT-BRK",
  "resultCode": "ATTENTION_RECOMMENDED",
  "score": 75,
  "diagnosticMetric": "4.2mm (25% remaining)",
  "standardSpec": "> 3.0mm friction lining",
  "sensorDeviceUsed": "Digital Vernier Caliper (Mitutoyo Cal-99)",
  "technicianNotesEn": "Front brake pads measured at 4.2mm friction lining remaining. While safe for immediate driving, replacement is recommended within next 5,000 km.",
  "technicianNotesAr": "تم قياس سمك بطانات الفرامل الأمامية بـ 4.2 مم متبقية. على الرغم من أنها آمنة للقيادة الفورية، يوصى باستبدالها خلال الـ 5000 كم القادمة.",
  "mediaEvidence": [
    {
      "mediaType": "PHOTO",
      "captionEn": "Digital Caliper Measurement - Front Left Inner Pad",
      "captionAr": "قياس الفرجار الرقمي - قماش الفرامل الأمامي الداخلي",
      "storageUrl": "/reports/assets/evidence/job_1029_brk_pad_01.jpg",
      "thumbnailUrl": "/reports/assets/evidence/job_1029_brk_pad_01_thumb.jpg",
      "timestamp": "2026-11-11T14:22:10Z"
    },
    {
      "mediaType": "VIDEO",
      "captionEn": "Brake Rotor Lip & Pad Assembly Inspection",
      "captionAr": "فحص حافة هوب الفرامل وتجميع الأقمشة",
      "storageUrl": "/reports/assets/video/job_1029_brk_rotor_spin.mp4",
      "durationSeconds": 18,
      "thumbnailUrl": "/reports/assets/evidence/video_thumb_01.jpg",
      "timestamp": "2026-11-11T14:22:45Z"
    }
  ]
}
```

### Validation Rules Enforced by Backend:
1. **No Blank Decisions**: Submitting without a `resultCode` (`PASS`, `ATTENTION`, `FAIL`) is rejected (`422 Unprocessable Entity`).
2. **Mandatory Evidence on Defect/Attention**:
   - If `resultCode == 'ATTENTION_RECOMMENDED'`, at least **1 photo** is strictly required.
   - If `resultCode == 'DEFECT_FOUND'`, at least **2 photos** AND **1 video** are strictly required before the item can be saved.
3. **Mandatory Comment Length**:
   - Minimum 15 characters of notes explaining why an item is marked `ATTENTION` or `FAIL`.

---

## 3. The 3 System Roles & Data Flow

```
┌─────────────────────────────────┐
│     1. PLATFORM ADMIN           │
│  - Master Categories & Items    │
│  - Severity Scoring Weights     │
│  - Grade Boundaries (A, B, C, D)│
└────────────────┬────────────────┘
                 │ Configures System Standard
                 ▼
┌─────────────────────────────────┐
│     2. WORKSHOP ADMIN           │
│  - Creates Vehicle Job          │
│  - Selects Template (Full/Basic)│
│  - Assigns Certified Technician │
└────────────────┬────────────────┘
                 │ Dispatches Job
                 ▼
┌─────────────────────────────────┐
│     3. CERTIFIED TECHNICIAN     │
│  - Conducts 30-Point Inspection │
│  - Records Measurements & Notes │
│  - Captures Photos & Videos     │
│  - Submits Completed Checklist  │
└────────────────┬────────────────┘
                 │ Final Signoff & Publication
                 ▼
┌────────────────────────────────────────────────────────┐
│             PUBLIC INSPECTION REPORT                   │
│   (Score: 94%, Grade: A, Checklist, Videos, Docs)      │
└────────────────────────────────────────────────────────┘
```

### Role 1: Platform Admin
- **Primary Responsibility**: System-wide governance, data dictionary, standard templates, scoring engine rules.
- **Key Master Tables Managed**:
  - `master_categories`: Defines codes, names (EN/AR), order index, default percentage weight.
  - `master_checklist_items`: Defines 30 standard items, testing procedures, metric units, tool requirements.
  - `scoring_rules`: Defines mathematical weightings and hard-fail caps (e.g., if a safety-critical item like `BOD-UND-01` or `BRK-HYD-01` fails, the vehicle cannot receive Grade `A`).

### Role 2: Workshop Admin / Manager
- **Primary Responsibility**: Operational booking, job intake, technician assignment, quality assurance.
- **Workflow**:
  1. Creates an **Inspection Job** by entering:
     - Customer Details (Name, Phone, Email).
     - Vehicle Information (VIN, Make, Model, Year, Plate Number, Odometer, Transmission, Fuel Type).
  2. Selects the Checklist Template (e.g. `Comprehensive 30-Point GCC Standard`).
  3. Assigns the job to a certified Technician on duty.
  4. Once the technician completes inspection, reviews findings, generates the 5 supplementary documents (Battery Test, Brake Test, Road Test, Tyre Alignment, Electrical Diagnostic), and clicks **"Approve & Issue Certificate"**.

### Role 3: Certified Technician
- **Primary Responsibility**: Physical hands-on inspection, measurement recording, photographic/video proof.
- **Workflow**:
  1. Opens tablet/mobile inspection web app (`/app/technician/jobs/:id`).
  2. Walks through the 6 category tabs sequentially.
  3. For every item:
     - Enters measured value (e.g., `4.2mm`, `125 µm`, `14.2 V`).
     - Toggles result: `PASS`, `ATTENTION`, or `FAIL`.
     - System automatically suggests score based on standard brackets (editable by technician).
     - Types or voice-transcribes observation notes in Arabic or English.
     - Captures live photos/videos through the app camera interface.
  4. Reviews summary score card.
  5. Signs off with digital signature and clicks **"Complete Physical Assessment"**.

---

## 4. Database Schema for APIs & UI Implementation

To implement the backend APIs and UI screens, use the following production-ready relational schema:

```sql
-- 1. Master Checklist Categories
CREATE TABLE master_categories (
    category_id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name_en VARCHAR(150) NOT NULL,
    name_ar VARCHAR(150) NOT NULL,
    weight_percentage DECIMAL(5,2) NOT NULL DEFAULT 16.66,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Master Checklist Items
CREATE TABLE master_checklist_items (
    item_id VARCHAR(36) PRIMARY KEY,
    category_id VARCHAR(36) NOT NULL,
    stable_code VARCHAR(50) NOT NULL UNIQUE,
    label_en VARCHAR(200) NOT NULL,
    label_ar VARCHAR(200) NOT NULL,
    instruction_en TEXT,
    instruction_ar TEXT,
    measurement_unit VARCHAR(30), -- 'mm', 'um', 'V', 'PSI', 'deg_C', 'SOH_%'
    sensor_tool VARCHAR(100),
    is_safety_critical BOOLEAN DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES master_categories(category_id)
);

-- 3. Vehicle Inspection Jobs
CREATE TABLE inspection_jobs (
    job_id VARCHAR(36) PRIMARY KEY,
    workshop_id VARCHAR(36) NOT NULL,
    technician_id VARCHAR(36) NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    client_phone VARCHAR(50),
    client_email VARCHAR(100),
    vin VARCHAR(50) NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    odometer INT NOT NULL,
    plate_number VARCHAR(30),
    status ENUM('DRAFT', 'IN_PROGRESS', 'PENDING_REVIEW', 'APPROVED', 'PUBLISHED') DEFAULT 'DRAFT',
    overall_score INT DEFAULT 0,
    overall_grade VARCHAR(5) DEFAULT 'N/A',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Item Assessment Results (Completed by Technician)
CREATE TABLE job_item_assessments (
    assessment_id VARCHAR(36) PRIMARY KEY,
    job_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(36) NOT NULL,
    result_code ENUM('NO_ISSUE_OBSERVED', 'ATTENTION_RECOMMENDED', 'DEFECT_FOUND') NOT NULL,
    score INT NOT NULL CHECK (score BETWEEN 0 AND 100),
    diagnostic_metric VARCHAR(100),
    sensor_device VARCHAR(100),
    notes_en TEXT,
    notes_ar TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES inspection_jobs(job_id),
    FOREIGN KEY (item_id) REFERENCES master_checklist_items(item_id),
    UNIQUE KEY uk_job_item (job_id, item_id)
);

-- 5. Photographic & Video Evidence
CREATE TABLE job_assessment_evidence (
    evidence_id VARCHAR(36) PRIMARY KEY,
    assessment_id VARCHAR(36) NOT NULL,
    media_type ENUM('PHOTO', 'VIDEO', 'DOCUMENT') NOT NULL,
    caption_en VARCHAR(255),
    caption_ar VARCHAR(255),
    file_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    duration_seconds INT DEFAULT 0,
    file_size_bytes BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assessment_id) REFERENCES job_item_assessments(assessment_id)
);
```

---

## 5. Direct Mapping to the Public Inspection Report

The data entered by the Technician directly maps to each section of the Public Report:

1. **Hero Header & Score Ring**:
   - `overall_score` (e.g. `94`) $\rightarrow$ Rendered inside circular SVG ring with grade letter `A`.
   - Category rollup counts (`PASSED: 26`, `ATTENTION: 3`, `DEFECTS: 1`) $\rightarrow$ Calculated dynamically from `job_item_assessments`.
2. **Customer Details Card**:
   - Customer Name (`client_name`), VIN, Make/Model, Plate Number, Mileage $\rightarrow$ Rendered in the top customer & vehicle grid.
3. **Category Breakdown Accordions (`#categories`)**:
   - Groups items by `category_id`.
   - Displays category score bar (e.g., `Braking: 89%`, `Powertrain: 96%`).
   - Renders each item with its status chip (`PASS`, `ATTENTION`, `DEFECT`), numeric score, sensor metric, and bilingual technician comment.
4. **Key Findings / Defects (`#findings`)**:
   - Queries all items with `result_code IN ('ATTENTION_RECOMMENDED', 'DEFECT_FOUND')`.
   - Highlights them at the top of the report with severity pills and estimated maintenance urgency.
5. **Certified Inspection Videos (`#videos`)**:
   - Pulls all records from `job_assessment_evidence` where `media_type = 'VIDEO'`.
   - Renders HTML5 video cards with bilingual titles, duration tags, and technician commentary.
6. **Download Center Documents (`#documents`)**:
   - Provides one-click access to the 5 diagnostic reports:
     - `Electrical Diagnostics Report`
     - `Battery Health & Conductance Test`
     - `Pre-Test Drive Inspection`
     - `Post-Road Test Performance`
     - `Tyre Alignment & Laser Wear Analysis`
