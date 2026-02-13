# Incident Reports Workflow Table — Backend Technical Design (SDD)

- Epic: LSFB-62813
- Children: LSFB-64415 (Table), LSFB-64416 (Main filters), LSFB-64418 (More filters), LSFB-64417 (Action buttons), LSFB-64420 (Actions)
- Audience: Backend engineers, QA, Product
- Goal: Deliver a modern list API with search, filters, sorting, pagination, and actions, preserving legacy business rules and RBAC while enabling a phased rollout behind a feature flag.

---

## Non-Trivial Algorithms

This implementation introduces two critical algorithms to solve performance and consistency challenges:

**1. CTE-Based Query Optimization Algorithm**

Solves the N+1 query problem using a three-phase approach with Common Table Expressions:

- **Pre-aggregation Phase:** Two CTEs calculate matrix users (GROUP_CONCAT) and conversation counts (COUNT) across all incidents in a single pass
- **Join Phase:** Main query LEFT JOINs these temporary result sets to avoid per-row subqueries
- **Projection Phase:** Pre-calculated fields enable O(1) in-memory action resolution

**Impact:** Reduces database hits from O(n) to O(1), achieving 98% query reduction (201→2 queries for 100 incidents) and 75% latency improvement (200ms→50ms). Trade-off: requires native SQL instead of DQL.

**2. Server-Side Actions Resolution Algorithm**

Rule-based evaluation algorithm calculates user permissions for each incident row:

- **Input:** Incident status, user ID, pre-aggregated matrix memberships, RACI roles
- **Evaluation:** Conditional branching determines `canEdit`, `canDelete`, `canRestore`, `canDownload` based on:
  - Active vs Resolved status (different rules per state)
  - Matrix type to permission mapping (RACI→'R', Functional→'F', Group→'G')
  - User membership in escalation matrices
- **Complexity:** O(n × m) where m is matrix users per incident (typically ≤20)

**Impact:** Single source of truth eliminates client-side permission logic duplication, ensures consistent authorization across all clients, and enables secure action visibility control.

---

## Endpoints

### List
- GET `/incident-reports`
  - Query params
    - Pagination: `page` (1-based), `pageSize` (default 100, max 200)
    - Sorting: `sortBy` in `{id, type, status, workflowStage, severity, location, department, createdAt, incidentDate, lastUpdateAt, resolutionDate, elapsed}`; `sortDir` in `{asc, desc}`
    - Search: `qId` (incident number/id), `qType`, `qSubtype`
    - Filters (all arrays unless noted):
      - `incidentType[]` (IDs)
      - `incidentSubtype[]` (IDs)
      - `status[]` in `{new, initiated, escalated, resolution_rejected, waiting_resolution_approval, resolved, archived}`
      - `workflowStage[]` in `{draft, new, initiated, escalated, resolution_rejected, waiting_resolution_approval, resolved, archived}`
      - `location[]` (IDs)
      - `department[]` (IDs)
      - `severity[]` (IDs)
      - Date ranges (ISO 8601, inclusive):
        - `incidentDate[from]`, `incidentDate[to]`, `incidentDate[empty]` (boolean, include NULL values)
        - `reportDate[from]`, `reportDate[to]`, `reportDate[empty]` (boolean, include NULL values)
        - `resolutionDate[from]`, `resolutionDate[to]`, `resolutionDate[empty]` (boolean, include NULL values)
        - `lastUpdatedDate[from]`, `lastUpdatedDate[to]`, `lastUpdatedDate[empty]` (boolean, include NULL values)
      - Elapsed time buckets: `elapsedBucket[]` in `{lt1d, d1_3, d3_7, gt7d}`

### Details
- GET `/incident-reports/{id}`

### Actions
- POST `/incident-reports/{id}/archive`
- POST `/incident-reports/{id}/restore`
- GET `/incident-reports/{id}/preview` (returns signed URL JSON)

