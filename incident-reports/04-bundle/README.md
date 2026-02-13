# IncidentReportsAPIBundle

REST API bundle for Incident Reports workflow table v4.

**Epic**: LSFB-62813 - Incident Reports: Workflow table revamp  
**Current Version**: 1.0.0-alpha (scaffolding phase)  
**Symfony Version**: 4.4  
**PHP Version**: 7.2 syntax (7.1.33 runtime)  
**Last Updated**: 2026-01-28

---

## Overview

This bundle provides REST API endpoints for the new Incident Reports workflow table, implementing CTE-based query optimization and server-side permission calculation.

**Key Features**:
- CTE-optimized queries (98% reduction: 201→2 queries)
- Server-side permission calculation (canEdit, canDelete, canRestore, canDownload)
- Full autowiring with modern Symfony 4.4 structure
- Feature flag support for gradual rollout (`incident_reports_table_v4_enabled`)

---

## Bundle Structure

```
src/MedTrainer/IncidentReportsAPIBundle/
├── config/
│   └── services.yml          # Service configuration (autowiring)
├── src/
│   ├── Controller/          # REST API controllers (empty - Phase 4)
│   ├── Service/             # Business logic services (empty - Phase 4)
│   ├── Repository/          # Database repositories (empty - Phase 4)
│   ├── DTO/                 # Data Transfer Objects (empty - Phase 4)
│   ├── Policy/              # Permission policies (empty - Phase 4)
│   ├── DependencyInjection/
│   │   ├── Configuration.php
│   │   └── IncidentReportsAPIExtension.php
│   └── IncidentReportsAPIBundle.php
├── README.md                # This file
└── CHANGELOG.md             # Version history

tests/
├── Unit/MedTrainer/IncidentReportsAPIBundle/
└── Functional/MedTrainer/IncidentReportsAPIBundle/
```

---

## Configuration

### Services (config/services.yml)

**Autowiring**: Enabled for all services  
**Visibility**: `public: true` (project standard - consistent with existing MedTrainer bundles)  
**Auto-configuration**: Enabled

All services in `Controller/`, `Service/`, `Repository/`, and `Policy/` namespaces are automatically registered.

**Example Configuration:**
```yaml
services:
  _defaults:
    public: true         # Legacy MedTrainer pattern
    autowire: true       # Enable constructor injection
    autoconfigure: true  # Auto-tag services

  MedTrainer\IncidentReportsAPIBundle\Service\:
    resource: '../src/Service/'

  MedTrainer\IncidentReportsAPIBundle\Repository\:
    resource: '../src/Repository/'

  MedTrainer\IncidentReportsAPIBundle\Policy\:
    resource: '../src/Policy/'

  MedTrainer\IncidentReportsAPIBundle\Controller\:
    resource: '../src/Controller/'
    tags: ['controller.service_arguments']
```

---

## Current Status (Phase 3: Scaffolding Complete)

### Completed ✅
- [x] Bundle class created
- [x] DependencyInjection setup (Extension + Configuration)
- [x] Services configuration with autowiring
- [x] Modern directory structure (`config/` not `Resources/config/`)
- [x] Empty directories for future implementation (with .gitkeep)
- [x] Test directories created (Unit + Functional)
- [x] Bundle registered in AppKernel.php (line 138)
- [x] Documentation (README + CHANGELOG)

### Pending (Phase 4+) ⏳
- [ ] IncidentReportDTO (24 fields)
- [ ] IncidentReportsRepository (CTE-optimized query)
- [ ] PermissionCalculator (server-side logic)
- [ ] ListController (core list endpoint)
- [ ] 7 additional API endpoints

---

## API Endpoints (Planned - Phase 4+)

**Path Convention**: `/ajax/spa/incident-reports/*`

### Core Endpoints (Phase 4)
- `GET /ajax/spa/incident-reports/list` - List incidents with filters, sorting, pagination

### Additional Endpoints (Phase 5)
- `GET /ajax/spa/incident-reports/{id}` - Get incident details
- `PUT /ajax/spa/incident-reports/{id}/status` - Update incident status
- `POST /ajax/spa/incident-reports/{id}/archive` - Archive incident
- `POST /ajax/spa/incident-reports/{id}/restore` - Restore archived incident
- `GET /ajax/spa/incident-reports/{id}/preview` - Preview incident PDF
- `GET /ajax/spa/incident-reports/catalogs/types` - Get incident types catalog
- `GET /ajax/spa/incident-reports/catalogs/subtypes` - Get incident subtypes catalog

