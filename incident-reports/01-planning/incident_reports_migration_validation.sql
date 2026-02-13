-- ================================================================
-- LSFB-64913: Incident Status Migration Validation Queries
-- ================================================================
-- Purpose: Validate data migration from legacy status columns
--          to new revamp columns
-- Last Updated: 2026-02-09
-- Related: 01-planning/dml-migration-command.md
-- ================================================================


-- ================================================================
-- PRE-MIGRATION QUERIES (Run before DML command)
-- ================================================================

-- ----------------------------------------------------------------
-- QUERY 1: Total Record Counts (Baseline)
-- ----------------------------------------------------------------
SELECT 
    'incident_scalable_data' AS table_name,
    COUNT(*) AS total_records
FROM incident_scalable_data

UNION ALL

SELECT 
    'company_incident_scalable' AS table_name,
    COUNT(*) AS total_records
FROM company_incident_scalable;

-- Expected: ~235,750 and ~234,640 respectively


-- ----------------------------------------------------------------
-- QUERY 2: Legacy Status Distribution (Before Migration)
-- ----------------------------------------------------------------

-- incident_scalable_data.status distribution
SELECT 
    'incident_scalable_data' AS table_name,
    status AS legacy_status,
    CASE status
        WHEN '0' THEN 'Draft'
        WHEN '1' THEN 'New'
        WHEN 'I' THEN 'Initiated'
        WHEN '2' THEN 'Escalated'
        WHEN '3' THEN 'Resolved'
        WHEN '5' THEN 'Resolution rejected'
        WHEN '6' THEN 'Waiting resolution approval'
        ELSE 'Unknown'
    END AS expected_workflow_stage,
    COUNT(*) AS record_count
FROM incident_scalable_data
GROUP BY status
ORDER BY record_count DESC;

-- company_incident_scalable.status distribution
SELECT 
    'company_incident_scalable' AS table_name,
    status AS legacy_status,
    CASE status
        WHEN 'S' THEN 'Active'
        WHEN '1' THEN 'Active'
        WHEN 'D' THEN 'Archived'
        WHEN '-1' THEN 'Archived'
        WHEN 'U' THEN 'Closed'
        ELSE 'Unknown'
    END AS expected_status_revamp,
    COUNT(*) AS record_count
FROM company_incident_scalable
GROUP BY status
ORDER BY record_count DESC;


-- ================================================================
-- POST-MIGRATION QUERIES (Run after DML command)
-- ================================================================

-- ----------------------------------------------------------------
-- QUERY 3: Sample of Migrated Records (Spot Check)
-- ----------------------------------------------------------------
SELECT 
    ir.id AS report_id,
    ird.id AS detail_id,
    
    -- incident_scalable_data (detail table)
    ird.status AS detail_status_legacy,
    ird.workflow_stage AS detail_workflow_new,
    
    -- company_incident_scalable (main table)
    ir.status AS report_status_legacy,
    ir.status_revamp AS report_status_new,
    ir.source,
    ir.archived_date,
    ir.update_date
    
FROM company_incident_scalable ir
INNER JOIN incident_scalable_data ird 
    ON ir.id_incident_scalable_detail = ird.id
LIMIT 100;


-- ----------------------------------------------------------------
-- QUERY 4: Check for Unmapped Values (Should be 0)
-- ----------------------------------------------------------------

-- incident_scalable_data: records with status but no workflow_stage
SELECT 
    'incident_scalable_data' AS table_name,
    'Missing workflow_stage' AS issue,
    COUNT(*) AS count,
    GROUP_CONCAT(DISTINCT status) AS unmapped_statuses
FROM incident_scalable_data
WHERE status IS NOT NULL 
  AND workflow_stage IS NULL;

-- company_incident_scalable: records with status but no status_revamp
SELECT 
    'company_incident_scalable' AS table_name,
    'Missing status_revamp' AS issue,
    COUNT(*) AS count,
    GROUP_CONCAT(DISTINCT status) AS unmapped_statuses
FROM company_incident_scalable
WHERE status IS NOT NULL 
  AND status_revamp IS NULL;

-- company_incident_scalable: records with status but no source
SELECT 
    'company_incident_scalable' AS table_name,
    'Missing source' AS issue,
    COUNT(*) AS count
FROM company_incident_scalable
WHERE status IS NOT NULL 
  AND source IS NULL;


-- ----------------------------------------------------------------
-- QUERY 5: Verify Mapping Accuracy
-- ----------------------------------------------------------------

