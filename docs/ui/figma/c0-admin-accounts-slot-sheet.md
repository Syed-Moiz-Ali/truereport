# C0 Admin accounts slot sheet — Figma "Add Staff / Create Account" coverage

**Project:** TrueReport
**Phase:** C0 Workstream A (admin_ui-engineer)
**Date:** 6 November 2026
**Figma source:** `docs/ui/figma-export/platform_admin_figma/screens/02_2._Add_Staff_-_Create_Account/`
**Rule applied:** implement the Figma Add Staff / Create Account fields where a
server counterpart exists; everything else is listed below as unsupported.
ARB set is fixed, so only existing keys are used (no new strings).

Legend: **done** = implemented in this workstream, **partial** = same slot with
a narrower scope than Figma, **not supported** = Figma element with no
counterpart (reason given, owner decision needed where marked).

| Figma element | Status | Implementation / gap |
|---|---|---|
| `FULL NAME` (e.g. Marcus Vance) | done | `displayName` field in both dialogs (`AppTextField`, required). |
| `EMAIL ADDRESS` | done | `email` field in both dialogs (required, `@` check; server normalizes + enforces `EMAIL_EXISTS`). |
| `TEMPORARY PASSWORD` (Precision-Auth-2024) | done | `temporaryPassword` field in both create dialogs; reused as the `newPassword` field in both reset-password dialogs (ARB-fixed, no new key). Server `PasswordPolicy` requires 12–128 chars; client validates required + min length 12. |
| `ASSIGN ROLE` picker | partial | Platform dialog: fixed to Workshop Admin (no picker). Server returns `ROLE_NOT_PERMITTED` for any other role on `POST /api/v1/platform/users` (strict chain A1). Workshop dialog: fixed to Technician (no picker, role row only). |
| `ASSIGN WORKSHOP` picker | partial | Platform dialog: workshop is the card the dialog opened from (shown as `role · workshop: name`, not editable). No cross-workshop picker in this minimal build. Workshop dialog: no workshop field at all — the server derives the workshop from the caller on `POST /api/v1/workshop/technicians` (strict chain A2). |
| Invitation action + token display (`Invite`, `Invitation token`, `Pending invitations`, pending filter) | not supported | Invitation flow removed: no invite button/dialog, no `PENDING` filter chip, no pending-invitation section. Client no longer calls `POST /api/v1/platform/invitations` (`platformInvitations` getter kept unused for contract stability). **Owner to confirm invitations stay out.** |
| Free workshop dropdown (pick any workshop in the dialog) | not supported | Minimal build only; a searchable workshop picker would need design + a11y review. Current card-context assignment covers the Platform Admin flow. |
| Reset-password entry point beyond the member menu | not supported | Reset is a per-member menu item labelled with the existing `temporaryPassword` key (no dedicated Figma frame for reset exists). Success uses `accountCreated` (create) / `contentSaved` (reset); failures use `actionFailed`. |
| Panel chrome around the form (zone cards, `14 Active Nodes`, search `Search platform assets…`, sidebar, generic `Text` nodes) | not supported / out of scope | Background hierarchy UI, unchanged by this workstream. |
| Technician login: `Forgot password?` / self-service request ID | not supported | No reset/self-service endpoint for technicians; login keeps the neutral help slot (`Need technician access?` + `Contact Admin` + `Authorised workshop staff only`, non-interactive). No account-creation UI in technician_app. |

## ARB reuse (fixed set, no new keys)

Create: `create`, `cancel`, `confirm`, `email`, `displayName`,
`temporaryPassword`, `role`, `workshop`, `roleTechnician`, `roleWorkshopAdmin`,
`accountCreated`, `actionFailed`, `requiredField`, `invalidEmail`.
Reset: `temporaryPassword`, `confirm`, `cancel`, `requiredField`,
`contentSaved`, `actionFailed`.
Workshop staff list: `staffTab`, `noTechnicians`, `noResults`, `search`,
`error`, `genericError`.

## Notes for the lead / owner

1. `ApiEndpoints` gained `platformPasswordReset`, `workshopTechnicians`,
   `workshopTechnicianPasswordReset` (additive only). Shared routing /
   `SecurityConfig` untouched — server role chains (A1/A2) are enforced
   server-side; client only narrows the UI to permitted roles.
2. `POST /api/v1/platform/users` and both password-reset endpoints require an
   `Idempotency-Key` header; the client now generates one per call
   (`Uuid().v7()`). The previous client `createUser` omitted it and would have
   been rejected.
3. The old `AdminApi.invite()` was removed; `platformInvitations` remains as an
   unused endpoint getter. `pendingInvitations` is still parsed (server may
   send it) but never rendered.