**Note**: Routing configuration will be added in Phase 4 when controllers are implemented.

---

## Verification

### Verify Bundle Registration
```bash
# Clear cache
kool run console cache:clear

# Verify bundle is loaded
kool run console debug:container | grep IncidentReports
```

**Expected**: Bundle services appear in container registry

### Verify Directory Structure
```bash
find symfony/src/MedTrainer/IncidentReportsAPIBundle -type f | sort
```

**Expected**: 11 files (4 PHP + 1 YAML + 6 .gitkeep)

### Check for Errors
```bash
# Check Symfony console works
kool run console --env=dev

# Check for PHP syntax errors
kool run console lint:yaml symfony/src/MedTrainer/IncidentReportsAPIBundle/config/
```

**Expected**: No errors

---

## Development Guidelines

### PHP Version Constraints
**Runtime**: PHP 7.1.33  
**Syntax**: PHP 7.2 compatible

**✅ Allowed**:
- `declare(strict_types=1);`
- Return type declarations (`:void`, `:JsonResponse`, `:array`)
- Scalar type hints (`string`, `int`, `bool`, `array`)
- Nullable types (`?string`, `?int`)
- PHPDoc for complex types (`@var`, `@param`, `@return`)

**❌ NOT Allowed**:
- Typed class properties: `private string $foo;` (PHP 7.4+)
- Arrow functions: `fn($x) => $x * 2` (PHP 7.4+)
- Null coalescing assignment: `$x ??= 'default'` (PHP 7.4+)
- Union types: `string|int` (PHP 8.0+)
- Attributes: `#[Route("/path")]` (PHP 8.0+)

### Service Pattern (AGENTS.md Compliance)

**Single `__invoke()` Entry Point**:
```php
<?php

declare(strict_types=1);

namespace MedTrainer\IncidentReportsAPIBundle\Service;

class GetIncidentListService
{
    public function __invoke(IncidentListQuery $query): array
    {
        // Business logic here
        return $result;
    }
}
```

**Constructor Injection via Autowiring**:
```php
<?php

declare(strict_types=1);

namespace MedTrainer\IncidentReportsAPIBundle\Service;

use MedTrainer\IncidentReportsAPIBundle\Repository\IncidentReportsRepository;

class GetIncidentListService
{
    /** @var IncidentReportsRepository */
    private $repository;

    public function __invoke(IncidentReportsRepository $repository)
    {
        $this->repository = $repository;
    }
    
    public function __invoke(IncidentListQuery $query): array
    {
        // Use $this->repository
    }
}
```

### Testing

**Unit Tests**: `symfony/tests/Unit/MedTrainer/IncidentReportsAPIBundle/`
- Test services, repositories, policies in isolation
- Use mocks for dependencies
- No database access

**Functional Tests**: `symfony/tests/Functional/MedTrainer/IncidentReportsAPIBundle/`
- Test controllers with real database
- Test end-to-end scenarios
- Use test database

**Run Tests**:
```bash
# Run all bundle tests
kool run phpunit tests/Unit/MedTrainer/IncidentReportsAPIBundle/
kool run phpunit tests/Functional/MedTrainer/IncidentReportsAPIBundle/

# Run specific test
kool run phpunit tests/Unit/MedTrainer/IncidentReportsAPIBundle/Service/GetIncidentListServiceTest.php
```

### Code Quality

**Before Committing**:
```bash
# Run PHP CodeSniffer
kool run phpcs

# Auto-fix code style issues
kool run phpcbf

# Run PHPStan (static analysis)
kool run composer phpstan
```

**Standards**: PSR-2/PSR-12

---

## Database Schema

### Main Entity: IncidentScalableData

**Location**: `symfony/src/PlanetMedia/MedTrainerBundle/Entity/IncidentScalableData.php`

