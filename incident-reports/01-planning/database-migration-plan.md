# Database Migration Plan - Incident Reports Status Fields

**Epic:** LSFB-62813
**Migration Task:** LSFB-64913
**Bundle:** `MedTrainer\IncidentReportsAPIBundle`
**Goal:** Migrate legacy status fields to new normalized schema
**Status:** DDL Complete, DML Command Ready (2026-02-13)

---

## Executive Summary

This migration introduces **new ENUM columns** to normalize the status system across two tables:

### Table: `incident_scalable_data`

| New Field | Type | Purpose |
|-----------|------|---------|
| `workflow_stage` | ENUM('Draft','New','Initiated','Escalated','Resolved','Resolution rejected','Waiting resolution approval') | Technical workflow position |

### Table: `company_incident_scalable`

| New Field | Type | Purpose |
|-----------|------|---------|
| `status_revamp` | ENUM('Active','Closed') | Business status |
| `source` | ENUM('Created','Uploaded') | Report origin |
| `is_archived` | BOOLEAN NULL | Archive flag for deleted/draft-deleted records |

**Migration Strategy:** DDL first (add nullable columns) → DML via console command (populate data) → Future: add constraints

---

## Implementation Status

### ✅ DDL Migration (Completed 2026-02-03)

**File:** `symfony/src/Migrations/Version20260203173237.php`

```sql
-- incident_scalable_data
ALTER TABLE incident_scalable_data
ADD COLUMN workflow_stage ENUM(
    'Draft','New','Initiated','Escalated','Resolved',
    'Resolution rejected','Waiting resolution approval'
) NULL, ALGORITHM=INSTANT;

-- company_incident_scalable
ALTER TABLE company_incident_scalable
ADD COLUMN source ENUM('Created','Uploaded') NULL, ALGORITHM=INSTANT;

ALTER TABLE company_incident_scalable
ADD COLUMN status_revamp ENUM('Active','Closed') NULL, ALGORITHM=INSTANT;

ALTER TABLE company_incident_scalable
ADD COLUMN is_archived BOOLEAN NULL, ALGORITHM=INSTANT;
```

### ✅ DML Migration Command (Completed 2026-02-13)

**Command:** `ir-configuration:populate-revamp-status`
**File:** `symfony/src/MedTrainer/IncidentReportsAPIBundle/Command/PopulateRevampStatusCommand.php`

**Usage:**
```bash
# Preview migration (dry-run)
kool run console ir-configuration:populate-revamp-status --dry-run --limit=100

# Execute full migration
kool run console ir-configuration:populate-revamp-status --commit-size=1000
```

**Options:**
- `--dry-run` - Preview without making changes
- `--commit-size=N` - Records per transaction (default: 1000)
- `--limit=N` - Max records per table for testing (default: 0 = all)

---

## Current State: Legacy Status Fields

### Table 1: `incident_scalable_data.status` (Legacy Detail Status)

**Type:** `varchar` (stores mixed values like `'I'`, `'0'`, `'1'`)
**Purpose:** Workflow stage of the incident detail
**Entity:** `PlanetMedia\MedTrainerBundle\Entity\IncidentScalableData`

**Values:**
| Value | Constant | Meaning |
|-------|----------|---------|
| `'0'` | INCIDENT_SCALABLE_DATA_STATUS_DRAFT | Draft |
| `'1'` | INCIDENT_SCALABLE_DATA_STATUS_NEW | New |
| `'I'` | INCIDENT_SCALABLE_DATA_STATUS_INITIATED | Initiated (computed - status=1 + has conversations) |
| `'2'` | INCIDENT_SCALABLE_DATA_STATUS_ESCALATED | Escalated |
| `'3'` | INCIDENT_SCALABLE_DATA_STATUS_RESOLVED | Resolved |
| `'5'` | INCIDENT_SCALABLE_DATA_STATUS_RESOLUTION_REJECTED | Resolution Rejected |
| `'6'` | INCIDENT_SCALABLE_DATA_STATUS_WAITING_RESOLUTION_APROVAL | Waiting Resolution Approval |

---

### Table 2: `company_incident_scalable.status` (Legacy Report Status)

**Type:** `varchar`
**Purpose:** Lifecycle/visibility control of the incident report
**Entity:** `PlanetMedia\MedTrainerBundle\Entity\CompanyIncidentScalable`

**Values:**
| Value | Constant | Meaning |
|-------|----------|---------|
| `'S'` | COMPANY_INCIDENT_SCALABLE_STATUS_DRAFT | Draft (Active) |
| `'1'` | COMPANY_INCIDENT_SCALABLE_STATUS_ACTIVE | Active |
| `'D'` | COMPANY_INCIDENT_SCALABLE_STATUS_DELETED | Deleted/Archived |
| `'-1'` | COMPANY_INCIDENT_SCALABLE_STATUS_DRAFT_DELETED | Draft Deleted/Archived |
| `'U'` | COMPANY_INCIDENT_SCALABLE_STATUS_UPLOADED | Uploaded (from import) |

---

## Data Mapping (Implemented)

### Mapping 1: `incident_scalable_data.status` → `workflow_stage`

| Legacy `status` | New `workflow_stage` |
|-----------------|----------------------|
| `'0'` | `'Draft'` |
| `'1'` | `'New'` |
| `'I'` | `'Initiated'` |
| `'2'` | `'Escalated'` |
| `'3'` | `'Resolved'` |
| `'5'` | `'Resolution rejected'` |
| `'6'` | `'Waiting resolution approval'` |
| `'D'` | `'Resolved'` (via ARCHIVED_LEGACY_STATUSES) |
| `'-1'` | `'Resolved'` (via ARCHIVED_LEGACY_STATUSES) |
| *(other)* | `NULL` + warning log |

