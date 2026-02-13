# Incident Reports Workflow Table - Documentation Index

**Epic:** LSFB-62813 - Incident Reports: Workflow table revamp  
**Last Updated:** February 09, 2026  
**Current Phase:** Phase 1 DML Migration Complete - Ready for Phase 4

---

## Project Status

**Overall Progress**: 30% (Phase 1 DDL+DML complete, Phase 3 complete)  
**Last Milestone**: DML Migration Command implemented and tested (2026-02-09)  
**Next Milestone**: Repository & DTO implementation (Phase 4)

### Completed Phases ✅

#### 1. Phase 1: Database Foundation (2026-01-27 to 2026-02-09)

**DDL Migration (2026-02-03):**
- ✅ Migration `Version20260203173237.php` executed successfully
- ✅ Added nullable columns to both tables for safe migration

**Schema Changes:**

| Table | Column | Type | Purpose |
|-------|--------|------|---------|
| `incident_scalable_data` | `workflow_stage` | ENUM | Technical workflow position |
| `company_incident_scalable` | `status_revamp` | ENUM | Business-facing status |
| `company_incident_scalable` | `source` | ENUM | Report origin (Created/Uploaded) |
| `company_incident_scalable` | `archived_date` | DATETIME | Archive timestamp |

**DML Migration Command (2026-02-09):**
- ✅ Created `app:migrate-incident-status` console command
- ✅ Migrates ~470K records (235,750 + 234,640)
- ✅ Cursor-based pagination for performance
- ✅ Transactional batching (default 1000 records)
- ✅ Dry-run mode for validation
- ✅ Idempotent (safe to re-run)
- ✅ Progress bars and detailed summary
- ✅ Warning logs for unmapped values
- ✅ Code standards pass (phpcs)
- ✅ Documentation and verification queries created

**Data Mapping:**

*incident_scalable_data (`status` → `workflow_stage`):*
| Legacy | New |
|--------|-----|
| `'0'` | `'Draft'` |
| `'1'` | `'New'` |
| `'I'` | `'Initiated'` |
| `'2'` | `'Escalated'` |
| `'3'` | `'Resolved'` |
| `'5'` | `'Resolution rejected'` |
| `'6'` | `'Waiting resolution approval'` |

*company_incident_scalable (`status` → `status_revamp`, `source`, `archived_date`):*
| Legacy | status_revamp | source | archived_date |
|--------|---------------|--------|---------------|
| `'S'`, `'1'` | `'Active'` | `'Created'` | NULL |
| `'D'`, `'-1'` | `'Archived'` | `'Created'` | from `update_date` |
| `'U'` | `'Closed'` | `'Uploaded'` | NULL |

#### 2. Phase 3: Bundle Scaffolding (2026-01-28)
- ✅ Bundle structure created (`IncidentReportsAPIBundle`)
- ✅ Autowiring configured (`public: true` per project standards)
- ✅ Directory structure established (Controller, Service, Repository, DTO, Policy)
- ✅ Test directories created (Unit + Functional)
- ✅ Modern Symfony 4.4 structure (`config/` directory)
- ✅ Bundle documentation (README + CHANGELOG)
- ✅ 11 files created (4 PHP + 1 YAML + 6 .gitkeep)

### In Progress 🔄

**Phase 2: Legacy Code Updates** - Deferred to Phase 4
- 73 locations identified that reference old `status` field
- Will be updated incrementally during Phase 4 implementation
- Low risk: dual-read pattern supported

### Upcoming Phases ⏳

- **Phase 4**: Repository & DTO Implementation (10-12 days)
- **Phase 5**: Additional API Endpoints (8-10 days)
- **Phase 6**: Frontend Implementation (30-40 days)
- **Phase 7**: Testing & QA (10-15 days)
- **Phase 8**: Deployment with Feature Flag (2-3 days)

---

## Bundle Overview

### IncidentReportsAPIBundle

**Location**: `symfony/src/MedTrainer/IncidentReportsAPIBundle/`  
**Namespace**: `MedTrainer\IncidentReportsAPIBundle`  
**Bundle Documentation**: See `symfony/src/MedTrainer/IncidentReportsAPIBundle/README.md`