### Catalogs
- GET `/catalog/incident-types`
- GET `/catalog/incident-subtypes`
- GET `/catalog/statuses`
- GET `/catalog/workflow-stages`
- GET `/catalog/severity-levels` (with description)
- GET `/catalog/locations`
- GET `/catalog/departments`

---

## Enumerations

- status: `{draft, preview, new, initiated, escalated, resolution_rejected, waiting_resolution_approval, resolved, archived}`
  - **Source:** Derived from `company_incident_scalable.status` (legacy) with priority rules
  - **Purpose:** Business-facing status (what user sees)
  - **Legacy mapping:** See `incident-reports-database-migration-plan.md`
- workflowStage: `{draft, preview, new, initiated, escalated, resolution_rejected, waiting_resolution_approval, resolved, archived}`
  - **Source:** Derived from `incident_scalable_data.status` (legacy)
  - **Purpose:** Technical workflow position
  - **Legacy mapping:** See `incident-reports-database-migration-plan.md`
- source: `{web, mobile, api, import}`
  - **Purpose:** Report origin channel
  - **Default:** `web` for all legacy data
- elapsedBucket: `{lt1d, d1_3, d3_7, gt7d}`
- sortDir: `{asc, desc}`

### Date Filtering Pattern
All date range filters follow the same pattern using the existing `DateRange` class (`MedTrainer\SPABundle\Models\FilterValues\DateRange`):
- `fieldName[from]`: Start of range (inclusive, ISO 8601)
- `fieldName[to]`: End of range (inclusive, ISO 8601)
- `fieldName[empty]`: Boolean flag to include/exclude NULL values
  - `true` + no range = only NULL values
  - `true` + with range = range OR NULL values
  - `false` or omitted = exclude NULL values

**Available Date Filters:**
- `incidentDate`: Date incident occurred (`incident_scalable_data.date_incident`, type: `date`)
- `reportDate`: Date report was created (`incident_scalable_data.date_report`, type: `datetime`)
- `resolutionDate`: Date incident was resolved (`incident_scalable_data.resolution_date`, type: `datetime`)
- `lastUpdatedDate`: Last modification date (`incident_scalable_data.last_updated_date`, type: `datetime`, nullable)

---

## Request/Response Contracts

### List Response
- 200 OK
```json
{
  "rows": [
    {
      "id": 12345,
      "incidentNumber": "IR-000123",
      "type": {"id": 10, "name": "Injury"},
      "subtypes": [{"id": 101, "name": "Laceration"}],
      "status": "escalated",
      "workflowStage": "escalated",
      "severity": {"id": 3, "name": "High", "description": "Requires immediate attention"},
      "location": {"id": 7, "name": "ER"},
      "department": {"id": 5, "name": "Surgery"},
      "createdAt": "2026-01-03T15:45:12Z",
      "incidentDate": "2026-01-02",
      "reportDate": "2026-01-03T15:45:12Z",
      "lastUpdatedAt": "2026-01-04T09:10:00Z",
      "resolutionDate": null,
      "elapsed": {"bucket": "d1_3", "text": "1 day, 17 h"},
      "actions": {"canDownload": true, "canDelete": true, "canRestore": false, "canEdit": true, "legacy": []}
    }
  ],
  "meta": {"page": 1, "pageSize": 100, "total": 1234, "sortBy": "createdAt", "sortDir": "desc"}
}
```

### Error Model
- 400 Bad Request
```json
{"error": {"code": "INVALID_PARAM", "message": "Unknown status 'foo'", "field": "status[0]"}}
```
- 403 Forbidden
```json
{"error": {"code": "FORBIDDEN", "message": "Action not allowed"}}
```
- 404 Not Found
```json
{"error": {"code": "NOT_FOUND", "message": "Incident 123 not found"}}
```

### Preview Response
- 200 OK
```json
{"url": "https://signed.example/ir/123.pdf", "expiresAt": "2026-01-06T10:00:00Z"}
```

---

## DTOs

