# Incident Module Refactoring Strategy

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Time Estimation Summary](#time-estimation-summary)
3. [Core Principles](#core-principles)
4. [Phase 1: Service Interface Layer](#phase-1-service-interface-layer) - 16-24 hrs
5. [Phase 2: God Class Decomposition](#phase-2-god-class-decomposition) - 40-56 hrs
6. [Phase 3: Utility Class Migration](#phase-3-utility-class-migration) - 32-48 hrs
7. [Phase 4: Event-Driven Architecture](#phase-4-event-driven-architecture) - 24-32 hrs
8. [Phase 5: Repository Pattern Enhancement](#phase-5-repository-pattern-enhancement) - 16-24 hrs
9. [Phase 6: Legacy Decoupling](#phase-6-legacy-decoupling) - 24-40 hrs
10. [Rollback Procedures](#rollback-procedures)
11. [Testing Strategy](#testing-strategy)
12. [Success Criteria](#success-criteria)
13. [File Structure After Refactoring](#file-structure-after-refactoring)
14. [Appendix A: Incident List API Refactoring](#appendix-a-incident-list-api-refactoring)

---

## Executive Summary

This document outlines a **zero-downtime refactoring strategy** for the `symfony/src/Incident` module. Rollback is handled via **git revert + deploy** - no runtime feature flags or circuit breakers needed.

### Status Legend

| Icon | Meaning |
|------|---------|
| 🔴 | Critical - Immediate attention required |
| ⚠️ | High - Should be addressed soon |
| 🟡 | Medium - Plan to address |
| 🟢 | Low/Good - Acceptable state |
| ✅ | Passing/Complete |

### Current State Metrics

| Metric | Value |
|--------|-------|
| Total PHP Files | 93 (non-test) |
| Total Lines of Code | ~20,545 |
| Bundles | 3 (Configuration, Creation, Tracking) |
| Routes/Endpoints | 91 |
| External Consumers | 17 files across 4 bundles |

---

### Bundle-Level Metrics

#### ConfigurationBundle (Form & Type Configuration)

| Component | Count | Status |
|-----------|-------|--------|
| PHP Files | 36 | - |
| Controllers | 3 | ✅ Good |
| Services | 8 | ✅ Good |
| Entities | 12 | ✅ Good |
| Repositories | 5 | ✅ Good |
| Utilities | 2 (1,535 lines) | 🔴 Critical |

| Quality Metric | Value | Status |
|----------------|-------|--------|
| `__invoke()` Compliance | 87.5% (7/8) | ✅ Good |
| Files >300 lines | 4 files | ⚠️ High |
| Manual Instantiation | Minimal | ✅ Good |
| PlanetMedia Coupling | 7 files (19%) | 🟡 Medium |

**Critical Files:**
| File | Lines | Issue |
|------|-------|-------|
| CompanyIncidentUtil.php | 1,465 | 🔴 God object |
| FormAjaxController.php | 422 | ⚠️ Large controller |

**Reusability Level:** ⚠️ **Partial**
- ✅ Severity Level Services - Highly reusable (pure CRUD, proper DI)
- ⚠️ GetIncidentTypesByForm - Reusable with interface extraction
- 🔴 CompanyIncidentUtil - Not reusable (god object, mixed concerns)

---

#### CreationBundle (Report Creation & Evidence)

| Component | Count | Status |
|-----------|-------|--------|
| PHP Files | 21 | - |
| Controllers | 2 | ⚠️ High |
| Services | 5 | ✅ Good |
| Entities | 6 | ✅ Good |
| Repositories | 1 | ✅ Good |
| Utilities | 2 (2,718 lines) | 🔴 Critical |

| Quality Metric | Value | Status |
|----------------|-------|--------|
| `__invoke()` Compliance | 80% (4/5) | ✅ Good |
| Files >300 lines | 3 files | 🔴 Critical |
| Manual Instantiation | SEVERE | 🔴 Critical |
| PlanetMedia Coupling | 7 files (33%) | ⚠️ High |
| Internal Coupling | 8 files (38%) | 🔴 Critical |

**Critical Files:**
| File | Lines | Issue |
|------|-------|-------|
| CustomIncidentReportUtil.php | 1,709 | 🔴 God object + manual DI |
| PDFUtil.php | 1,009 | 🔴 Large + manual DI |
| DisplayAjaxController.php | 921 | 🔴 God controller |

**Reusability Level:** 🔴 **Low**
- ✅ Evidence Services - Moderately reusable (focused, proper DI)
- 🔴 CustomIncidentReportUtil - Not reusable (bypasses DI container)
- 🔴 PDFUtil - Not reusable (embedded business logic)

**Anti-Pattern Alert:**
```php
// CustomIncidentReportUtil.php - Manual instantiation bypasses DI
new ContainerBuilder();
new YamlFileLoader();
new ArrayUtil();
new TrackingActionsUtil();
new EmployeeUtil();
```

---

#### TrackingBundle (Workflow & Reporting)

| Component | Count | Status |
|-----------|-------|--------|
| PHP Files | 39 | - |
| Controllers | 2 | 🔴 Critical |
| Services | 16 | ✅ Good |
| Entities | 4 | ✅ Good |
| Repositories | 4 | ✅ Good |
| Utilities | 3 (1,195 lines) | ⚠️ High |
| Security Voters | 1 | ✅ Good |

| Quality Metric | Value | Status |
|----------------|-------|--------|
| `__invoke()` Compliance | 87.5% (14/16) | ✅ Good |
| Files >300 lines | 6 files | 🔴 Critical |
| Manual Instantiation | Minimal | ✅ Good |
| PlanetMedia Coupling | 18 files (46%) | 🔴 Critical |
| Internal Coupling | 7 files (18%) | 🟡 Medium |

**Critical Files:**
| File | Lines | Issue |
|------|-------|-------|
| TrackingActionsController.php | 2,357 | 🔴 God controller (32 methods) |
| TrackingActionsUtil.php | 687 | ⚠️ Large utility |
| GenerateIncidentReport.php | 609 | ⚠️ Large service |
| GenerateFullSummaryReport.php | 573 | ⚠️ Large service |

**Reusability Level:** 🟡 **Medium**
- ✅ GetIncidentReportByStatus - Highly reusable (clean query service)
- ✅ GetPermissionByRoleByIncident - Reusable (access control)
- ✅ GetStudentIncidentDrafts - Reusable (draft retrieval)
- ⚠️ Report Generation Services - Reusable with interface extraction
- 🔴 TrackingActionsController - Not reusable (monolithic)

---

### Reusability Matrix

| Component | Bundle | Lines | Reusability | Reason |
|-----------|--------|-------|-------------|--------|
| Severity Level Services | Config | ~200 | ✅ High | Pure CRUD, proper DI |
| Evidence Services | Creation | ~150 | ✅ High | Focused, proper DI |
| GetIncidentReportByStatus | Tracking | ~100 | ✅ High | Clean query pattern |
| GetPermissionByRoleByIncident | Tracking | ~80 | ✅ High | Reusable access control |
| Report Generation Services | Tracking | ~1,200 | 🟡 Medium | Need interface extraction |
| Notification Services | Tracking | ~300 | 🟡 Medium | Template-based pattern |
| CompanyIncidentUtil | Config | 1,465 | 🔴 None | God object |
| CustomIncidentReportUtil | Creation | 1,709 | 🔴 None | Bypasses DI |
| PDFUtil | Creation | 1,009 | 🔴 None | Embedded logic |
| TrackingActionsController | Tracking | 2,357 | 🔴 None | Monolithic |

---

### Cross-Bundle Dependency Map

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCIDENT MODULE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐                                          │
│  │ ConfigurationBundle │◄──────────────────────────────┐       │
│  │   (Form & Types)    │                               │       │
│  │   36 files          │                               │       │
│  └────────┬─────────────┘                               │       │
│           │ 7 files                                     │       │
│           ▼                                             │       │
│  ┌──────────────────┐      5 files      ┌─────────────────────┐│
│  │  CreationBundle   │◄────────────────►│   TrackingBundle    ││
│  │ (Report Creation) │                  │ (Workflow/Reports)  ││
│  │   21 files        │                  │   39 files          ││
│  └────────┬──────────┘                  └──────────┬──────────┘│
│           │                                        │           │
└───────────┼────────────────────────────────────────┼───────────┘
            │                                        │
            ▼ 7 files                               ▼ 18 files
┌───────────────────────────────────────────────────────────────┐
│              PlanetMedia\MedTrainerBundle                     │
│                   (Legacy Core)                               │
│                   107 total imports                           │
└───────────────────────────────────────────────────────────────┘
            │                                        │
            ▼ 1 file                                ▼ 2 files
┌───────────────────────────────────────────────────────────────┐
│            MedTrainer\EscalationMatrixBundle                  │
│                 (Escalation Rules)                            │
└───────────────────────────────────────────────────────────────┘
```

---

### Coupling Metrics

| Metric | Percentage | Status |
|--------|------------|--------|
| Coupled to External Modules | ~68% | ⚠️ High |
| Internal Module Dependencies | ~32% | ✅ Good |
| Legacy Bundle Dependency | 107 imports from `PlanetMedia\MedTrainerBundle` | 🔴 Critical |

**External Dependencies Breakdown:**
- `PlanetMedia\MedTrainerBundle`: 107 uses (legacy core)
- `Doctrine\ORM`: 80 uses (EntityManager: 34x direct)
- `MedTrainer\EscalationMatrixBundle`: 42 uses
- `Symfony Core`: 99 uses

### Code Quality Metrics

| Metric | Value | Status |
|--------|-------|--------|
| `__invoke()` Pattern Compliance | 86% (25/29 services) | ✅ Good |
| Service Interfaces | 0% (0 interfaces) | 🔴 Critical |
| Controllers with >500 lines | 2 god classes | 🔴 Critical |
| Utility Classes >200 lines | 5 of 7 | ⚠️ High |

### Reusability Assessment

| Component Type | Count | Reusable | Issues |
|----------------|-------|----------|--------|
| Constants | 5 | ✅ Yes | Well-organized |
| Utility Classes | 7 | ⚠️ Partial | Manual DI, tightly coupled |
| Services | 29 | ⚠️ Partial | No interfaces, concrete only |
| Entities | 22 | ✅ Yes | Proper ORM mapping |

### Technical Debt Indicators

**Critical Files (God Classes):**

| File | Lines | Priority |
|------|-------|----------|
| TrackingActionsController.php | 2,357 | 🔴 Critical |
| CustomIncidentReportUtil.php | 1,709 | 🔴 Critical |
| CompanyIncidentUtil.php | 1,465 | 🔴 Critical |
| PDFUtil.php | 1,009 | ⚠️ High |
| DisplayAjaxController.php | 921 | ⚠️ High |

**Anti-Patterns Found:**
- **Manual Service Instantiation** - Controllers use `new ServiceClass()` instead of DI
- **Direct YAML Loading** - Utils load config files directly bypassing container
- **N+1 Query Patterns** - 34+ direct EntityManager injections with `getRepository()` calls
- **No Service Interfaces** - All 29 services are concrete classes

### Refactoring Priority Matrix

| Priority | Task | Impact | Effort |
|----------|------|--------|--------|
| 🔴 P1 | Break down TrackingActionsController (32 methods → services) | High | High |
| 🔴 P1 | Create service interfaces for cross-bundle communication | High | Medium |
| 🔴 P2 | Migrate Utility classes to proper DI services | High | High |
| ⚠️ P2 | Refactor CustomIncidentReportUtil into focused services | Medium | High |
| ⚠️ P3 | Optimize repository queries (N+1 prevention) | Medium | Medium |
| 🟡 P3 | Decouple from `PlanetMedia\MedTrainerBundle` | High | Very High |
| 🟢 P4 | Add missing tests (currently minimal) | Medium | Medium |

### Module Independence Score

| Criterion | Score | Notes |
|-----------|-------|-------|
| Self-contained | 🔴 3/10 | Heavy external dependencies |
| Interface-driven | 🔴 1/10 | No service interfaces |
| DI Compliance | ⚠️ 6/10 | Most services OK, controllers/utils bad |
| Single Responsibility | 🔴 4/10 | God classes present |
| Test Coverage | 🔴 2/10 | Only 3 test files visible |
| **Overall Readiness** | 🔴 **32%** | Not ready for extraction |

### Recommended Next Steps

1. **Immediate**: Create interfaces for services consumed across bundles
2. **Short-term**: Decompose TrackingActionsController into single-responsibility services
3. **Medium-term**: Migrate all Util classes to proper services with constructor DI
4. **Long-term**: Create DTOs to decouple from `PlanetMedia\MedTrainerBundle` entities

### Rollback Strategy

**Simple Version-Based Rollback:**
```bash
# On failure detection:
git revert <commit-hash>   # Revert the problematic commit
git push origin master     # Push to trigger deploy
# Deploy pipeline handles the rest
```

---

## Time Estimation Summary

| Phase | Focus | Hours | Days | Weeks | Risk |
|-------|-------|-------|------|-------|------|
| **Phase 1** | Service Interface Layer | 16-24 | 2-3 | 0.5 | 🟢 Low |
| **Phase 2** | God Class Decomposition | 40-56 | 5-7 | 1-1.5 | 🟡 Medium |
| **Phase 3** | Utility Class Migration | 32-48 | 4-6 | 1-1.5 | 🟡 Medium |
| **Phase 4** | Event-Driven Architecture | 24-32 | 3-4 | 0.5-1 | 🟡 Medium |
| **Phase 5** | Repository Pattern Enhancement | 16-24 | 2-3 | 0.5 | 🟢 Low |
| **Phase 6** | Legacy Decoupling | 24-40 | 3-5 | 0.5-1 | 🔴 High |
| | | | | | |
| **Total** | | **152-224 hrs** | **19-28 days** | **4-6 weeks** | |

### Week-by-Week Projection (1 Developer)

```
Week 1: Phase 1 (complete) + Phase 2 (start)
        ├── SharedBundle setup
        ├── Service interfaces
        └── Begin controller decomposition

Week 2: Phase 2 (continue)
        ├── Controller extraction
        ├── Service creation
        └── Routing updates

Week 3: Phase 2 (complete) + Phase 3 (start)
        ├── Finish controller decomposition
        ├── Begin utility migration
        └── CustomIncidentReportUtil

Week 4: Phase 3 (continue)
        ├── CompanyIncidentUtil
        ├── PDFUtil
        └── TrackingActionsUtil

Week 5: Phase 3 (complete) + Phase 4 + Phase 5
        ├── Finish utility migration
        ├── Domain events
        └── Query objects

Week 6: Phase 6 + Buffer
        ├── DTOs for legacy entities
        ├── Anti-corruption layer
        └── Final testing & cleanup
```

### Week-by-Week Projection (2 Developers)

```
Week 1:
        Dev 1: Phase 1 (complete) + Phase 2 (start)
        Dev 2: Phase 3 (start - after Phase 1 interfaces ready)

Week 2:
        Dev 1: Phase 2 (continue)
        Dev 2: Phase 3 (continue)

Week 3:
        Dev 1: Phase 2 (complete) + Phase 4
        Dev 2: Phase 3 (complete) + Phase 5

Week 4:
        Dev 1: Phase 4 (complete) + Buffer
        Dev 2: Phase 6 + Buffer

Total: ~4 weeks with 2 developers
```

### Estimation Notes

- Estimates assume **1 developer** working full-time (8 hrs/day, 5 days/week)
- Includes time for: coding, testing, code review, and deployment
- Does **not** include: meetings, interruptions, or context switching
- Phases can overlap (e.g., Phase 3 can start while Phase 2 is in progress)
- Add **20% buffer** for unexpected issues
- Week projections assume sequential phases with minimal overlap

---

## Core Principles

### 1. Small, Atomic Commits
- Each commit = one logical change
- Every commit must be independently revertable
- No "big bang" refactoring PRs

### 2. Backward Compatible Changes
- New code must work alongside old code
- No breaking changes to public interfaces until migration complete
- Deprecate → Migrate → Remove (3-step pattern)

### 3. Test Coverage Before Refactoring
- Write tests for existing behavior BEFORE changing code
- Tests serve as safety net and documentation
- If tests pass after revert, system is healthy

---

## Phase 1: Service Interface Layer

> Estimated Time: 16-24 hours

| Task | Hours |
|------|-------|
| Create SharedBundle structure | 2-3 |
| Define 10 service interfaces | 4-6 |
| Create DTOs (5-6 classes) | 3-4 |
| Implement interfaces on existing services | 4-6 |
| Write tests | 2-4 |
| Code review & fixes | 1-2 |

### 1.1 Create SharedBundle for Contracts

**Objective**: Define interfaces that decouple consumers from implementations.

```
symfony/src/Incident/
├── SharedBundle/                          # NEW
│   ├── Contract/
│   │   ├── Configuration/
│   │   │   ├── IncidentTypeProviderInterface.php
│   │   │   ├── SectionProviderInterface.php
│   │   │   └── SeverityLevelManagerInterface.php
│   │   ├── Creation/
│   │   │   ├── IncidentReportCreatorInterface.php
│   │   │   ├── EvidenceManagerInterface.php
│   │   │   └── WitnessManagerInterface.php
│   │   └── Tracking/
│   │       ├── IncidentTrackerInterface.php
│   │       ├── EscalationManagerInterface.php
│   │       ├── ResolutionManagerInterface.php
│   │       └── ReportGeneratorInterface.php
│   └── DTO/
│       ├── IncidentReportDTO.php
│       ├── EscalationDTO.php
│       └── SeverityLevelDTO.php
```

### 1.2 Interface Definition Example

```php
<?php
// symfony/src/Incident/SharedBundle/Contract/Tracking/ReportGeneratorInterface.php

namespace Incident\SharedBundle\Contract\Tracking;

interface ReportGeneratorInterface
{
    public function generate(int $incidentId, string $format = 'pdf', array $options = []): GeneratedReportResult;

    public function generateSummary(
        int $companyIncidentId,
        \DateTimeInterface $startDate,
        \DateTimeInterface $endDate,
        array $filters = []
    ): GeneratedReportResult;
}
```

### 1.3 Wrap Existing Services with Interface

```php
<?php
// symfony/src/Incident/TrackingBundle/Service/GenerateIncidentReport.php

namespace Incident\TrackingBundle\Service;

use Incident\SharedBundle\Contract\Tracking\ReportGeneratorInterface;

// Step 1: Add interface to existing service (backward compatible)
class GenerateIncidentReport implements ReportGeneratorInterface
{
    // Existing code unchanged
    public function __invoke(int $incidentId, array $options = []): array
    {
        // ... existing implementation
    }

    // Step 2: Add interface method that delegates to __invoke
    public function generate(int $incidentId, string $format = 'pdf', array $options = []): GeneratedReportResult
    {
        $result = $this($incidentId, $options);

        return new GeneratedReportResult(
            content: $result['content'] ?? '',
            filename: $result['filename'] ?? "incident_{$incidentId}.{$format}",
            mimeType: $this->getMimeType($format),
        );
    }
}
```

**Commit Strategy:**
```bash
# Commit 1: Add SharedBundle with interfaces (no behavior change)
git commit -m "LSFB-XXXXX: Add Incident SharedBundle with service interfaces"

# Commit 2: Implement interface on existing service (no behavior change)
git commit -m "LSFB-XXXXX: Implement ReportGeneratorInterface on GenerateIncidentReport"

# Each commit is independently revertable
```

---

## Phase 2: God Class Decomposition

> Estimated Time: 40-56 hours

| Task | Hours |
|------|-------|
| Analyze TrackingActionsController (32 methods) | 2-3 |
| Extract to 6 new controllers | 16-24 |
| Create supporting services (8-10 services) | 12-16 |
| Update routing configuration | 2-3 |
| Write/update tests | 6-8 |
| Code review & fixes | 2-4 |

### 2.1 TrackingActionsController Strategy

**Current**: 2,357 lines, 32+ methods
**Target**: 6 focused controllers, max 300 lines each

```
DECOMPOSITION MAP:

TrackingActionsController (2,357 lines)
│
├── Dashboard Methods ──────────► DashboardController.php
│   ├── indexAction()                 └── index()
│   ├── filterAction()                └── filter()
│   └── searchAction()                └── search()
│
├── Detail Methods ─────────────► IncidentDetailController.php
│   ├── viewAction()                  └── view()
│   ├── editAction()                  └── edit()
│   └── updateAction()                └── update()
│
├── Escalation Methods ─────────► EscalationController.php
│   ├── escalateAction()              └── escalate()
│   ├── assignAction()                └── assign()
│   └── reassignAction()              └── reassign()
│
├── Resolution Methods ─────────► ResolutionController.php
│   ├── resolveAction()               └── submit()
│   ├── approveAction()               └── approve()
│   └── rejectAction()                └── reject()
│
└── Report Methods ─────────────► ReportController.php
    ├── generateReportAction()        └── generate()
    └── exportAction()                └── export()
```

### 2.2 Step-by-Step Extraction Pattern

**Step 1: Extract method to service (same file)**
```php
// TrackingActionsController.php

public function indexAction(Request $request): Response
{
    // BEFORE: 150 lines of logic here

    // AFTER: Delegate to extracted method
    return $this->handleIndex($request);
}

private function handleIndex(Request $request): Response
{
    // Logic extracted here, still in same class
    // This commit is safe to revert
}
```

**Step 2: Extract to dedicated service**
```php
// NEW: IncidentListService.php
class IncidentListService
{
    public function __invoke(IncidentListCriteria $criteria): IncidentListResult
    {
        // Logic moved here with proper DI
    }
}

// TrackingActionsController.php
public function indexAction(Request $request): Response
{
    $result = ($this->incidentListService)($criteria);
    return $this->render('...', ['incidents' => $result]);
}
```

**Step 3: Create new controller**
```php
// NEW: DashboardController.php
class DashboardController extends AbstractController
{
    public function __construct(
        private IncidentListService $listService,
    ) {}

    public function index(Request $request): Response
    {
        // Clean implementation
    }
}
```

**Step 4: Update routing**
```yaml
# routing.yml - Add new route alongside old
incident_dashboard_index:
  path: /admin/ir/index
  controller: Incident\TrackingBundle\Controller\DashboardController::index

# Remove old route in separate commit after validation
```

**Commit Strategy:**
```bash
# Commit 1: Extract to private method
git commit -m "LSFB-XXXXX: Extract index logic to handleIndex method"

# Commit 2: Create service
git commit -m "LSFB-XXXXX: Create IncidentListService"

# Commit 3: Controller uses service
git commit -m "LSFB-XXXXX: TrackingActionsController delegates to IncidentListService"

# Commit 4: New controller
git commit -m "LSFB-XXXXX: Add DashboardController"

# Commit 5: Switch routing
git commit -m "LSFB-XXXXX: Route /admin/ir/index to DashboardController"

# Commit 6: Remove old method (after validation period)
git commit -m "LSFB-XXXXX: Remove legacy indexAction from TrackingActionsController"
```

---

## Phase 3: Utility Class Migration

> Estimated Time: 32-48 hours

| Task | Hours |
|------|-------|
| CustomIncidentReportUtil (1,709 lines) | 8-12 |
| CompanyIncidentUtil (1,465 lines) | 6-10 |
| PDFUtil (1,009 lines) | 5-7 |
| TrackingActionsUtil (687 lines) | 4-6 |
| IRInformationUtil + MatrixUtil + SectionUtil | 4-6 |
| Write/update tests | 4-6 |
| Code review & fixes | 2-4 |

### 3.1 Migration Priority

| Utility Class | Lines | Risk | Target Services |
|---------------|-------|------|-----------------|
| CustomIncidentReportUtil | 1,709 | High | FormRetrievalService, AnswerProcessingService |
| CompanyIncidentUtil | 1,465 | High | IncidentTypeService, FormConfigService |
| PDFUtil | 1,009 | Medium | PdfGeneratorService |
| TrackingActionsUtil | 687 | Medium | ClosureService, LogService |
| IRInformationUtil | 291 | Low | IncidentQueryService |
| MatrixUtil | 217 | Low | EscalationMatrixService |

### 3.2 Utility Migration Pattern

**Problem**: Utilities use manual instantiation (`new ArrayUtil()`)

**Solution**: Gradual migration to DI

```php
<?php
// STEP 1: Add optional DI alongside manual instantiation

class CustomIncidentReportUtil
{
    private ArrayUtil $arrayUtil;
    private ?FormRetrievalService $formService = null;

    public function __construct(?FormRetrievalService $formService = null)
    {
        // Legacy: manual instantiation as fallback
        $this->arrayUtil = new ArrayUtil();

        // New: use injected service if available
        $this->formService = $formService;
    }

    public function getFormConfig(int $formId): array
    {
        // Prefer new service, fall back to legacy
        if ($this->formService !== null) {
            return ($this->formService)($formId)->toArray();
        }

        return $this->legacyGetFormConfig($formId);
    }
}
```

```yaml
# STEP 2: Register utility as service with DI
services:
  Incident\CreationBundle\Util\CustomIncidentReportUtil:
    arguments:
      - '@Incident\CreationBundle\Service\Form\FormRetrievalService'
```

```php
<?php
// STEP 3: After all consumers use DI, remove legacy fallback

class CustomIncidentReportUtil
{
    public function __construct(
        private FormRetrievalService $formService,
    ) {}

    public function getFormConfig(int $formId): array
    {
        return ($this->formService)($formId)->toArray();
    }
}
```

**Commit Strategy:**
```bash
# Commit 1: Create new service
git commit -m "LSFB-XXXXX: Add FormRetrievalService"

# Commit 2: Add optional DI to utility
git commit -m "LSFB-XXXXX: CustomIncidentReportUtil accepts optional FormRetrievalService"

# Commit 3: Register as service
git commit -m "LSFB-XXXXX: Register CustomIncidentReportUtil with DI"

# Commit 4: Update consumers to use DI
git commit -m "LSFB-XXXXX: Inject CustomIncidentReportUtil via DI in controllers"

# Commit 5: Remove legacy fallback
git commit -m "LSFB-XXXXX: Remove manual instantiation from CustomIncidentReportUtil"
```

---

## Phase 4: Event-Driven Architecture

> Estimated Time: 24-32 hours

| Task | Hours |
|------|-------|
| Define domain events (5-6 events) | 3-4 |
| Create event subscribers | 6-8 |
| Integrate events into existing services | 8-10 |
| Configure async processing (optional) | 2-4 |
| Write/update tests | 4-6 |
| Code review & fixes | 2-3 |

### 4.1 Domain Events

```php
<?php
// symfony/src/Incident/SharedBundle/Event/IncidentCreatedEvent.php

namespace Incident\SharedBundle\Event;

use Symfony\Contracts\EventDispatcher\Event;

class IncidentCreatedEvent extends Event
{
    public const NAME = 'incident.created';

    public function __construct(
        public readonly int $incidentId,
        public readonly int $companyId,
        public readonly int $createdById,
        public readonly string $incidentType,
    ) {}
}
```

### 4.2 Gradual Event Introduction

```php
<?php
// STEP 1: Dispatch event alongside existing logic (no behavior change)

class CreateIncidentReportService
{
    public function __construct(
        private EventDispatcherInterface $dispatcher,
    ) {}

    public function __invoke(CreateIncidentRequest $request): IncidentReport
    {
        // Existing logic
        $incident = $this->createIncident($request);
        $this->sendNotifications($incident);  // Existing direct call

        // NEW: Also dispatch event (observers can subscribe)
        $this->dispatcher->dispatch(
            new IncidentCreatedEvent(
                incidentId: $incident->getId(),
                companyId: $incident->getCompanyId(),
                createdById: $request->createdBy,
                incidentType: $incident->getType(),
            ),
            IncidentCreatedEvent::NAME
        );

        return $incident;
    }
}
```

```php
<?php
// STEP 2: Create subscriber for new notification handling

class IncidentNotificationSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            IncidentCreatedEvent::NAME => 'onIncidentCreated',
        ];
    }

    public function onIncidentCreated(IncidentCreatedEvent $event): void
    {
        // New notification logic here
    }
}
```

```php
<?php
// STEP 3: Remove direct call, rely on event subscriber

class CreateIncidentReportService
{
    public function __invoke(CreateIncidentRequest $request): IncidentReport
    {
        $incident = $this->createIncident($request);

        // Removed: $this->sendNotifications($incident);

        // Event subscriber handles notifications now
        $this->dispatcher->dispatch(
            new IncidentCreatedEvent(...),
            IncidentCreatedEvent::NAME
        );

        return $incident;
    }
}
```

---

## Phase 5: Repository Pattern Enhancement

> Estimated Time: 16-24 hours

| Task | Hours |
|------|-------|
| Identify N+1 query patterns | 2-3 |
| Create query objects (4-6 classes) | 6-8 |
| Optimize existing repository queries | 4-6 |
| Write/update tests | 2-4 |
| Code review & fixes | 2-3 |

### 5.1 Query Objects

Replace scattered DQL with reusable query objects:

```php
<?php
// symfony/src/Incident/TrackingBundle/Repository/Query/IncidentListQuery.php

namespace Incident\TrackingBundle\Repository\Query;

class IncidentListQuery
{
    public function __construct(
        private EntityManagerInterface $em,
    ) {}

    public function execute(IncidentListCriteria $criteria): IncidentListResult
    {
        $qb = $this->em->createQueryBuilder()
            ->select('i', 'e', 'r')  // Eager load to prevent N+1
            ->from(CompanyIncidentScalable::class, 'i')
            ->leftJoin('i.escalations', 'e')
            ->leftJoin('i.resolution', 'r')
            ->where('i.company = :companyId')
            ->setParameter('companyId', $criteria->companyId);

        $this->applyFilters($qb, $criteria);
        $this->applySorting($qb, $criteria);

        $paginator = new Paginator($qb);

        return new IncidentListResult(
            items: iterator_to_array($paginator),
            totalCount: $paginator->count(),
            page: $criteria->page,
            pageSize: $criteria->pageSize,
        );
    }

    private function applyFilters(QueryBuilder $qb, IncidentListCriteria $criteria): void
    {
        if ($criteria->status !== null) {
            $qb->andWhere('i.status IN (:statuses)')
               ->setParameter('statuses', (array) $criteria->status);
        }

        if ($criteria->dateFrom !== null) {
            $qb->andWhere('i.createdAt >= :dateFrom')
               ->setParameter('dateFrom', $criteria->dateFrom);
        }
    }
}
```

---

## Phase 6: Legacy Decoupling

> Estimated Time: 24-40 hours

| Task | Hours |
|------|-------|
| Create DTOs for PlanetMedia entities | 6-8 |
| Build anti-corruption layer (IncidentDataBridge) | 8-12 |
| Migrate services to use DTOs | 6-10 |
| Update consumers to use new abstractions | 4-6 |
| Write/update tests | 4-6 |
| Code review & fixes | 2-4 |

### 6.1 DTO Layer

Create DTOs to decouple from `PlanetMedia\MedTrainerBundle` entities:

```php
<?php
// symfony/src/Incident/SharedBundle/DTO/IncidentScalableDTO.php

namespace Incident\SharedBundle\DTO;

class IncidentScalableDTO
{
    public function __construct(
        public readonly int $id,
        public readonly int $companyId,
        public readonly int $incidentTypeId,
        public readonly string $title,
        public readonly int $status,
        public readonly ?int $assignedToId,
        public readonly \DateTimeInterface $createdAt,
    ) {}

    public static function fromEntity(CompanyIncidentScalable $entity): self
    {
        return new self(
            id: $entity->getId(),
            companyId: $entity->getCompany()->getId(),
            incidentTypeId: $entity->getCompanyIncident()->getId(),
            title: $entity->getTitle() ?? '',
            status: $entity->getStatus(),
            assignedToId: $entity->getAssignedTo()?->getId(),
            createdAt: $entity->getCreatedAt(),
        );
    }
}
```

### 6.2 Anti-Corruption Layer

```php
<?php
// symfony/src/Incident/SharedBundle/Service/LegacyBridge/IncidentDataBridge.php

namespace Incident\SharedBundle\Service\LegacyBridge;

/**
 * Anti-corruption layer between Incident module and legacy PlanetMedia bundle
 */
class IncidentDataBridge
{
    public function __construct(
        private EntityManagerInterface $em,
        private IncidentScalableDataRepository $legacyRepo,
    ) {}

    public function findById(int $id): ?IncidentScalableDTO
    {
        $entity = $this->legacyRepo->find($id);
        return $entity ? IncidentScalableDTO::fromEntity($entity) : null;
    }

    public function findByCompany(int $companyId, array $criteria = []): array
    {
        $entities = $this->legacyRepo->findByCompany($companyId, $criteria);
        return array_map(
            fn($entity) => IncidentScalableDTO::fromEntity($entity),
            $entities
        );
    }
}
```

---

## Rollback Procedures

### Standard Rollback (Version-Based)

```bash
# 1. Identify problematic commit
git log --oneline -10

# 2. Revert the commit
git revert <commit-hash> --no-edit

# 3. Push to trigger deploy
git push origin master

# 4. Verify rollback
# Monitor logs/metrics after deploy
```

### Multiple Commit Rollback

```bash
# Revert a range of commits (newest to oldest)
git revert --no-commit HEAD~3..HEAD
git commit -m "Revert: LSFB-XXXXX incident refactoring due to [issue]"
git push origin master
```

### Database Migration Rollback

```bash
# Check current migration version
kool run console doctrine:migrations:status

# Rollback to specific version
kool run console doctrine:migrations:migrate <previous-version>

# Each migration MUST have down() method
```

**Migration Down Example:**
```php
public function down(Schema $schema): void
{
    $this->addSql('ALTER TABLE ir_company_incident DROP COLUMN IF EXISTS new_field');
    $this->addSql('DROP INDEX IF EXISTS idx_new_field ON ir_company_incident');
}
```

---

## Testing Strategy

### Pre-Refactoring: Characterization Tests

Before refactoring any component, write tests that capture current behavior:

```php
<?php
// tests/Unit/Incident/TrackingBundle/Service/GenerateIncidentReportTest.php

class GenerateIncidentReportTest extends UnitTestCase
{
    /**
     * Characterization test: captures current behavior before refactoring
     */
    public function testGenerateReportReturnsExpectedStructure(): void
    {
        $service = $this->createService();

        $result = ($service)(123, ['format' => 'pdf']);

        $this->assertArrayHasKey('content', $result);
        $this->assertArrayHasKey('filename', $result);
        $this->assertStringEndsWith('.pdf', $result['filename']);
    }
}
```

### Post-Refactoring: Same Tests Pass

```php
<?php
// After refactoring, same test must pass
// This proves behavior is preserved

class GenerateIncidentReportTest extends UnitTestCase
{
    public function testGenerateReportReturnsExpectedStructure(): void
    {
        // New implementation, same test
        $service = $this->createRefactoredService();

        $result = $service->generate(123, 'pdf');

        $this->assertInstanceOf(GeneratedReportResult::class, $result);
        $this->assertStringEndsWith('.pdf', $result->filename);
    }
}
```

---

## Success Criteria

| Phase | Focus | Key Deliverables | Metric | Target |
|-------|-------|------------------|--------|--------|
| **Phase 1** | Interfaces | SharedBundle, service contracts, DTOs | Interface coverage | 80% of public services |
| **Phase 2** | Controllers | Decompose TrackingActionsController (32 → 6) | Controller size | Max 300 lines/controller |
| **Phase 3** | Utilities | Migrate 7 utility classes to DI services | Manual instantiation | 0 `new Util()` calls |
| **Phase 4** | Events | Domain events, async processing | Event coverage | All state changes emit events |
| **Phase 5** | Repositories | Query objects, N+1 prevention | N+1 queries | 0 detected |
| **Phase 6** | Decoupling | DTOs for PlanetMedia entities | Legacy imports | < 20 from PlanetMedia |

---

## File Structure After Refactoring

```
symfony/src/Incident/
├── SharedBundle/                     # NEW - Cross-bundle shared code
│   ├── Contract/                     # Service interfaces
│   │   ├── Configuration/
│   │   ├── Creation/
│   │   └── Tracking/
│   ├── DTO/                          # Data Transfer Objects
│   ├── Event/                        # Domain events
│   └── Service/
│       └── LegacyBridge/             # Anti-corruption layer
│
├── ConfigurationBundle/              # EXISTING - Enhanced
│   ├── Controller/                   # Focused controllers
│   ├── Service/                      # Single-responsibility services
│   └── Repository/
│
├── CreationBundle/                   # EXISTING - Enhanced
│   ├── Controller/
│   ├── Service/
│   │   ├── Form/                     # From CustomIncidentReportUtil
│   │   ├── Answer/                   # From CustomIncidentReportUtil
│   │   └── Evidence/
│   └── Repository/
│
└── TrackingBundle/                   # EXISTING - Major refactoring
    ├── Controller/
    │   ├── DashboardController.php   # From TrackingActionsController
    │   ├── IncidentDetailController.php
    │   ├── EscalationController.php
    │   ├── ResolutionController.php
    │   └── ReportController.php
    ├── Service/
    │   ├── Dashboard/
    │   ├── Escalation/
    │   ├── Resolution/
    │   └── Report/
    ├── Repository/
    │   └── Query/                    # Query objects
    ├── EventSubscriber/
    └── Security/
```

---

## Quick Reference: Commit Message Format

```
LSFB-XXXXX: [TYPE] Brief description

Types:
- [ADD]      New file/feature
- [REFACTOR] Code restructuring (no behavior change)
- [MOVE]     Move code to new location
- [DEPRECATE] Mark as deprecated
- [REMOVE]   Delete deprecated code
- [FIX]      Bug fix
```

**Examples:**
```
LSFB-XXXXX: [ADD] Create IncidentListService
LSFB-XXXXX: [REFACTOR] Extract index logic from TrackingActionsController
LSFB-XXXXX: [MOVE] indexAction to DashboardController
LSFB-XXXXX: [DEPRECATE] TrackingActionsController::indexAction
LSFB-XXXXX: [REMOVE] TrackingActionsController::indexAction
```

---

## Appendix A: Incident List API Refactoring

### Current State Analysis

**Route**: `/admin/ir/index` (`incident_tracking_admin_index`)
**Controller**: `TrackingActionsController::indexAction()` (line 127)
**Data Endpoint**: `/admin/ir/getIncidentCreatedByCompany` (AJAX POST)
**Service**: `GetIncidentReportByStatus`

#### Current Architecture Flow

```
┌─────────────────────┐     ┌──────────────────────────────┐
│  incidentReports    │     │  TrackingActionsController   │
│    .html.twig       │────▶│      indexAction()           │
│                     │     │      (line 127-172)          │
└─────────────────────┘     └──────────────────────────────┘
         │                              │
         │ renders                      │ returns view with
         ▼                              │ locations, departments
┌─────────────────────┐                 │ companySettings
│   DataTables JS     │                 ▼
│  incident-table-    │     ┌──────────────────────────────┐
│  by-status.js       │────▶│ getIncidentCreatedByCompany  │
│                     │     │    Action() (line 560-733)   │
└─────────────────────┘     └──────────────────────────────┘
                                        │
                                        ▼
                            ┌──────────────────────────────┐
                            │  GetIncidentReportByStatus   │
                            │    Service (243 lines)       │
                            └──────────────────────────────┘
```

#### Current Table Columns

| # | Column | Field | Sortable | Source |
|---|--------|-------|----------|--------|
| 1 | Incident # | `incidentNumber` | ✅ | `isd.incidentNumber` |
| 2 | Incident Type | `title` | ✅ | `cir.title` or `ir.name` |
| 3 | Severity Level | `severityLevelId` | ✅ | Subquery on `IrResolutionInfo` |
| 4 | Location | `nameLocation` | ✅ | `l.name` |
| 5 | Department | `departmentName` | ✅ | `cd.name` or `isd.department` |
| 6 | Report Creation Date | `dateReport` | ✅ | `isd.dateReport` |
| 7 | Incident Date | `dateIncident` | ✅ | `isd.dateIncident` |
| 8 | Resolution Date | `resolutionDate` | ✅ | `isd.resolutionDate` |
| 9 | Status | `statusData` | ✅ | `isd.status` |
| 10 | Elapsed Time | `dateWords` | ✅ | Calculated `TIMEDIFF()` |
| 11 | Actions | - | ❌ | Dynamic buttons |

#### Current Filters

| Filter | Type | Parameter | Implementation |
|--------|------|-----------|----------------|
| Status | Dropdown | `optionStatus` | `isd.status IN (:statusData)` |
| Date From | DatePicker | `fromDate` | `isd.dateReport >= :fromDate` |
| Date To | DatePicker | `toDate` | `isd.dateReport <= :toDate` |
| Search | Text | `searchField` | `LIKE` on number, title, description |
| Location | Navbar | Session `_location` | `l.id = :idLocation` |
| Department | Navbar | Session `_department` | `isd.department LIKE` or `isd.idDepartment =` |

#### Issues with Current Implementation

| Issue | Location | Impact |
|-------|----------|--------|
| 🔴 N+1 Queries | `getIncidentCreatedByCompanyAction` lines 625-701 | Loop queries for matrix users, conversations per row |
| 🔴 God Controller | 173 lines in action method | Unmaintainable, untestable |
| ⚠️ Manual Instantiation | `new CompanyUtil()`, `new ToolsUtil()` | Bypasses DI, breaks testing |
| ⚠️ Session Coupling | Direct `$this->get('session')` | Hard to test, implicit state |
| 🟡 Mixed Concerns | Data fetching + formatting + permissions | SRP violation |

---

### Target API Design

#### New Endpoint Structure

```
GET /api/v1/incidents
POST /api/v1/incidents/search  (for complex filters)
```

#### Request/Response Contract

**GET /api/v1/incidents**

```http
GET /api/v1/incidents?status=1,2&page=1&limit=10&sort=dateReport&order=desc
Authorization: Bearer {token}
X-Company-Id: {companyId}
```

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Page number (1-indexed) |
| `limit` | int | 10 | Items per page (max 100) |
| `sort` | string | `dateReport` | Sort column |
| `order` | string | `desc` | Sort direction (asc/desc) |
| `status` | string | - | Comma-separated status IDs |
| `dateFrom` | string | - | ISO 8601 date (YYYY-MM-DD) |
| `dateTo` | string | - | ISO 8601 date (YYYY-MM-DD) |
| `search` | string | - | Search term (max 100 chars) |
| `locationId` | int | - | Filter by location |
| `departmentId` | int | - | Filter by department |
| `severityLevel` | int | - | Filter by severity level |

**Response:**

```json
{
  "data": [
    {
      "id": 12345,
      "incidentNumber": "IR-2024-001",
      "title": "Patient Fall in Room 302",
      "type": {
        "id": 5,
        "name": "Patient Safety"
      },
      "severityLevel": {
        "level": 3,
        "color": "#FF9800",
        "description": "Moderate"
      },
      "location": {
        "id": 10,
        "name": "Main Hospital"
      },
      "department": {
        "id": 25,
        "name": "Emergency Department"
      },
      "dates": {
        "incident": "2024-12-01",
        "reported": "2024-12-01T14:30:00Z",
        "resolved": null
      },
      "status": {
        "code": 2,
        "label": "Escalated"
      },
      "elapsedTime": {
        "hours": 192,
        "formatted": "8 days"
      },
      "permissions": {
        "canView": true,
        "canEdit": false,
        "canDelete": true,
        "canDownload": true
      },
      "meta": {
        "isAnonymous": false,
        "isUploaded": false,
        "conversationCount": 3,
        "matrixType": "RACI"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 156,
    "totalPages": 16
  },
  "filters": {
    "applied": {
      "status": [1, 2],
      "dateFrom": "2024-01-01"
    },
    "available": {
      "statuses": [
        {"code": 1, "label": "New", "count": 45},
        {"code": 2, "label": "Escalated", "count": 32},
        {"code": 3, "label": "Resolved", "count": 67},
        {"code": 4, "label": "Closed", "count": 12}
      ],
      "locations": [
        {"id": 10, "name": "Main Hospital", "count": 89},
        {"id": 11, "name": "Clinic A", "count": 67}
      ],
      "severityLevels": [
        {"level": 1, "label": "Low", "count": 50},
        {"level": 2, "label": "Medium", "count": 60},
        {"level": 3, "label": "High", "count": 30},
        {"level": 4, "label": "Critical", "count": 16}
      ]
    }
  }
}
```

---

### Implementation Plan

#### Step 1: Create Filter Criteria DTO

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/IncidentListCriteria.php

namespace Incident\TrackingBundle\DTO;

use Symfony\Component\Validator\Constraints as Assert;

final class IncidentListCriteria
{
    public function __construct(
        #[Assert\Positive]
        public readonly int $companyId,

        #[Assert\Positive]
        #[Assert\LessThanOrEqual(100)]
        public readonly int $limit = 10,

        #[Assert\PositiveOrZero]
        public readonly int $offset = 0,

        #[Assert\Choice(['incidentNumber', 'title', 'dateReport', 'dateIncident', 'status', 'severityLevel'])]
        public readonly string $sortBy = 'dateReport',

        #[Assert\Choice(['asc', 'desc'])]
        public readonly string $sortOrder = 'desc',

        /** @var int[]|null */
        public readonly ?array $statuses = null,

        public readonly ?\DateTimeInterface $dateFrom = null,
        public readonly ?\DateTimeInterface $dateTo = null,

        #[Assert\Length(max: 100)]
        public readonly ?string $search = null,

        public readonly ?int $locationId = null,
        public readonly ?int $departmentId = null,
        public readonly ?int $severityLevelId = null,

        /** @var int[] User's accessible location IDs (for admin filtering) */
        public readonly array $accessibleLocationIds = [],

        public readonly ?int $userId = null,
        public readonly string $dashboardType = 'S',
    ) {}

    public static function fromRequest(array $params, int $companyId, array $userContext): self
    {
        return new self(
            companyId: $companyId,
            limit: min((int) ($params['limit'] ?? 10), 100),
            offset: (int) ($params['offset'] ?? 0),
            sortBy: $params['sort'] ?? 'dateReport',
            sortOrder: $params['order'] ?? 'desc',
            statuses: isset($params['status']) ? array_map('intval', explode(',', $params['status'])) : null,
            dateFrom: isset($params['dateFrom']) ? new \DateTime($params['dateFrom']) : null,
            dateTo: isset($params['dateTo']) ? new \DateTime($params['dateTo']) : null,
            search: $params['search'] ?? null,
            locationId: isset($params['locationId']) ? (int) $params['locationId'] : null,
            departmentId: isset($params['departmentId']) ? (int) $params['departmentId'] : null,
            severityLevelId: isset($params['severityLevel']) ? (int) $params['severityLevel'] : null,
            accessibleLocationIds: $userContext['locationIds'] ?? [],
            userId: $userContext['userId'] ?? null,
            dashboardType: $userContext['dashboardType'] ?? 'S',
        );
    }
}
```

#### Step 2: Create Response DTO

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/IncidentListItem.php

namespace Incident\TrackingBundle\DTO;

final class IncidentListItem
{
    public function __construct(
        public readonly int $id,
        public readonly string $incidentNumber,
        public readonly string $title,
        public readonly IncidentTypeInfo $type,
        public readonly ?SeverityLevelInfo $severityLevel,
        public readonly LocationInfo $location,
        public readonly ?DepartmentInfo $department,
        public readonly IncidentDates $dates,
        public readonly IncidentStatusInfo $status,
        public readonly ElapsedTimeInfo $elapsedTime,
        public readonly IncidentPermissions $permissions,
        public readonly IncidentMeta $meta,
    ) {}

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'incidentNumber' => $this->incidentNumber,
            'title' => $this->title,
            'type' => $this->type->toArray(),
            'severityLevel' => $this->severityLevel?->toArray(),
            'location' => $this->location->toArray(),
            'department' => $this->department?->toArray(),
            'dates' => $this->dates->toArray(),
            'status' => $this->status->toArray(),
            'elapsedTime' => $this->elapsedTime->toArray(),
            'permissions' => $this->permissions->toArray(),
            'meta' => $this->meta->toArray(),
        ];
    }
}
```

#### Step 3: Create API Service (Refactored)

```php
<?php
// symfony/src/Incident/TrackingBundle/Service/Api/GetIncidentList.php

namespace Incident\TrackingBundle\Service\Api;

use Doctrine\ORM\EntityManagerInterface;
use Incident\TrackingBundle\DTO\IncidentListCriteria;
use Incident\TrackingBundle\DTO\IncidentListResult;
use Incident\TrackingBundle\Repository\Query\IncidentListQuery;

final class GetIncidentList
{
    public function __construct(
        private readonly IncidentListQuery $query,
        private readonly IncidentPermissionResolver $permissionResolver,
        private readonly IncidentMetaLoader $metaLoader,
    ) {}

    public function __invoke(IncidentListCriteria $criteria): IncidentListResult
    {
        // Single optimized query with JOINs (prevents N+1)
        $queryResult = $this->query->execute($criteria);

        // Batch load permissions and meta (2 queries max, not N)
        $incidentIds = array_column($queryResult->items, 'id');
        $permissions = $this->permissionResolver->resolveForIncidents($incidentIds, $criteria->userId);
        $meta = $this->metaLoader->loadForIncidents($incidentIds);

        // Transform to DTOs
        $items = array_map(
            fn(array $row) => $this->toListItem($row, $permissions[$row['id']] ?? [], $meta[$row['id']] ?? []),
            $queryResult->items
        );

        return new IncidentListResult(
            items: $items,
            total: $queryResult->total,
            page: ($criteria->offset / $criteria->limit) + 1,
            limit: $criteria->limit,
        );
    }

    private function toListItem(array $row, array $permissions, array $meta): IncidentListItem
    {
        return new IncidentListItem(
            id: $row['id'],
            incidentNumber: $row['incidentNumber'],
            title: $row['title'],
            type: new IncidentTypeInfo($row['incidentTypeId'], $row['incidentTypeName']),
            severityLevel: $row['severityLevelId']
                ? new SeverityLevelInfo($row['severityLevel'], $row['severityLevelColor'], $row['severityLevelDescription'])
                : null,
            location: new LocationInfo($row['locationId'], $row['locationName']),
            department: $row['departmentId']
                ? new DepartmentInfo($row['departmentId'], $row['departmentName'])
                : null,
            dates: new IncidentDates($row['dateIncident'], $row['dateReport'], $row['resolutionDate']),
            status: new IncidentStatusInfo($row['status'], $this->getStatusLabel($row['status'])),
            elapsedTime: new ElapsedTimeInfo($row['elapsedHours'], $this->formatElapsedTime($row['elapsedHours'])),
            permissions: new IncidentPermissions(...$permissions),
            meta: new IncidentMeta(...$meta),
        );
    }
}
```

#### Step 4: Create Optimized Query Object

```php
<?php
// symfony/src/Incident/TrackingBundle/Repository/Query/IncidentListQuery.php

namespace Incident\TrackingBundle\Repository\Query;

use Doctrine\ORM\EntityManagerInterface;
use Incident\TrackingBundle\DTO\IncidentListCriteria;

final class IncidentListQuery
{
    private const COLUMN_MAP = [
        'incidentNumber' => 'isd.incidentNumber',
        'title' => 'title',
        'dateReport' => 'isd.dateReport',
        'dateIncident' => 'isd.dateIncident',
        'status' => 'isd.status',
        'severityLevel' => 'severityLevelId',
    ];

    public function __construct(
        private readonly EntityManagerInterface $em,
    ) {}

    public function execute(IncidentListCriteria $criteria): QueryResult
    {
        $qb = $this->em->createQueryBuilder();

        // Main query with all JOINs (single query, no N+1)
        $qb->select(
            'cir.id',
            'isd.incidentNumber',
            'CASE WHEN cir.title IS NULL OR cir.title = \'\' THEN ir.name ELSE cir.title END AS title',
            'ir.id AS incidentTypeId',
            'ir.name AS incidentTypeName',
            'l.id AS locationId',
            'l.name AS locationName',
            'cd.id AS departmentId',
            'COALESCE(cd.name, isd.department) AS departmentName',
            'isd.dateIncident',
            'isd.dateReport',
            'isd.resolutionDate',
            'isd.status',
            'TIMESTAMPDIFF(HOUR, isd.dateReport, COALESCE(isd.resolutionDate, CURRENT_TIMESTAMP())) AS elapsedHours',
            'ci.isAnonymous',
            'cir.status AS companyStatus',
            'ismc.escalationType AS matrixType',
            // Subquery for severity level (indexed, fast)
            '(SELECT iri.severityLevelId FROM IncidentTrackingBundle:IrResolutionInfo iri
              WHERE iri.idIrDetail = isd.id ORDER BY iri.id DESC LIMIT 1) AS severityLevelId',
        )
        ->from('PlanetMediaMedTrainerBundle:CompanyIncidentScalable', 'cir')
        ->join('PlanetMediaMedTrainerBundle:IncidentScalableData', 'isd', 'WITH', 'cir.idIncidentScalableDetail = isd.id')
        ->join('PlanetMediaMedTrainerBundle:Location', 'l', 'WITH', 'l.id = isd.locationId')
        ->join('PlanetMediaMedTrainerBundle:IncidentReportType', 'ir', 'WITH', 'ir.id = isd.idIncidentReportType')
        ->leftJoin('MedTrainerEscalationMatrixBundle:IrScaleMatrixCompany', 'ismc', 'WITH', 'ismc.id = isd.idIrScaleMatrixCompany')
        ->leftJoin('PlanetMediaMedTrainerBundle:CompanyDepartment', 'cd', 'WITH', 'cd.id = isd.idDepartment')
        ->leftJoin('IncidentConfigurationBundle:CompanyIncident', 'ci', 'WITH', 'isd.idCompanyIncidentForm = ci.id')
        ->where('cir.idCompany = :companyId')
        ->andWhere('l.enable = 1')
        ->andWhere('ci.isAnonymous IS NOT NULL OR ci.id IS NULL')
        ->setParameter('companyId', $criteria->companyId);

        $this->applyFilters($qb, $criteria);
        $this->applyLocationAccess($qb, $criteria);

        // Count query (before pagination)
        $countQb = clone $qb;
        $countQb->select('COUNT(DISTINCT cir.id)');
        $total = (int) $countQb->getQuery()->getSingleScalarResult();

        // Apply sorting and pagination
        $sortColumn = self::COLUMN_MAP[$criteria->sortBy] ?? 'isd.dateReport';
        $qb->orderBy($sortColumn, $criteria->sortOrder)
           ->setFirstResult($criteria->offset)
           ->setMaxResults($criteria->limit);

        return new QueryResult(
            items: $qb->getQuery()->getArrayResult(),
            total: $total,
        );
    }

    private function applyFilters(\Doctrine\ORM\QueryBuilder $qb, IncidentListCriteria $criteria): void
    {
        // Status filter
        if ($criteria->statuses !== null && count($criteria->statuses) > 0) {
            $qb->andWhere('isd.status IN (:statuses)')
               ->setParameter('statuses', $criteria->statuses);
        } else {
            // Default: exclude deleted and draft
            $qb->andWhere('cir.status NOT IN (:excludedStatuses)')
               ->setParameter('excludedStatuses', ['D', '0', 'S', '-1']);
        }

        // Date range
        if ($criteria->dateFrom !== null) {
            $qb->andWhere('isd.dateReport >= :dateFrom')
               ->setParameter('dateFrom', $criteria->dateFrom);
        }
        if ($criteria->dateTo !== null) {
            $qb->andWhere('isd.dateReport <= :dateTo')
               ->setParameter('dateTo', $criteria->dateTo);
        }

        // Location filter
        if ($criteria->locationId !== null) {
            $qb->andWhere('l.id = :locationId')
               ->setParameter('locationId', $criteria->locationId);
        }

        // Department filter
        if ($criteria->departmentId !== null) {
            $qb->andWhere('cd.id = :departmentId')
               ->setParameter('departmentId', $criteria->departmentId);
        }

        // Search filter
        if ($criteria->search !== null && trim($criteria->search) !== '') {
            $searchTerm = '%' . mb_strtolower(trim($criteria->search)) . '%';
            $qb->andWhere('(
                LOWER(isd.incidentNumber) LIKE :search
                OR LOWER(cir.title) LIKE :search
                OR LOWER(isd.incidentDescription) LIKE :search
                OR LOWER(ir.name) LIKE :search
            )')
            ->setParameter('search', $searchTerm);
        }
    }

    private function applyLocationAccess(\Doctrine\ORM\QueryBuilder $qb, IncidentListCriteria $criteria): void
    {
        if ($criteria->dashboardType === 'A' && count($criteria->accessibleLocationIds) > 0) {
            $qb->andWhere('(
                l.id IN (:accessibleLocations)
                OR isd.id IN (
                    SELECT ier.idIrDetail
                    FROM IncidentTrackingBundle:IrEscalationsReport ier
                    WHERE ier.idDscModule = 1 AND ier.idEmployee = :userId
                )
            )')
            ->setParameter('accessibleLocations', $criteria->accessibleLocationIds)
            ->setParameter('userId', $criteria->userId);
        }
    }
}
```

#### Step 5: Create API Controller

```php
<?php
// symfony/src/Incident/TrackingBundle/Controller/Api/IncidentListController.php

namespace Incident\TrackingBundle\Controller\Api;

use Incident\TrackingBundle\DTO\IncidentListCriteria;
use Incident\TrackingBundle\Service\Api\GetIncidentList;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api/v1/incidents', name: 'api_incidents_')]
final class IncidentListController extends AbstractController
{
    public function __construct(
        private readonly GetIncidentList $getIncidentList,
        private readonly UserContextResolver $userContextResolver,
    ) {}

    #[Route('', name: 'list', methods: ['GET'])]
    public function list(Request $request): JsonResponse
    {
        $userContext = $this->userContextResolver->resolve($request);

        $criteria = IncidentListCriteria::fromRequest(
            params: $request->query->all(),
            companyId: $userContext->companyId,
            userContext: [
                'userId' => $userContext->userId,
                'dashboardType' => $userContext->dashboardType,
                'locationIds' => $userContext->accessibleLocationIds,
            ],
        );

        $result = ($this->getIncidentList)($criteria);

        return $this->json([
            'data' => array_map(fn($item) => $item->toArray(), $result->items),
            'pagination' => [
                'page' => $result->page,
                'limit' => $result->limit,
                'total' => $result->total,
                'totalPages' => (int) ceil($result->total / $result->limit),
            ],
        ]);
    }
}
```

---

### Migration Strategy (Backward Compatible)

#### Phase 1: Add New API Endpoint (No Breaking Changes)

```yaml
# routing.yml - Add new route alongside existing
api_incidents_list:
    path: /api/v1/incidents
    controller: Incident\TrackingBundle\Controller\Api\IncidentListController::list
    methods: [GET]

# Existing route unchanged
incident_tracking_admin_getIncidentCreatedByCompany:
    path: /admin/ir/getIncidentCreatedByCompany
    defaults: { _controller: IncidentTrackingBundle:TrackingActions:getIncidentCreatedByCompany }
```

#### Phase 2: Update Frontend to Use New API

```javascript
// incident-table-by-status.js - Add feature flag
const USE_NEW_API = window.FEATURE_FLAGS?.USE_INCIDENT_API_V1 ?? false;

function getApiUrl() {
    return USE_NEW_API
        ? '/api/v1/incidents'
        : urlGetIncidentCreated;
}

function transformResponse(data, useNewApi) {
    if (!useNewApi) return data; // Legacy format

    // Transform new API response to DataTables format
    return {
        draw: data.pagination.page,
        recordsTotal: data.pagination.total,
        recordsFiltered: data.pagination.total,
        data: data.data.map(item => ({
            incidentReport: {
                id: item.id,
                incidentNumber: item.incidentNumber,
                title: item.title,
                // ... map other fields
            }
        }))
    };
}
```

#### Phase 3: Deprecate Old Endpoint

```php
// TrackingActionsController.php
/**
 * @deprecated Use /api/v1/incidents instead. Will be removed in v3.0.
 */
public function getIncidentCreatedByCompanyAction(Request $request): JsonResponse
{
    trigger_deprecation('incident-module', '2.5',
        'The "%s" endpoint is deprecated, use "/api/v1/incidents" instead.',
        '/admin/ir/getIncidentCreatedByCompany'
    );

    // Delegate to new service for consistency
    return $this->forward(IncidentListController::class . '::list');
}
```

#### Phase 4: Remove Old Endpoint

After validation period (1-2 sprints), remove legacy endpoint.

---

### New Columns Support

The new API supports adding columns via query parameters:

```http
GET /api/v1/incidents?columns=incidentNumber,title,status,location,assignedTo,lastActivity
```

**Available Columns (extensible):**

| Column Key | Description | Default |
|------------|-------------|---------|
| `incidentNumber` | Incident number | ✅ |
| `title` | Incident title/type | ✅ |
| `severityLevel` | Severity with color | ✅ |
| `location` | Location name | ✅ |
| `department` | Department name | ✅ |
| `dateReport` | Creation date | ✅ |
| `dateIncident` | Incident date | ✅ |
| `resolutionDate` | Resolution date | ✅ |
| `status` | Status badge | ✅ |
| `elapsedTime` | Time since creation | ✅ |
| `assignedTo` | Current assignee | ❌ (new) |
| `lastActivity` | Last activity timestamp | ❌ (new) |
| `escalationLevel` | Current escalation level | ❌ (new) |
| `conversationCount` | Number of conversations | ❌ (new) |

---

### Estimated Time for API Refactoring

| Task | Hours |
|------|-------|
| Create DTOs (Criteria, ListItem, sub-DTOs) | 3-4 |
| Create IncidentListQuery (optimized) | 4-6 |
| Create GetIncidentList service | 3-4 |
| Create API controller | 2-3 |
| Create permission/meta loaders | 3-4 |
| Update routing | 1 |
| Update frontend (feature flag) | 2-3 |
| Write tests | 4-6 |
| Code review & fixes | 2-3 |
| **Total** | **24-34 hours** |

---

*Document Version: 2.0*
*Strategy: Version-based rollback via git revert*
*Created: December 2024*
