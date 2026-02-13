# Incident Reports Status Migration - DML Command

**Epic:** LSFB-62813
**Migration Task:** LSFB-64913
**Last Updated:** 2026-02-13
**Status:** DDL Complete, DML Command Ready for Production

---

## Current Status

| Phase | Status | Date |
|-------|--------|------|
| Phase 1: Preparation | ✅ COMPLETED | 2026-02-05 |
| Phase 2: Deploy Code | ✅ COMPLETED | 2026-02-09 |
| Phase 3: DDL Migration | ✅ COMPLETED | 2026-02-05 |
| Phase 4: Dry-run | ⏳ PENDING | - |
| Phase 5: Execute DML | ⏳ PENDING | - |
| Phase 6: Validate | ⏳ PENDING | - |
| Phase 7: Monitor | ⏳ PENDING | - |
| Phase 8: Cleanup | ⏳ PENDING | ~1 month later |

## Overview

This document summarizes the **code-first** data migration for legacy `status` fields into new enum-based fields with **minimal impact**.

**Strategy:** Gradual migration - legacy columns remain untouched, new columns added alongside. This keeps existing workflow stable during transition.

**Related Files:**
- DDL Migration: `symfony/src/Migrations/Version20260203173237.php`
- DML Command: `symfony/src/MedTrainer/IncidentReportsAPIBundle/Command/PopulateRevampStatusCommand.php`

## Scope

### Tables & Volumes
- `incident_scalable_data`: **235,750** rows
- `company_incident_scalable`: **234,640** rows
- **Total:** ~470K records
- Relationship: **1:1** (via `id_incident_scalable_detail`)

## Schema Changes (COMPLETED)

### `incident_scalable_data`

| Column | Type | Status |
|--------|------|--------|
| `status` | VARCHAR(20) NULL | **UNCHANGED** (legacy) |
| `workflow_stage` | ENUM('Draft','New','Initiated','Escalated','Resolved','Resolution rejected','Waiting resolution approval') NULL | **ADDED** |

### `company_incident_scalable`

| Column | Type | Status |
|--------|------|--------|
| `status` | CHAR(2) NOT NULL DEFAULT '1' | **UNCHANGED** (legacy) |
| `status_revamp` | ENUM('Active','Closed') NULL | **ADDED** |
| `source` | ENUM('Created','Uploaded') NULL | **ADDED** |
| `is_archived` | BOOLEAN NULL | **ADDED** |

> **Note:** Using `status_revamp` instead of overwriting `status` allows existing code to continue working during transition.

## Data Mapping

### `incident_scalable_data.status` → `workflow_stage`

| Legacy Value | New Value |
|--------------|-----------|
| `0` | `Draft` |
| `1` | `New` |
| `I` | `Initiated` |
| `2` | `Escalated` |
| `3` | `Resolved` |
| `5` | `Resolution rejected` |
| `6` | `Waiting resolution approval` |
| `D` | `Resolved` (archived legacy status) |
| `-1` | `Resolved` (archived legacy status) |
| *(other)* | NULL + warning logged |

### `company_incident_scalable.status` → `status_revamp`

| Legacy Value | New Value |
|--------------|-----------|
| `S` | `Active` |
| `1` | `Active` |
| `D` | `Closed` |
| `-1` | `Closed` |
| `U` | `Closed` |
| *(other)* | NULL + warning logged |

### `company_incident_scalable.status` → `source`

| Condition | Value |
|-----------|-------|
| `status = 'U'` | `Uploaded` |
| Any other status | `Created` |

### `company_incident_scalable.is_archived`

| Condition | Value |
|-----------|-------|
| `status IN ('D', '-1')` | `1` (true) |
| Otherwise | `0` (false) |

> **Note:** `D` and `-1` are archived legacy statuses (`ARCHIVED_LEGACY_STATUSES`). They derive both `is_archived = 1` on `company_incident_scalable` and `workflow_stage = 'Resolved'` on `incident_scalable_data`.

## Command: `ir-configuration:populate-revamp-status`

### Location
`symfony/src/MedTrainer/IncidentReportsAPIBundle/Command/PopulateRevampStatusCommand.php`

### Usage
```bash
# Dry-run (recommended first)
kool run console ir-configuration:populate-revamp-status --dry-run

# Dry-run with limit (for testing)
kool run console ir-configuration:populate-revamp-status --dry-run --limit=100

# Execute migration
kool run console ir-configuration:populate-revamp-status

# Custom commit size
kool run console ir-configuration:populate-revamp-status --commit-size=500
```

### Options
| Option | Default | Description |
|--------|---------|-------------|
| `--dry-run` | false | Simulate without writing |
| `--commit-size` | 1000 | Rows per transaction |
| `--limit` | 0 | Max rows per table (0 = all) |

### Behavior
- **Idempotent:** Only updates rows where new field is NULL
- **Transactional:** Each batch commits atomically
- **Cursor-based:** Uses `id > :lastId` pagination (no OFFSET)
- **Progress:** Shows progress bar and summary
- **Logging:** Aggregates unmapped values by status with total count
- **Exit codes:** 0 = success, 1 = failure
- **Entity constants:** Uses `IncidentScalableData::*` and `CompanyIncidentScalable::*` constants for status mapping

### Estimated Time
- **Dry-run with limit=100:** ~0.3 seconds
- **Full migration (~470K records):** 5-10 minutes