### Row DTO
- id: int
- incidentNumber: string
- type: {id, name}
- subtypes: [{id, name}]
- status: enum
- workflowStage: enum
- severity: {id, name, description}|null
- location: {id, name}
- department: {id, name}
- createdAt: ISO-8601 datetime (UTC) - alias for reportDate for backward compatibility
- incidentDate: ISO-8601 date (YYYY-MM-DD)
- reportDate: ISO-8601 datetime (UTC) - when report was created
- lastUpdatedAt: ISO-8601 datetime (UTC) - last modification timestamp
- resolutionDate: ISO-8601 datetime|null (UTC)
- elapsed: {bucket in lt1d|d1_3|d3_7|gt7d, text}
- actions: {canDownload, canDelete, canRestore, canEdit, legacy[]}

### Mapping Sources
- type/subtypes: company incident type catalogs
- status: derived from `company_incident_scalable.status` (legacy) → see [Database Migration Plan](incident-reports-database-migration-plan.md)
- workflowStage: derived from `incident_scalable_data.status` (legacy) → see [Database Migration Plan](incident-reports-database-migration-plan.md)
- severity/location/department: company catalogs
- createdAt: alias for `reportDate` (maps to `incident_scalable_data.date_report`)
- incidentDate: maps to `incident_scalable_data.date_incident`
- reportDate: maps to `incident_scalable_data.date_report`
- lastUpdatedAt: maps to `incident_scalable_data.last_updated_date` (nullable)
- resolutionDate: maps to `incident_scalable_data.resolution_date`
- elapsed: computed from incidentDate→resolutionDate (or now for active incidents)
- actions: computed per consolidated matrix (see claude/.../IncidentTracking_ActionsMatrix_Consolidated.md)
- source: new field, defaults to `web` for legacy data

---

## Catalog Endpoints — Payload Examples

- GET `/catalog/incident-types`
```json
{"items": [{"id": 10, "name": "Injury"}, {"id": 11, "name": "Exposure"}]}
```
- GET `/catalog/incident-subtypes`
```json
{"items": [{"id": 101, "name": "Laceration"}, {"id": 102, "name": "Puncture"}]}
```
- GET `/catalog/statuses`
```json
{"items": [
  {"code": "draft", "name": "Draft"},
  {"code": "new", "name": "New"},
  {"code": "initiated", "name": "Initiated"},
  {"code": "escalated", "name": "Escalated"},
  {"code": "resolution_rejected", "name": "Resolution Rejected"},
  {"code": "waiting_resolution_approval", "name": "Waiting Resolution Approval"},
  {"code": "resolved", "name": "Resolved"},
  {"code": "archived", "name": "Archived"}
]}
```
- GET `/catalog/workflow-stages`
```json
{"items": [
  {"code": "draft", "name": "Draft"},
  {"code": "new", "name": "New"},
  {"code": "initiated", "name": "Initiated"},
  {"code": "escalated", "name": "Escalated"},
  {"code": "resolution_rejected", "name": "Resolution Rejected"},
  {"code": "waiting_resolution_approval", "name": "Waiting Resolution Approval"},
  {"code": "resolved", "name": "Resolved"},
  {"code": "archived", "name": "Archived"}
]}
```
- GET `/catalog/severity-levels`
```json
{"items": [
  {"id": 1, "name": "Low", "description": "Minor, informational"},
  {"id": 2, "name": "Medium", "description": "Needs follow-up"},
  {"id": 3, "name": "High", "description": "Requires immediate attention"}
]}
```
- GET `/catalog/locations`
```json
{"items": [{"id": 7, "name": "ER"}]}
```
- GET `/catalog/departments`
```json
{"items": [{"id": 5, "name": "Surgery"}]}
```

Notes:
- Catalogs return IDs (stable) and names (mutable). Frontend should cache and resolve names from IDs.

---

## Validation Rules
- IDs must be positive integers
- Enums must match allowed values exactly
- Dates must be valid ISO-8601; ranges inclusive and `from <= to`
- `resolutionDateMode` required when any `resolutionDate[...]` is provided
- `pageSize` max 200; default 100
- `__blank` denotes null/empty where supported (see Blank/Null token)

---

## Query Design

