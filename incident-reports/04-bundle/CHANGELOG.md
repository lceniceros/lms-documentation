# Changelog - IncidentReportsAPIBundle

All notable changes to this bundle will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### LSFB-64913 - Incident Status Migration Command (2026-02-13)

#### Added
- `PopulateRevampStatusCommand` (`ir-configuration:populate-revamp-status`)
  - Migrates legacy `status` fields to new ENUM columns across two tables
  - Step 1: `incident_scalable_data.status` → `workflow_stage`
  - Step 2: `company_incident_scalable.status` → `status_revamp`, `source`, `is_archived`
  - `ARCHIVED_LEGACY_STATUSES` (`D`, `-1`) derive both `is_archived = 1` and `workflow_stage = 'Resolved'`
  - Cursor-based pagination, transactional batches, dry-run mode
  - Uses entity constants (`IncidentScalableData::*`, `CompanyIncidentScalable::*`)
  - Yoda-style conditions, `private const` for all magic values
- DDL Migration `Version20260203173237.php`
  - `workflow_stage` ENUM on `incident_scalable_data` (ALGORITHM=INSTANT)
  - `source`, `status_revamp`, `is_archived` on `company_incident_scalable` (ALGORITHM=INSTANT)
  - Idempotent via `information_schema.COLUMNS` checks
  - Pattern B: explicit `$this->connection->executeStatement()` with SET SESSION timeouts
- 32+ unit tests covering all mappings, batching, dry-run, limits, unmapped values, and error handling

#### Changed
- Command renamed from `app:migrate-incident-status` to `ir-configuration:populate-revamp-status`
- Class renamed from `MigrateIncidentStatusCommand` to `PopulateRevampStatusCommand`
- `archived_date DATETIME` replaced with `is_archived BOOLEAN`
- `status_revamp` ENUM simplified from `('Active','Closed','Archived')` to `('Active','Closed')`
- `workflow_stage` ENUM: removed `'Archived'` value
- D/-1 statuses now map to `status_revamp = 'Closed'` + `is_archived = 1` (was `'Archived'`)
- Replaced deprecated DBAL APIs (`fetchColumn`, `FetchMode`, `Statement` chain) with `fetchOne`/`fetchAllAssociative`
- Replaced literal status values with entity constants throughout
- Replaced `return 0/1` with `self::COMMAND_EXECUTION_OK/ERROR`

### Phase 4 - Repository & DTO Implementation (Planned)
- IncidentReportDTO with 24 fields (incidentId, incidentNumber, status, workflowStage, etc.)
- IncidentReportsRepository with CTE-optimized query
- PermissionCalculator service for server-side action calculation
- Core list endpoint: `GET /ajax/spa/incident-reports/list`
- Date range filters (4 filters: incident, report, resolution, lastUpdated)
- Pagination and sorting support

### Phase 5 - Additional Endpoints (Planned)
- Details endpoint: `GET /ajax/spa/incident-reports/{id}`
- Update status: `PUT /ajax/spa/incident-reports/{id}/status`
- Archive/Restore: `POST /ajax/spa/incident-reports/{id}/{archive|restore}`
- Preview PDF: `GET /ajax/spa/incident-reports/{id}/preview`
- Catalog endpoints: Types, Subtypes, Workflow Stages

---

## [1.0.0-alpha] - 2026-01-28

### Phase 3 - Bundle Scaffolding (Complete)

#### Added
- Bundle class `IncidentReportsAPIBundle.php`
- DependencyInjection extension (`IncidentReportsAPIExtension.php`)
- DependencyInjection configuration (`Configuration.php`)
- Services configuration with full autowiring (`config/services.yml`)
- Modern bundle structure (`config/` directory at bundle root)
- Empty directory structure for future implementation:
  - `src/Controller/` - REST API controllers
  - `src/Service/` - Business logic services
  - `src/Repository/` - Database repositories
  - `src/DTO/` - Data Transfer Objects
  - `src/Policy/` - Permission policies
- Test directory structure:
  - `tests/Unit/MedTrainer/IncidentReportsAPIBundle/`
  - `tests/Functional/MedTrainer/IncidentReportsAPIBundle/`
- Bundle documentation:
  - `README.md` - Developer documentation (400+ lines)
  - `CHANGELOG.md` - This file

#### Configuration
- Autowiring enabled for all services
- Service visibility: `public: true` (consistent with existing MedTrainer bundles)
- Auto-configuration enabled
- Resource-based service registration (Controller, Service, Repository, Policy)
- Controllers tagged with `controller.service_arguments`