### Sample Output
```
Command started at: 2026-02-13 18:08:17

DRY RUN MODE - No records will be modified

LIMIT MODE - Processing max 100 records per table

Step 1: Migrating incident_scalable_data
  Found 235750 records to migrate
  Limited to 100 records
 100/100 [============================] 100% - Done!

Step 2: Migrating company_incident_scalable
  Found 234640 records to migrate
  Limited to 100 records
 100/100 [============================] 100% - Done!

========================================
Migration Summary
========================================
incident_scalable_data total pending: 235750
  - processed: 100
  - workflow_stage mapped: 100
  - unmapped values: 0
  - transactions (would commit): 4
  - remaining: 235650

company_incident_scalable total pending: 234640
  - processed: 100
  - status_revamp mapped: 100
  - source derived: 100
  - is_archived set: 25
  - unmapped values: 0
  - transactions (would commit): 4
  - remaining: 234540

Command finished at: 2026-02-13 18:08:17
Total execution time: 0.41 seconds

This was a dry run. No changes were made.
Run without --dry-run to execute the migration.
```

### Sample Output with Unmapped Values

When unmapped status values are found, the summary shows a breakdown by value sorted by frequency:

```
  - unmapped values: 3 unique value(s) affecting 150 total record(s)
      • status="X": 100 record(s)
      • status="(NULL)": 35 record(s)
      • status="Z": 15 record(s)
```

## Validation Queries (Post-DML)

See: `01-planning/incident_reports_migration_validation.sql`

```sql
-- Record counts (should match)
SELECT COUNT(*) FROM incident_scalable_data;
SELECT COUNT(*) FROM company_incident_scalable;

-- Mapping distribution for incident_scalable_data
SELECT status, workflow_stage, COUNT(*) as cnt
FROM incident_scalable_data
GROUP BY status, workflow_stage
ORDER BY status;

-- Mapping distribution for company_incident_scalable
SELECT status, status_revamp, source, is_archived, COUNT(*) as cnt
FROM company_incident_scalable
GROUP BY status, status_revamp, source, is_archived
ORDER BY status;

-- Unmapped records (expect 0 or known exceptions)
SELECT COUNT(*) FROM incident_scalable_data WHERE workflow_stage IS NULL;
SELECT COUNT(*) FROM company_incident_scalable WHERE status_revamp IS NULL;

-- Source distribution
SELECT source, COUNT(*) FROM company_incident_scalable GROUP BY source;

-- Archived records
SELECT COUNT(*) FROM company_incident_scalable WHERE is_archived = 1;
```

## Rollback Strategy

- **Primary:** The command is idempotent - fix mapping logic and re-run
- **Secondary:** Set new columns back to NULL:
  ```sql
  UPDATE incident_scalable_data SET workflow_stage = NULL;
  UPDATE company_incident_scalable
  SET status_revamp = NULL, source = NULL, is_archived = NULL;
  ```
- **Note:** Legacy columns are untouched, so existing functionality continues working

## Cleanup Phase (1 month after DML migration)

Separate migration to execute after stabilization period:

```sql
-- 1. Rename legacy columns (per AGENTS.md § 6)
ALTER TABLE company_incident_scalable
  CHANGE COLUMN status status_delete_me CHAR(2);
ALTER TABLE incident_scalable_data
  CHANGE COLUMN status status_delete_me VARCHAR(20);

-- 2. After 1 month, drop legacy columns
ALTER TABLE company_incident_scalable DROP COLUMN status_delete_me;
ALTER TABLE incident_scalable_data DROP COLUMN status_delete_me;
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    MIGRATION FLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │ incident_        │         │ company_         │              │
│  │ scalable_data    │◄────────│ incident_        │              │
│  │                  │  1:1    │ scalable         │              │
│  └────────┬─────────┘         └────────┬─────────┘              │
│           │                            │                         │
│           ▼                            ▼                         │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │ Legacy Fields    │         │ Legacy Fields    │              │
│  │ • status (kept)  │         │ • status (kept)  │              │
│  └────────┬─────────┘         └────────┬─────────┘              │
│           │                            │                         │
│           │  MAPPING                   │  MAPPING                │
│           ▼                            ▼                         │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │ New Fields       │         │ New Fields       │              │
│  │ • workflow_stage │         │ • status_revamp  │              │
│  │   (ENUM)         │         │ • source (ENUM)  │              │
│  │                  │         │ • is_archived    │              │
│  │                  │         │   (BOOLEAN)      │              │
│  └──────────────────┘         └──────────────────┘              │
│                                                                  │
│  ARCHIVED_LEGACY_STATUSES = ['D', '-1']                          │
│  → is_archived = 1 on company_incident_scalable                  │
│  → workflow_stage = 'Resolved' on incident_scalable_data         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Processing Strategy:
• Cursor-based pagination (id > :lastId)
• Transactional batches (1000 records default)
• Idempotent (WHERE new_field IS NULL)
• Entity constants for all status values
```

## Migration Commands Reference

### Check migration status
```bash
kool run console doctrine:migrations:status
```

### Execute DDL migration (if not done)
```bash
kool run migrations
```

### Test DML command
```bash
kool run console ir-configuration:populate-revamp-status --dry-run --limit=100
```

### Execute DML command
```bash
kool run console ir-configuration:populate-revamp-status --commit-size=1000
```

## Production Execution Checklist

- [ ] DDL migration executed and verified
- [ ] Database backup created (if < 1 month old)
- [ ] Dry-run executed successfully: `--dry-run --limit=1000`
- [ ] Reviewed dry-run logs for unmapped values
- [ ] Stakeholders notified (if downtime expected)
- [ ] Execute migration: `kool run console ir-configuration:populate-revamp-status`
- [ ] Monitor logs during execution
- [ ] Run validation queries after completion
- [ ] Upload evidence to JIRA (record counts, sample data)
- [ ] Confirm with QA
