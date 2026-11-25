# TrueReport — product brief

## What the product is

TrueReport is a vehicle-inspection platform for partner workshops. Three Flutter clients share one
Spring Boot API and one multilingual content pipeline:

| App | User | Job |
|---|---|---|
| `platform_admin_app` | Platform admin | Owns the master library (items, categories, option sets), workshops, languages and the translation desk |
| `workshop_admin_app` | Workshop admin | Creates jobs, assigns technicians, reviews submitted inspections, signs off |
| `technician_app` | Technician | Works the assigned inspection on a phone or tablet, captures evidence, submits for review |

## Who the technician is

A mechanic on a workshop floor, holding a phone in one hand next to a vehicle. Gloves, noise, poor signal,
interruptions. They are not sitting at a desk, they do not read help text, and they switch between jobs
during the day. The screen must answer three questions in under two seconds:

1. **What do I have to do now?** (which job, which vehicle, what is next)
2. **How much is left?** (items done / items total, what still blocks submission)
3. **Can I finish it here?** (photo gate, required evidence, signature, offline)

## Core jobs of the technician app

- See the assigned inspection queue for a day, and get back into unfinished work.
- Open a job, work item by item, and capture evidence (photo / video) where the item demands it.
- Track progress across categories without losing the place in the list.
- Produce the summary, collect the signature, and complete the job.
- Keep working when the connection drops and reconcile later.

## Glossary (used consistently in copy)

| Term | Meaning |
|---|---|
| Job | One vehicle inspection assignment (`JOB-…`), has a status and a schedule |
| Checklist item | One inspection point inside the job (30 per job in the seed data) |
| Category | Group of checklist items (Powertrain & Mechanical, Braking Systems & Tyres, …) |
| Evidence | Photo/video attached to an item; some items are safety-critical and require it |
| Summary | The generated report of the inspection before signature |
| Review | Workshop admin's approval step after submission |

## Module map (technician app)

| Module | Routes | Notes |
|---|---|---|
| auth | `/signin` | Technician only; help line contacts the workshop admin |
| jobs | `/jobs`, `/jobs/:id`, `/jobs/:id/items/:itemCode`, `/jobs/:id/summary`, `/jobs/:id/signature`, `/jobs/:id/completed` | **Current rebuild target** |
| profile | `/profile` | Identity, language, sign out |
| sync | `/sync`, `/sync/conflicts/:id` | Offline queue and conflict resolution |

## Why this rebuild

The job screens are visually finished but do not answer the three questions above. The list is a date
rail with an empty state; the detail is one long phone column that at tablet width becomes a phone
column with 400 px of empty space, a clipped category rail, and a sticky bar that repeats the first row.
"Current is good but there is no clarity" is a structure problem, not a paint problem.