#### Decisions
1. **Bundle Name**: `IncidentReportsAPIBundle` (not `WorkflowTableBundle`) - better reflects REST API purpose
2. **Service Visibility**: `public: true` - matches existing MedTrainer patterns (not modern `public: false`)
3. **Directory Structure**: Modern Symfony 4.4 (`config/` not `Resources/config/`)
4. **Health Check**: Skipped in scaffolding phase - verified via console commands
5. **Routing**: Deferred to Phase 4 when controllers are implemented

#### Verification
- Bundle verified via console commands (cache:clear, debug:container)
- No HTTP endpoints in scaffolding phase
- 11 files created:
  - 4 PHP files (Bundle, Extension, Configuration, + future controllers)
  - 1 YAML file (services.yml)
  - 6 .gitkeep files (empty directories)
  - 2 documentation files (README, CHANGELOG)

#### Bundle Registration
- Registered in `AppKernel.php` (line 138)
- Namespace: `MedTrainer\IncidentReportsAPIBundle`
- Path: `symfony/src/MedTrainer/IncidentReportsAPIBundle/`

---

## [Pre-release] - 2026-01-27

### Phase 1 - Database Foundation (Complete)

#### Added
- 4 database migrations (executed successfully)
- New fields in `incident_scalable_data` table:
  - `status` (VARCHAR 20) - Business-facing status
  - `workflow_stage` (VARCHAR 50) - Technical workflow position
  - `archived_date` (DATETIME NULL) - Archive timestamp
  - `source` (VARCHAR 20) - Creation source
- Renamed field: `status` → `legacy_status` (deprecated)
- 5 new indexes for performance:
  - `idx_status` (on `status`)
  - `idx_workflow_stage` (on `workflow_stage`)
  - `idx_archived_date` (on `archived_date`)
  - `idx_source` (on `source`)
  - `idx_status_workflow` (composite on `status`, `workflow_stage`)

#### Changed
- 232,308 records migrated with status mapping:
  - Legacy `1` → `archived`
  - Legacy `2` → `escalated`
  - Legacy `3` → `resolved`
  - Legacy `I` → `escalated`
  - Legacy `D`, `0` → `draft`
- Entity `IncidentScalableData.php` updated with 5 new properties
- Added getters/setters with PHP 7.2 type hints
- PHPDoc annotations for all new properties

#### Fixed
- Handled orphaned records (1 record without `company_incident_scalable`)
- Added fallback for missing `incident_conversations` table in test environment
- MySQL 8 ALGORITHM compatibility (INPLACE → COPY for type changes)

#### Database Statistics
- Total records migrated: 232,308
- Migration duration: ~15 minutes
- Zero data loss
- All integrity checks passed

---

## [0.1.0] - 2026-01-26

### Planning Phase (Complete)

#### Added
- Master implementation plan (850+ lines)
- Software design document (backend architecture)
- OpenAPI 3.0 specification (8 endpoints)
- CTE algorithm documentation
- Date filters implementation guide
- Database migration strategy
- Testing strategy (35 test cases)

#### Defined
- 8 implementation phases (78-105 days estimated)
- Technology stack: PHP 7.1.33, Symfony 4.4, MySQL 8.0.15
- API path convention: `/ajax/spa/incident-reports/*`
- Feature flag: `incident_reports_table_v4_enabled`
- Performance targets: p95 < 250ms, p99 < 500ms

---

## Legend

- **Added**: New features, files, or functionality
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Now removed features
- **Fixed**: Bug fixes
- **Security**: Security fixes

---

## Version Naming Convention

- **0.x.x**: Planning and documentation
- **1.0.0-alpha**: Scaffolding phase (current)
- **1.0.0-beta**: Repository & DTO implementation (Phase 4)
- **1.0.0-rc1**: Core endpoint complete (Phase 4)
- **1.1.0**: Additional endpoints (Phase 5)
- **2.0.0**: Frontend integration complete (Phase 6)
- **2.1.0**: Production deployment with feature flag (Phase 8)

---

## Contributing

See `symfony/docs/incident-reports-implementation-plan.md` for development guidelines and phase roadmap.

**Epic**: LSFB-62813  
**Current Phase**: Phase 3 Complete → Ready for Phase 4  
**Next Milestone**: Repository & DTO Implementation