**Key Features:**
- ✅ Modern Symfony 4.4 structure (`config/` directory)
- ✅ Full autowiring enabled (`public: true` per project standards)
- ✅ PHP 7.2 syntax compatible (7.1.33 runtime)
- ✅ Empty directory structure ready for Phase 4 implementation
- ✅ Test directories established (Unit + Functional)

**Current Status**: Scaffolding complete, awaiting Phase 4 implementation

**Endpoints**: None yet (will be added in Phase 4)  
**Path Convention**: `/ajax/spa/incident-reports/*`

---

## Documentation Structure

### 1. Core Design Documents

#### [incident-reports-backend-design.md](./incident-reports-backend-design.md)
**Software Design Document (SDD)** - Primary technical specification

**Contents:**
- API endpoints specification (list, details, actions, catalogs)
- Request/Response contracts with examples
- DTO definitions and field mappings
- Enumerations (status, workflowStage, source, etc.)
- Date filtering pattern
- RBAC and permission model
- Feature flag strategy
- Performance targets (p95 < 250ms, p99 < 500ms)

**Audience:** Backend engineers, QA, Product

---

#### [swagger/incident-reports.yaml](./swagger/incident-reports.yaml)
**OpenAPI 3.0 Specification** - Formal API contract

**Contents:**
- All endpoints with request/response schemas
- Query parameters with validation rules
- Error response definitions (400/403/404/409)
- DTO schemas with examples
- Catalog endpoint specifications

**Usage:** Import into Swagger UI for interactive API documentation

---

### 2. Discovery Phase Documents

#### [05-discovery/](./05-discovery/)
**Discovery & Analysis Phase Documentation** - Business requirements, technical findings, and migration strategies

**Contents:**
- Actions Matrix consolidated reference (PRIMARY permission rules source)
- Business capabilities and requirements
- Migration guide and refactoring strategy
- Database ERD and schema design
- Multiple views of actions matrix (product, technical, analysis)

**Files:** 11 documents, ~236KB  
**Key Document:** `IncidentTracking_ActionsMatrix_Consolidated.md` - Definitive actions permission logic

**See:** [05-discovery/README.md](./05-discovery/README.md) for detailed index

---

### 3. Implementation Guides

#### [01-planning/dml-migration-command.md](./01-planning/dml-migration-command.md)
**DML Migration Command Documentation** - Console command for status data migration

**Contents:**
- Command usage and options (`app:migrate-incident-status`)
- Data mapping tables (legacy → new fields)
- Execution phases and status tracking
- Sample output and expected results
- Rollback strategy
- Production execution checklist

**Related Files:**
- Validation queries: `01-planning/incident_reports_migration_validation.sql`
- DDL Migration: `symfony/src/Migrations/Version20260203173237.php`
- Command: `symfony/src/MedTrainer/IncidentReportsAPIBundle/Command/MigrateIncidentStatusCommand.php`

---

#### [02-technical/date-filters-implementation.md](./02-technical/date-filters-implementation.md)
**Date Filters Implementation Guide** - Step-by-step implementation for 4 date range filters

**Contents:**
- DateRange class usage patterns
- Database field mappings (incidentDate, reportDate, resolutionDate, lastUpdatedDate)
- Code examples for Controller, Repository, Service
- Unit and functional test templates
- Request parameter format examples
- Effort estimation (~5.5 hours)

**Related Stories:** LSFB-64416, LSFB-64418

---

#### [02-technical/cte-implementation-plan.md](./02-technical/cte-implementation-plan.md)
**CTE Query Optimization Plan** - Solves N+1 problem with Common Table Expressions

**Contents:**
- Three-phase CTE algorithm (pre-aggregation, join, projection)
- Native SQL query templates
- Performance benchmarks (98% query reduction, 75% latency improvement)
- Trade-offs and considerations
- Migration from DQL to native SQL

**Related Story:** LSFB-64415

---

#### [01-planning/database-migration-plan.md](./01-planning/database-migration-plan.md)
**Database Migration Strategy** - Schema changes and data mapping

**Contents:**
- DDL migration details (Version20260203173237.php)
- DML command reference (app:migrate-incident-status)
- Legacy → New field mapping
- Validation queries reference
- Rollback procedures

**Related Story:** LSFB-64913

---

### 4. Algorithm Explanations

#### [02-technical/algorithms-explained.md](./02-technical/algorithms-explained.md)
**Non-Trivial Algorithms Deep Dive**

