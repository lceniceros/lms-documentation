# Incident Reports v3 — Actions Matrix (Consolidated)

Audience: Product, Engineering, QA

Purpose: Single source summarizing business rules and technical conditions for which actions appear per incident status, including matrix permissions, anonymous protections, and IR_EAR behavior.

---

## Statuses and Codes (Unified)

| Display | Code | Source | Notes |
|--------|------|--------|-------|
| Draft | 0 | IncidentScalableData.status | Separate tab in legacy UI |
| New | 1 | IncidentScalableData.status | Fresh report |
| Initiated | I | Derived (1 + conversations) | Treated like New for actions |
| Escalated | 2 | IncidentScalableData.status | Active escalation |
| Resolved | 3 | IncidentScalableData.status | Closed unless IR_EAR allows edits |
| Escalated (IRv2) | 4 | Legacy | Old reports only |
| Resolution Rejected | 5 | IncidentScalableData.status | Returns to editability |
| Waiting Resolution Approval | 6 | IncidentScalableData.status | Editing locked |
| Deleted | D | CompanyIncidentScalable.status | Soft delete state |

---

## Actions Catalog

- Download: Always visible (PDF), all statuses
- Delete (soft delete): Visible for active reports; not for anonymous
- Restore (undelete): Only for Deleted
- Edit: Conditional by status + matrix membership + permission; special case for Resolved via IR_EAR
- IRv2-only actions (Old reports): Open Discussion, Close Incident, Post Closure, Change Follow Up Date

---

## Action Matrix (Product + Technical)

| Status | Code | Download | Delete | Restore | Edit | IRv2: Discussion | IRv2: Close | IRv2: Post Closure | IRv2: Change Follow Up |
|--------|------|----------|--------|---------|------|-------------------|-------------|---------------------|------------------------|
| Draft | 0 | ✅ | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| New | 1 | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ | ❌ |
| Initiated | I | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ | ❌ |
| Escalated | 2 | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ | ❌ |
| Resolved | 3 | ✅ | ✅* | ❌ | ✅² | ❌ | ❌ | ✅ | ✅ |
| Resolution Rejected | 5 | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ | ❌ |
| Waiting Resolution Approval | 6 | ✅ | ✅* | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Deleted | D | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

Legend:
- * Delete not shown for anonymous reports
- ¹ Edit requires: user in escalation matrix AND matching permission for the matrix type (R for RACI, F for Functional, G for Group). Employees (`userType = 'E'`) do not get Edit in list actions even if assigned.
- ² Resolved edit requires IR_EAR feature enabled AND matching permission in IR_EAR extras AND user in matrix

---

## Matrix Membership and Permissions

Matrix types and required permission flags:
- 1: RACI → 'R'
- 2 or 4: Functional → 'F'
- 5: Group → 'G'

Conditions for Edit (Rule Set A: statuses 1, 2, 5):
- `userAllowEditIncident` contains the needed flag (R/F/G)
- `matrixType` is present and matches (1, 2/4, or 5)
- Current user ID is in `incident.matrixUsers`
- `userType` is not 'E'

Conditions for Edit (Rule Set B: status 3 Resolved):
- `newSettings.IR_EAR.value == 1`
- `newSettings.IR_EAR.extras` contains the needed flag (R/F/G)
- `matrixType` present and matches
- Current user ID is in `incident.matrixUsers`

---

## Anonymous Reports Protection

- Delete action is hidden for anonymous reports across active statuses.
- Download remains available.

---

## Notes on Initiated and Draft

- Initiated is a derived state treated like New for action visibility.
- Drafts live in a separate tab in legacy UI; list actions differ and do not include Edit in this table.

---

## Alignment and Source References

- Product view: claude/irv3/context/discovery/IncidentTracking_ActionsMatrix_ProductView.md
- Technical view: claude/irv3/context/discovery/IncidentTracking_ActionsMatrix_Technical.md
- Business matrices: claude/irv3/context/discovery/business/matrices/IncidentTracking_CreatedReportsTab_ActionsMatrix.md
- ERD reference: claude/irv3/context/discovery/technical/database-erd.md

---

## Implementation Guidance (for new list API)

- Server-side should not replicate UI rendering but must expose enough flags for FE to render actions consistently:
  - status code, isDeleted, isAnonymous
  - matrixType, matrixUsers (or boolean hasEditAuthority computed server-side)
  - company feature IR_EAR value and extras (or boolean canEditResolved)
- Prefer computing booleans server-side in the new module: `canEdit`, `canDelete`, `canRestore`, `legacyIrV2Actions[]` to reduce FE duplication and avoid drift.

---

## Migration & API Integration Notes

- API-first approach: expose action booleans (`canEdit`, `canDelete`, `canRestore`, `canDownload`) from the backend to avoid FE duplication; legacy DataTables remains untouched until full deprecation.
- Coexistence: keep legacy controllers and routes while introducing new API controllers under `/api/v1/incidents*` (or `/incident-reports*` alias) gated by a feature flag. Frontend can switch via flag without modifying legacy views.
- Zero-downtime + rollback: version-based rollback via git revert; no runtime switches required beyond the feature flag.
- Decoupling: compute permissions via a dedicated resolver service (server-side), using DTOs and query objects to avoid N+1.
- Boundaries: actions logic resides in TrackingBundle; configuration catalogs from ConfigurationBundle; creation flows in CreationBundle (do not cross-mutate across bundles).

## RBAC Integration Hooks

- Policy layer uses existing Incident Voter and matrix membership checks; align with `userAllowEditIncident`, `matrixType`, `matrixUsers` semantics.
- IR_EAR source: company setting (feature flag/extras) resolved by a FeatureFlag adapter in the new bundle.
- Optional outputs: expose both raw inputs (status code, isAnonymous, matrixType) and computed booleans to aid migration.

## Open Items to Confirm

- Final policy on employee ('E') edit capability outside list view
- IR_EAR configuration source for new module (feature flag adapter)
- Whether server will emit `canEdit` booleans or raw ingredients only