### Mapping 2: `company_incident_scalable.status` → `status_revamp`

| Legacy `status` | New `status_revamp` |
|-----------------|---------------------|
| `'S'` | `'Active'` |
| `'1'` | `'Active'` |
| `'D'` | `'Closed'` |
| `'-1'` | `'Closed'` |
| `'U'` | `'Closed'` |
| *(other)* | `NULL` + warning log |

### Mapping 3: `company_incident_scalable.status` → `source`

| Legacy `status` | New `source` |
|-----------------|--------------|
| `'U'` | `'Uploaded'` |
| *(any other)* | `'Created'` |

### Mapping 4: `is_archived`

- **Condition:** Set to `1` when legacy status is in `ARCHIVED_LEGACY_STATUSES` (`'D'`, `'-1'`)
- **Otherwise:** `0`
- **Cross-table effect:** These same statuses also derive `workflow_stage = 'Resolved'` on `incident_scalable_data`

---

## Table Relationship

```
company_incident_scalable (Main Report)
    │
    └── id_incident_scalable_detail ──► incident_scalable_data.id (Detail Data)
```

- `company_incident_scalable` = Header/main incident report record
- `incident_scalable_data` = Incident detail data

---

## Validation Queries (Actual Implementation)

The verification queries are in `01-planning/incident_reports_migration_validation.sql`.

### Sample Migrated Records

```sql
SELECT
    ir.id AS report_id,
    ird.id AS detail_id,
    ird.status AS detail_status_legacy,
    ird.workflow_stage AS detail_workflow_new,
    ir.status AS report_status_legacy,
    ir.status_revamp AS report_status_new,
    ir.source,
    ir.is_archived,
    ir.update_date
FROM company_incident_scalable ir
INNER JOIN incident_scalable_data ird
    ON ir.id_incident_scalable_detail = ird.id
LIMIT 100;
```

### Check for Unmapped Values

```sql
-- incident_scalable_data: records with status but no workflow_stage
SELECT
    'incident_scalable_data' AS table_name,
    COUNT(*) AS count,
    GROUP_CONCAT(DISTINCT status) AS unmapped_statuses
FROM incident_scalable_data
WHERE status IS NOT NULL AND workflow_stage IS NULL;

-- company_incident_scalable: records with status but no status_revamp
SELECT
    'company_incident_scalable' AS table_name,
    COUNT(*) AS count,
    GROUP_CONCAT(DISTINCT status) AS unmapped_statuses
FROM company_incident_scalable
WHERE status IS NOT NULL AND status_revamp IS NULL;
```

### Verify Mapping Accuracy

```sql
-- incident_scalable_data.workflow_stage mapping
SELECT
    status AS legacy_status,
    workflow_stage AS new_workflow_stage,
    COUNT(*) AS record_count
FROM incident_scalable_data
WHERE workflow_stage IS NOT NULL
GROUP BY status, workflow_stage
ORDER BY status;

-- company_incident_scalable.status_revamp mapping
SELECT
    status AS legacy_status,
    status_revamp AS new_status_revamp,
    source,
    is_archived,
    COUNT(*) AS record_count
FROM company_incident_scalable
WHERE status_revamp IS NOT NULL
GROUP BY status, status_revamp, source, is_archived
ORDER BY status;
```

### Overall Migration Progress

```sql
SELECT
    'incident_scalable_data' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN workflow_stage IS NOT NULL THEN 1 ELSE 0 END) AS migrated,
    SUM(CASE WHEN workflow_stage IS NULL THEN 1 ELSE 0 END) AS pending,
    ROUND(SUM(CASE WHEN workflow_stage IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS percent_complete
FROM incident_scalable_data

UNION ALL

SELECT
    'company_incident_scalable' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN status_revamp IS NOT NULL THEN 1 ELSE 0 END) AS migrated,
    SUM(CASE WHEN status_revamp IS NULL THEN 1 ELSE 0 END) AS pending,
    ROUND(SUM(CASE WHEN status_revamp IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS percent_complete
FROM company_incident_scalable;
```

---

## Rollback Plan

The DML migration only populates new columns - it does NOT modify legacy columns.

**If issues occur:**

1. Stop the command (Ctrl+C) - safe to interrupt
2. Set new columns back to NULL:
   ```sql
   UPDATE incident_scalable_data SET workflow_stage = NULL;
   UPDATE company_incident_scalable
   SET status_revamp = NULL, source = NULL, is_archived = NULL;
   ```
3. Fix mapping issues in command
4. Re-run migration

**Note:** The legacy `status` columns remain unchanged, so the application can continue using them until the migration is verified.

---

## References

- **Epic:** LSFB-62813 - Incident Reports Workflow Table Revamp
- **Migration Task:** LSFB-64913 - Migrate old incident reports records to new statuses
- **DDL Migration:** `symfony/src/Migrations/Version20260203173237.php`
- **DML Command:** `symfony/src/MedTrainer/IncidentReportsAPIBundle/Command/PopulateRevampStatusCommand.php`
- **Verification Queries:** `01-planning/incident_reports_migration_validation.sql`

---

**Last Updated:** 2026-02-13
**Status:** DDL Complete, DML Command Ready for Production Execution