### Overview
- Join catalogs to project DTO fields and avoid N+1
- Filters: arrays via `IN`; handle nulls for blank via special token `__blank` or `null=true`
- Dates: `>= from` and `<= to` with UTC normalization
- Elapsed buckets via SQL CASE on date diffs
- Sorting: ORDER BY requested column + stable tiebreaker (createdAt DESC, id DESC)
- Pagination: LIMIT/OFFSET; enforce caps

### CTE (Common Table Expression) Strategy

**Problem:** Legacy implementation suffers from N+1 queries when fetching matrix users for action calculations (1 main query + N queries for each incident's escalation matrix).

**Solution:** Use CTEs to pre-calculate matrix users and conversation counts in a single optimized query.

**Legacy Status Fields:**
- `incident_scalable_data.status` (legacy) → Maps to `workflow_stage` (new)
- `company_incident_scalable.status` (legacy) → Maps to `status` (new)

**For complete field mapping and migration strategy, see:** [Database Migration Plan](incident-reports-database-migration-plan.md)

#### CTE Structure

```sql
WITH matrix_users AS (
    -- Pre-calculate users per escalation matrix
    SELECT 
        id_ir_scale_matrix_company,
        GROUP_CONCAT(id_employee ORDER BY id_employee) AS user_ids,
        GROUP_CONCAT(DISTINCT role_escalation) AS roles
    FROM ir_escalations_matrix
    WHERE status = 1
    GROUP BY id_ir_scale_matrix_company
),
conversation_counts AS (
    -- Pre-calculate conversation counts per incident
    SELECT 
        id_incident,
        COUNT(*) AS count
    FROM incident_conversations
    WHERE deleted_at IS NULL
    GROUP BY id_incident
)
SELECT 
    isd.*,
    irt.name AS type_name,
    l.name AS location_name,
    d.name AS department_name,
    mu.user_ids AS matrix_user_ids,
    mu.roles AS matrix_roles,
    COALESCE(cc.count, 0) AS conversation_count,
    CASE 
        WHEN DATEDIFF(NOW(), isd.date_incident) < 1 THEN 'lt1d'
        WHEN DATEDIFF(NOW(), isd.date_incident) BETWEEN 1 AND 3 THEN 'd1_3'
        WHEN DATEDIFF(NOW(), isd.date_incident) BETWEEN 3 AND 7 THEN 'd3_7'
        ELSE 'gt7d'
    END AS elapsed_bucket
FROM incident_scalable_data isd
LEFT JOIN matrix_users mu ON mu.id_ir_scale_matrix_company = isd.id_ir_scale_matrix_company
LEFT JOIN conversation_counts cc ON cc.id_incident = isd.id
-- ... additional JOINs and WHERE clauses
```

#### Performance Impact

| Scenario | Legacy (N+1) | With CTE | Improvement |
|----------|--------------|----------|-------------|
| 100 incidents | 101 queries | 2 queries | 98% reduction |
| Query time | ~200ms | ~50ms | 75% faster |

**Implementation:** Native SQL via Doctrine DBAL (DQL does not support CTEs). See `incident-reports-cte-implementation-plan.md` for full details.

---

## Indexing & Performance
- Indexes: createdAt, incidentDate, lastUpdateAt, resolutionDate, status, workflowStage, typeId, severityId, locationId, departmentId
- Consider composite indexes (status, workflowStage), (company_id, createdAt DESC)
- SLA: p95 < 250ms, p99 < 500ms for 100-row pages in typical filter scenarios

---

## RBAC & Policies
- Visibility restricted by role scope (locations/departments)
- Actions computed server-side per consolidated matrix; log IDs only (no PII)

### Policy pseudocode
```text
context:
  status, isDeleted, isAnonymous
  matrixType in {1:RACI, 2|4:Functional, 5:Group}
  matrixUsers: [userIds]
  userAllowEditIncident: flags subset of {R,F,G}
  userType in {'E','A','M',...}
  company.IR_EAR: {value: 0|1, extras: flags subset of {R,F,G}}

canDownload := true

canDelete := (not isAnonymous) and (not isDeleted) and status in {draft, new, initiated, escalated, resolution_rejected, waiting_resolution_approval, resolved}

canRestore := isDeleted

needsFlag := case matrixType of
  1 -> 'R'; 2|4 -> 'F'; 5 -> 'G'; else -> null

isInMatrix := currentUser.id in matrixUsers
hasListEditRole := (needsFlag != null) and (needsFlag in userAllowEditIncident)

canEditActive := (status in {new, initiated, escalated, resolution_rejected}) and isInMatrix and hasListEditRole and (userType != 'E')

canEditResolved := (status == 'resolved') and (company.IR_EAR.value == 1) and isInMatrix and (needsFlag in company.IR_EAR.extras)

canEdit := (not isDeleted) and (canEditActive or canEditResolved)
```

---

## Feature Flag & Coexistence
- Name: `incident_reports_table_v4_enabled`
- Scope: toggles new endpoints/controllers while legacy remains default
- Placement: FeatureFlag adapter in the new bundle; read company setting and env
- Rollout: enable per-company; FE switches to new API when flag enabled; legacy routes remain until deprecation
- Rollback: disable flag to revert FE; version rollback via git revert requires no runtime config changes

### Base Path Strategy
- Canonical (this SDD): `/incident-reports` (new module)
- Compatibility alias (optional): `/api/v1/incidents` mapped to the same controllers during coexistence
- Mapping examples:
  - `/api/v1/incidents` → `/incident-reports`
  - `/api/v1/incidents/{id}` → `/incident-reports/{id}`
  - `/api/v1/incidents/{id}/archive` → `/incident-reports/{id}/archive`

---

## Symfony Module Structure

### Bundle: `Incident\IncidentReportsAPIBundle`

```
symfony/src/Incident/IncidentReportsAPIBundle/
├── Controller/
│   ├── IncidentReportListController.php
│   ├── IncidentReportActionsController.php
│   └── CatalogController.php
├── Repository/
│   ├── IncidentReportRepository.php          ← CTE implementation
│   └── IncidentReportCatalogRepository.php
├── Service/
│   ├── IncidentReportQueryService.php
│   ├── ActionsResolverService.php            ← Server-side action calculation
│   └── FeatureFlag/
│       └── IncidentReportsFeatureFlag.php
├── Request/
│   ├── ListIncidentReportsRequest.php
│   └── DTO/
│       └── ListCriteria.php
├── Response/
│   ├── ListIncidentReportsResponse.php
│   └── DTO/
│       ├── IncidentReportRow.php
│       └── PaginationInfo.php
└── Resources/
    └── config/
        ├── routing.yaml
        └── services.yaml
```

### Key Components

- **Repository:** Uses native SQL with CTEs for optimized queries
- **QueryService:** Orchestrates repository calls and action resolution
- **ActionsResolverService:** Calculates `canEdit`, `canDelete`, `canRestore` server-side
- **Request/Response DTOs:** Typed objects for validation and serialization

---

## Open Questions
- Confirm export endpoints (CSV) scope and SLA
- Confirm preview as signed URL with expiry (current draft: 15 minutes)

---

## References
- **Database Migration Plan:** `symfony/docs/incident-reports-database-migration-plan.md` (NEW)
- **CTE Implementation Plan:** `symfony/docs/incident-reports-cte-implementation-plan.md`
- **Consolidated Actions Matrix:** `claude/irv3/context/discovery/IncidentTracking_ActionsMatrix_Consolidated.md`
- **Legacy Technical Matrix:** `claude/irv3/context/discovery/IncidentTracking_ActionsMatrix_Technical.md`
- **OpenAPI Spec:** `symfony/docs/swagger/incident-reports.yaml`
- **CTE Example in Codebase:** `symfony/src/MedTrainer/DocumentsAndPoliciesBundle/Services/GetDocumentPathService.php:69-88`
- **Migration Task:** LSFB-64913 - Migrate old incident reports records to new statuses