**Contents:**
- **CTE-Based Query Optimization:** O(n) → O(1) database hits
- **Server-Side Actions Resolution:** Rule-based permission evaluation
- Complexity analysis
- Implementation pseudocode
- Visual diagrams

**Audience:** Senior engineers, architects

---

#### [incident-reports-cte-summary.md](./incident-reports-cte-summary.md)
**CTE Algorithm Quick Reference**

**Contents:**
- High-level overview of the CTE approach
- Query structure summary
- Key performance metrics
- When to use CTEs vs DQL

**Audience:** All engineers (quick reference)

---

## Related External Documents

### JIRA Stories

- **LSFB-62813:** Epic - Incident Reports: Workflow table revamp
- **LSFB-64415:** Create main table (list endpoint core)
- **LSFB-64416:** Main filters (status, location, department, dates)
- **LSFB-64417:** Action buttons (permission calculation)
- **LSFB-64418:** More filters + catalog endpoints
- **LSFB-64419:** Table section backend support
- **LSFB-64420:** Actions (archive/restore/preview)
- **LSFB-64913:** Data migration (status → workflow_stage)
- **LSFB-65185:** Backend activities (parent task with 8 subtasks)

### Confluence TDD

**URL:** *(Link to Confluence TDD document)*

**Contents:**
- Product requirements and acceptance criteria
- Frontend UI specifications (not our concern)
- User stories and workflows
- Estimated backend effort: 21 days

---

## Actions Matrix Reference

**Location:** `claude/irv3/context/discovery/IncidentTracking_ActionsMatrix_Consolidated.md`

**Contents:**
- Single source of truth for action permissions (Download/Delete/Restore/Edit)
- Status code mapping (Draft=0, New=1, Initiated=I, etc.)
- Matrix membership rules (RACI→R, Functional→F, Group→G)
- IR_EAR special case for editing resolved incidents
- Anonymous report protections

**Usage:** Reference when implementing `IncidentPermissionResolver` service

---

## Technology Stack

- **Backend:** PHP 7.1.33, Symfony 4.4, Doctrine ORM
- **Database:** MySQL 8.0.15
- **Frontend:** React 17 + TypeScript (handled by frontend team)
- **Testing:** PHPUnit 9.x
- **API Spec:** OpenAPI 3.0

---

## Architecture Patterns

### Bundle Structure
```
symfony/src/Incident/WorkflowTableBundle/
├── Controller/          # HTTP layer (slim, validation only)
├── Service/             # Business logic (single __invoke() entry)
├── Repository/          # Query builders with method chaining
├── Policy/              # Permission resolvers
├── FeatureFlag/         # Feature flag adapters
├── Request/             # Query objects (IncidentListQuery)
├── Response/            # DTOs (IncidentListItemDTO, PaginationDTO)
└── Resources/config/
    ├── services.yaml    # DI configuration
    └── routing.yaml     # Route definitions
```

### Key Design Principles

1. **Constructor DI only** - No service locator pattern
2. **Single `__invoke()` entry** - Services are single-purpose
3. **DTO boundaries** - No entity leaking to API
4. **Parameterized queries** - No SQL string concatenation
5. **CTE for N+1 prevention** - Pre-aggregate in database
6. **Server-side permissions** - Single source of truth
7. **Feature flag controlled** - Gradual rollout (5% → 25% → 50% → 100%)

---

## Testing Strategy

### Unit Tests
- **Location:** `symfony/tests/Unit/Incident/WorkflowTableBundle/`
- **Coverage:** Services, Policies, Query Objects
- **Target:** 25+ tests

### Functional Tests
- **Location:** `symfony/tests/Functional/Incident/WorkflowTableBundle/`
- **Coverage:** Controllers, End-to-end scenarios
- **Target:** 10+ tests

### Performance Tests
- **Tool:** Apache Bench or k6
- **Criteria:** 
  - p95 < 250ms
  - p99 < 500ms
  - 10k records dataset

---

## Deployment Strategy

### Phase 1: Migrations (Before Code)
1. Execute Migrations 1-4 (add columns, populate data)
2. Validate with test queries
3. Test legacy features (ensure no regression)

### Phase 2: Code Deployment
1. Deploy with feature flag **OFF**
2. Verify no errors in logs
3. Run smoke tests