-- incident_scalable_data.workflow_stage mapping
SELECT 
    status AS legacy_status,
    workflow_stage AS new_workflow_stage,
    COUNT(*) AS record_count
FROM incident_scalable_data
WHERE workflow_stage IS NOT NULL
GROUP BY status, workflow_stage
ORDER BY status;

-- company_incident_scalable.status_revamp and source mapping
SELECT 
    status AS legacy_status,
    status_revamp AS new_status_revamp,
    source,
    COUNT(*) AS record_count,
    SUM(CASE WHEN archived_date IS NOT NULL THEN 1 ELSE 0 END) AS with_archived_date
FROM company_incident_scalable
WHERE status_revamp IS NOT NULL
GROUP BY status, status_revamp, source
ORDER BY status;


-- ----------------------------------------------------------------
-- QUERY 6: Validate Archived Date Logic
-- ----------------------------------------------------------------

-- archived_date should ONLY be set when status_revamp = 'Archived'
SELECT 
    status_revamp,
    COUNT(*) AS total_records,
    SUM(CASE WHEN archived_date IS NOT NULL THEN 1 ELSE 0 END) AS with_archived_date,
    SUM(CASE WHEN archived_date IS NULL THEN 1 ELSE 0 END) AS without_archived_date
FROM company_incident_scalable
WHERE status_revamp IS NOT NULL
GROUP BY status_revamp;

-- Check for invalid archived_date (set when status_revamp != 'Archived')
SELECT 
    COUNT(*) AS invalid_archived_dates,
    GROUP_CONCAT(DISTINCT status_revamp) AS affected_statuses
FROM company_incident_scalable
WHERE archived_date IS NOT NULL 
  AND status_revamp != 'Archived';

-- Expected: invalid_archived_dates = 0


-- ----------------------------------------------------------------
-- QUERY 7: Overall Migration Progress
-- ----------------------------------------------------------------
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

-- Expected: percent_complete = 100.00 for both tables


-- ----------------------------------------------------------------
-- QUERY 8: New Field Distributions
-- ----------------------------------------------------------------

-- workflow_stage distribution
SELECT 
    workflow_stage,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM incident_scalable_data WHERE workflow_stage IS NOT NULL), 2) AS percentage
FROM incident_scalable_data
WHERE workflow_stage IS NOT NULL
GROUP BY workflow_stage
ORDER BY count DESC;

-- status_revamp distribution
SELECT 
    status_revamp,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM company_incident_scalable WHERE status_revamp IS NOT NULL), 2) AS percentage
FROM company_incident_scalable
WHERE status_revamp IS NOT NULL
GROUP BY status_revamp
ORDER BY count DESC;

-- source distribution
SELECT 
    source,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM company_incident_scalable WHERE source IS NOT NULL), 2) AS percentage
FROM company_incident_scalable
WHERE source IS NOT NULL
GROUP BY source
ORDER BY count DESC;


-- ================================================================
-- EXPECTED MAPPING RESULTS (Reference)
-- ================================================================

-- incident_scalable_data.status -> workflow_stage
-- | Legacy | New                           |
-- |--------|-------------------------------|
-- | '0'    | 'Draft'                       |
-- | '1'    | 'New'                         |
-- | 'I'    | 'Initiated'                   |
-- | '2'    | 'Escalated'                   |
-- | '3'    | 'Resolved'                    |
-- | '5'    | 'Resolution rejected'         |
-- | '6'    | 'Waiting resolution approval' |

-- company_incident_scalable.status -> status_revamp
-- | Legacy | New        |
-- |--------|------------|
-- | 'S'    | 'Active'   |
-- | '1'    | 'Active'   |
-- | 'D'    | 'Archived' |
-- | '-1'   | 'Archived' |
-- | 'U'    | 'Closed'   |

-- company_incident_scalable.status -> source
-- | Legacy | source     |
-- |--------|------------|
-- | 'U'    | 'Uploaded' |
-- | other  | 'Created'  |


-- ================================================================
-- JIRA EVIDENCE EXPORT
-- ================================================================
-- 
-- To export results for JIRA:
--   1. Run queries 1-2 BEFORE migration
--   2. Save results as: pre_migration_baseline_YYYYMMDD.csv
--   3. Run DML migration command
--   4. Run queries 3-8 AFTER migration
--   5. Save results as: post_migration_validation_YYYYMMDD.csv
--   6. Attach both files to LSFB-64913
--
-- ================================================================