**New Fields (Phase 1 - Complete)**:
- `status` (VARCHAR 20) - Business-facing status (draft, in_progress, resolved, archived)
- `workflow_stage` (VARCHAR 50) - Technical workflow position (draft, new, initiated, escalated, resolved, archived)
- `archived_date` (DATETIME NULL) - When incident was archived
- `source` (VARCHAR 20) - How incident was created (web, mobile, api, import)
- `legacy_status` (VARCHAR 10) - Deprecated old status field (for backward compatibility)

**Indexes**:
- `idx_status` - On `status` field
- `idx_workflow_stage` - On `workflow_stage` field
- `idx_archived_date` - On `archived_date` field
- `idx_source` - On `source` field
- `idx_status_workflow` - Composite on (`status`, `workflow_stage`)

---

## Related Documentation

### Master Documents
- **Implementation Plan**: `symfony/docs/incident-reports-implementation-plan.md` (850 lines)
- **Software Design**: `symfony/docs/incident-reports-backend-design.md`
- **CTE Algorithm**: `symfony/docs/incident-reports-cte-implementation-plan.md`
- **OpenAPI Spec**: `symfony/docs/swagger/incident-reports.yaml`
- **Date Filters**: `symfony/docs/incident-reports-date-filters-implementation.md`
- **Algorithms**: `symfony/docs/incident-reports-algorithms-explained.md`
- **Documentation Index**: `symfony/docs/incident-reports-README.md`

### Project Constraints
- **AGENTS.md**: Root-level AI execution protocol and constraints
- **PHP Runtime**: 7.1.33 (write code for 7.2 syntax)
- **Symfony Version**: 4.4 (targeting eventual 5.4 upgrade)
- **Database**: MySQL 8.0.15

---

## Architecture Decisions

### Why `public: true` for Services?
**Decision**: Use `public: true` instead of modern Symfony's `public: false`

**Reason**: Consistency with existing MedTrainer bundles (e.g., `EscalationMatrixAPIBundle`). This is a legacy codebase pattern where all services are publicly accessible from the container.

**Trade-off**: Slightly less optimal than modern Symfony best practices, but maintains consistency across the codebase.

---

### Why Modern Bundle Structure (`config/` not `Resources/config/`)?
**Decision**: Use `config/` directory at bundle root, not `Resources/config/`

**Reason**: Modern Symfony 4.4 structure. Easier to navigate, cleaner separation. Extension path adjusted accordingly: `__DIR__/../../config`.

**Trade-off**: Differs from some older MedTrainer bundles, but represents best practice for new bundles.

---

### Why No Health Check Endpoint in Scaffolding?
**Decision**: Skip demo/health check endpoint in scaffolding phase

**Reason**: No value in temporary demo code. Verification can be done via console commands (`debug:container`, `cache:clear`). Real endpoints will be added in Phase 4.

**Trade-off**: Less immediate "it works" feedback, but cleaner codebase with no throwaway code.

---

## Troubleshooting

### Bundle Not Loading
```bash
# Clear cache
kool run console cache:clear --no-warmup
kool run console cache:warmup

# Check bundle registration
grep -n "IncidentReportsAPIBundle" symfony/app/AppKernel.php
# Expected: Line 138
```

### Services Not Autowiring
```bash
# Verify services.yml syntax
kool run console lint:yaml symfony/src/MedTrainer/IncidentReportsAPIBundle/config/services.yml

# Check service container
kool run console debug:container MedTrainer\\IncidentReportsAPIBundle
```

### PHP Version Errors
**Error**: `syntax error, unexpected 'string' (T_STRING)`  
**Cause**: Using PHP 7.4+ syntax (typed properties, arrow functions)  
**Fix**: Remove typed properties, use PHPDoc instead

```php
// ❌ Wrong (PHP 7.4+)
private string $name;

// ✅ Correct (PHP 7.2)
/** @var string */
private $name;
```

---

## Contact & Support

**Epic**: LSFB-62813  
**Phase**: 3 of 8 (Scaffolding Complete)  
**Status**: Ready for Phase 4 implementation  
**Slack Channel**: `#incident-reports-revamp`  
**JIRA Board**: LMS New Features / Bugs (LSFB)

---

## Version History

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history.

**Current Version**: 1.0.0-alpha (Scaffolding Phase Complete)  
**Next Version**: 1.0.0-beta (Phase 4 - Repository & DTO Implementation)