### Phase 3: Feature Flag Rollout
1. Enable for 5% of users (monitor 24h)
2. Increase to 25% (monitor 24h)
3. Increase to 50% (monitor 24h)
4. Increase to 100% (full rollout)

### Phase 4: Final Migrations
1. Schedule maintenance window
2. Execute Migrations 5-7 (NOT NULL constraint + indexes)
3. Verify performance improvements

### Phase 5: Monitoring
- Error rates (should remain < 0.1%)
- API latency (p95/p99 metrics)
- Database query times
- User feedback via support tickets

---

## Common Patterns & Reusable Code

### DateRange Filtering
**Reference Implementation:**
- Class: `MedTrainer\SPABundle\Models\FilterValues\DateRange`
- Example: `symfony/src/MedTrainer/CourseAssignmentsBundle/src/QueryBuilder/AssignmentQueryBuilder.php` (lines 420-549)

### Repository Method Chaining
**Pattern:**
```php
public function filterByStatus(array $statuses): self
{
    if (empty($statuses)) {
        return $this;
    }
    
    $this->queryBuilder
        ->andWhere('incident.status IN (:statuses)')
        ->setParameter('statuses', $statuses);
    
    return $this;
}
```

### Service Invocation
**Pattern:**
```php
class GetIncidentListService
{
    public function __invoke(IncidentListQuery $query): array
    {
        // Business logic here
    }
}
```

---

## Glossary

| Term | Definition |
|------|------------|
| **CTE** | Common Table Expression - temporary result set for complex queries |
| **DTO** | Data Transfer Object - structured response format |
| **RBAC** | Role-Based Access Control |
| **IR_EAR** | Incident Report Edit After Resolution (special permission) |
| **Workflow Stage** | Technical position in incident lifecycle (draft, new, initiated, escalated, resolved, archived) |
| **Status** | Business-facing status shown to users |
| **Matrix** | Escalation matrix - defines user permissions per incident |
| **RACI** | Responsible, Accountable, Consulted, Informed (permission roles) |
| **N+1 Problem** | Performance issue where 1 main query triggers N additional queries |

---

## Questions & Support

- **Technical Lead:** *(TBD)*
- **Product Owner:** *(TBD)*
- **QA Lead:** *(TBD)*
- **Slack Channel:** `#incident-reports-revamp`
- **JIRA Board:** LMS New Features / Bugs (LSFB)

---

## Document History

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-27 | AI Assistant | Initial documentation structure |
| 2026-01-27 | AI Assistant | Added date filters implementation guide |
| 2026-01-27 | AI Assistant | Updated SDD and OpenAPI spec with date filter adjustments |
| 2026-02-03 | AI Assistant | DDL migration created (Version20260203173237.php) |
| 2026-02-09 | AI Assistant | DML migration command implemented (app:migrate-incident-status) |

---

## Next Steps

1. ✅ Documentation complete
2. ✅ Create DDL Migration (Phase 1 - 2026-02-03)
3. ✅ Create DML Migration Command (Phase 1 - 2026-02-09)
4. ✅ Scaffold IncidentReportsAPIBundle (Phase 3 complete)
5. ⏳ **Execute DML migration in production** (pending approval)
6. ⏳ Implement Repository & DTO (Phase 4 - awaiting approval)
7. ⏳ Build core list endpoint with CTE optimization
8. ⏳ Implement filters (including 4 date filters)
9. ⏳ Add action endpoints (archive/restore/preview)
10. ⏳ Write comprehensive tests (35 test cases)
11. ⏳ Frontend implementation (handed to frontend team)
12. ⏳ Deploy with feature flag rollout

**Current Phase:** Phase 1 DML Complete → Ready for Phase 4  
**Status:** DML command ready for production execution; awaiting approval to proceed with Phase 4

---

## Additional Resources

- **AGENTS.md:** AI execution protocol and constraints (root level)
- **PHP Version:** 7.1.33 runtime, 7.2 syntax compatibility required
- **Symfony Version:** 4.4 (targeting eventual migration to 5.4)
- **Code Style:** PSR-2/PSR-12 (enforced via phpcs)
- **Git Branch Convention:** `feature/LSFB-xxxxx-short-desc`
- **Commit Convention:** `LSFB-xxxxx: Descriptive message`
