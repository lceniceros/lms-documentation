# Incident Module Migration Guide

## Table of Contents

1. [Overview](#overview)
2. [Migration Strategy](#migration-strategy)
3. [Phase 1: API Foundation](#phase-1-api-foundation)
4. [Phase 2: Incident List API](#phase-2-incident-list-api)
5. [Phase 3: Incident Detail API](#phase-3-incident-detail-api)
6. [Phase 4: Incident Actions API](#phase-4-incident-actions-api)
7. [Phase 5: Frontend Replacement](#phase-5-frontend-replacement)
8. [Phase 6: Legacy Deprecation](#phase-6-legacy-deprecation)
9. [Testing Strategy](#testing-strategy)
10. [Rollback Procedures](#rollback-procedures)
11. [Checklist](#checklist)

---

## Overview

This guide documents the migration of the Incident Module from legacy controller-based architecture to a clean API-driven design. The frontend will be **completely rebuilt** - old frontend code remains untouched until full deprecation.

### Migration Principles

| Principle | Description |
|-----------|-------------|
| **Parallel Development** | New API + New Frontend coexist with legacy |
| **No Legacy Modifications** | Old code untouched until deprecation phase |
| **API-First** | Backend API completed before frontend starts |
| **Incremental Delivery** | One endpoint at a time, validated in production |
| **Version-Based Rollback** | Git revert + deploy (no runtime switches) |

### Architecture Comparison

```
LEGACY ARCHITECTURE                    NEW ARCHITECTURE
─────────────────────                  ─────────────────────

┌─────────────────────┐                ┌─────────────────────┐
│  Twig Templates     │                │  New SPA/React      │
│  + jQuery/DataTables│                │  Frontend           │
└──────────┬──────────┘                └──────────┬──────────┘
           │                                      │
           │ renders HTML                         │ JSON API
           ▼                                      ▼
┌─────────────────────┐                ┌─────────────────────┐
│  God Controllers    │                │  API Controllers    │
│  (2,357 lines)      │                │  (< 100 lines each) │
└──────────┬──────────┘                └──────────┬──────────┘
           │                                      │
           │ mixed logic                          │ delegates
           ▼                                      ▼
┌─────────────────────┐                ┌─────────────────────┐
│  Utility Classes    │                │  Single-Purpose     │
│  (manual DI)        │                │  Services (__invoke)│
└──────────┬──────────┘                └──────────┬──────────┘
           │                                      │
           │ N+1 queries                          │ optimized
           ▼                                      ▼
┌─────────────────────┐                ┌─────────────────────┐
│  Direct Entity      │                │  Query Objects +    │
│  Access             │                │  DTOs               │
└─────────────────────┘                └─────────────────────┘
```

---

## Migration Strategy

### Timeline Overview

| Phase | Focus | Duration | Dependencies |
|-------|-------|----------|--------------|
| **Phase 1** | API Foundation (structure, auth, DTOs) | 1 week | None |
| **Phase 2** | Incident List API | 1 week | Phase 1 |
| **Phase 3** | Incident Detail API | 1 week | Phase 2 |
| **Phase 4** | Incident Actions API | 2 weeks | Phase 3 |
| **Phase 5** | Frontend Replacement | 2-3 weeks | Phase 4 |
| **Phase 6** | Legacy Deprecation | 1 week | Phase 5 + validation |

**Total: 8-10 weeks**

### Coexistence Model

```
Week 1-6: Development Phase
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  /admin/ir/*  ──────────► Legacy Controllers (UNTOUCHED)   │
│                           └── TrackingActionsController    │
│                           └── DisplayAjaxController        │
│                                                             │
│  /api/v1/incidents/*  ──► NEW API Controllers              │
│                           └── IncidentListController       │
│                           └── IncidentDetailController     │
│                           └── IncidentActionController     │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Week 7-8: Frontend Replacement
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  /admin/ir/* (old routes) ──► Legacy (still working)       │
│  /ir/*       (new routes) ──► New Frontend + New API       │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Week 9-10: Deprecation
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  /admin/ir/* ──► Redirect to /ir/* (301)                   │
│  /ir/*       ──► New Frontend (primary)                    │
│                                                             │
│  Legacy code marked @deprecated, removal scheduled         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: API Foundation

**Duration**: 1 week
**Goal**: Establish API structure, authentication, and shared components

### 1.1 Directory Structure

Create the following structure within TrackingBundle:

```
symfony/src/Incident/TrackingBundle/
├── Controller/
│   ├── Api/                          # NEW - API controllers
│   │   ├── IncidentListController.php
│   │   ├── IncidentDetailController.php
│   │   └── IncidentActionController.php
│   └── TrackingActionsController.php  # EXISTING - unchanged
│
├── DTO/                               # NEW - Data Transfer Objects
│   ├── Request/
│   │   ├── IncidentListCriteria.php
│   │   ├── CreateIncidentRequest.php
│   │   └── EscalateIncidentRequest.php
│   ├── Response/
│   │   ├── IncidentListItem.php
│   │   ├── IncidentDetail.php
│   │   ├── IncidentListResult.php
│   │   └── Components/
│   │       ├── IncidentTypeInfo.php
│   │       ├── SeverityLevelInfo.php
│   │       ├── LocationInfo.php
│   │       ├── DepartmentInfo.php
│   │       ├── IncidentDates.php
│   │       ├── IncidentStatusInfo.php
│   │       ├── ElapsedTimeInfo.php
│   │       ├── IncidentPermissions.php
│   │       └── IncidentMeta.php
│   └── QueryResult.php
│
├── Service/
│   ├── Api/                           # NEW - API services
│   │   ├── GetIncidentList.php
│   │   ├── GetIncidentDetail.php
│   │   ├── EscalateIncident.php
│   │   └── ResolveIncident.php
│   ├── Query/                         # NEW - Query objects
│   │   ├── IncidentListQuery.php
│   │   └── IncidentDetailQuery.php
│   ├── Support/                       # NEW - Support services
│   │   ├── UserContextResolver.php
│   │   ├── IncidentPermissionResolver.php
│   │   └── IncidentMetaLoader.php
│   └── [existing services unchanged]
│
└── Resources/
    └── config/
        ├── routing.yml                # Add API routes
        └── services.yml               # Add new services
```

### 1.2 API Routing Configuration

```yaml
# symfony/src/Incident/TrackingBundle/Resources/config/routing.yml

# ============================================
# NEW API ROUTES (v1)
# ============================================

# --- Incident List ---
api_v1_incidents_list:
    path: /api/v1/incidents
    controller: Incident\TrackingBundle\Controller\Api\IncidentListController::list
    methods: [GET]

# --- Incident Detail ---
api_v1_incidents_detail:
    path: /api/v1/incidents/{id}
    controller: Incident\TrackingBundle\Controller\Api\IncidentDetailController::detail
    methods: [GET]
    requirements:
        id: \d+

# --- Incident Actions ---
api_v1_incidents_escalate:
    path: /api/v1/incidents/{id}/escalate
    controller: Incident\TrackingBundle\Controller\Api\IncidentActionController::escalate
    methods: [POST]
    requirements:
        id: \d+

api_v1_incidents_resolve:
    path: /api/v1/incidents/{id}/resolve
    controller: Incident\TrackingBundle\Controller\Api\IncidentActionController::resolve
    methods: [POST]
    requirements:
        id: \d+

api_v1_incidents_assign:
    path: /api/v1/incidents/{id}/assign
    controller: Incident\TrackingBundle\Controller\Api\IncidentActionController::assign
    methods: [POST]
    requirements:
        id: \d+

# --- Drafts ---
api_v1_incidents_drafts:
    path: /api/v1/incidents/drafts
    controller: Incident\TrackingBundle\Controller\Api\IncidentListController::drafts
    methods: [GET]

# ============================================
# EXISTING ROUTES (unchanged)
# ============================================
incident_tracking_admin_index:
    path: /admin/ir/index
    defaults: { _controller: IncidentTrackingBundle:TrackingActions:index }

# ... rest of existing routes unchanged ...
```

### 1.3 User Context Resolver

```php
<?php
// symfony/src/Incident/TrackingBundle/Service/Support/UserContextResolver.php

namespace Incident\TrackingBundle\Service\Support;

use Doctrine\ORM\EntityManagerInterface;
use PlanetMedia\MedTrainerBundle\Entity\User;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\HttpFoundation\Session\SessionInterface;

final class UserContextResolver
{
    public function __construct(
        private readonly RequestStack $requestStack,
        private readonly EntityManagerInterface $em,
    ) {}

    public function resolve(?Request $request = null): UserContext
    {
        $session = $this->requestStack->getSession();

        /** @var User $user */
        $user = $session->get('_employee');
        $companyId = (int) $session->get('_company');
        $locationId = (int) $session->get('_location');
        $departmentId = (int) $session->get('_department');

        $accessibleLocationIds = [];
        if ($user->getDashboardType() === User::IS_DASHBOARD_TYPE_ADMIN) {
            $accessibleLocationIds = $this->getAdminLocationIds($companyId, $user->getId());
        }

        return new UserContext(
            userId: $user->getId(),
            companyId: $companyId,
            dashboardType: $user->getDashboardType(),
            currentLocationId: $locationId,
            currentDepartmentId: $departmentId,
            accessibleLocationIds: $accessibleLocationIds,
        );
    }

    private function getAdminLocationIds(int $companyId, int $userId): array
    {
        $query = $this->em->createQuery(
            'SELECT l.id
             FROM PlanetMediaMedTrainerBundle:Location l
             JOIN PlanetMediaMedTrainerBundle:EmployeeLocationAdmin ela WITH l.id = ela.idLocation
             WHERE l.idCompany = :companyId AND ela.idEmployee = :userId'
        )->setParameters([
            'companyId' => $companyId,
            'userId' => $userId,
        ]);

        return array_column($query->getArrayResult(), 'id');
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/Service/Support/UserContext.php

namespace Incident\TrackingBundle\Service\Support;

final class UserContext
{
    public function __construct(
        public readonly int $userId,
        public readonly int $companyId,
        public readonly string $dashboardType,
        public readonly int $currentLocationId,
        public readonly int $currentDepartmentId,
        public readonly array $accessibleLocationIds,
    ) {}

    public function isAdmin(): bool
    {
        return $this->dashboardType === 'A';
    }

    public function isSuperAdmin(): bool
    {
        return $this->dashboardType === 'S';
    }
}
```

### 1.4 Base API Controller

```php
<?php
// symfony/src/Incident/TrackingBundle/Controller/Api/AbstractApiController.php

namespace Incident\TrackingBundle\Controller\Api;

use Incident\TrackingBundle\Service\Support\UserContext;
use Incident\TrackingBundle\Service\Support\UserContextResolver;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

abstract class AbstractApiController extends AbstractController
{
    public function __construct(
        protected readonly UserContextResolver $userContextResolver,
    ) {}

    protected function getUserContext(): UserContext
    {
        return $this->userContextResolver->resolve();
    }

    protected function success(array $data, int $status = Response::HTTP_OK): JsonResponse
    {
        return $this->json($data, $status);
    }

    protected function error(string $message, int $status = Response::HTTP_BAD_REQUEST, array $errors = []): JsonResponse
    {
        return $this->json([
            'error' => true,
            'message' => $message,
            'errors' => $errors,
        ], $status);
    }

    protected function notFound(string $message = 'Resource not found'): JsonResponse
    {
        return $this->error($message, Response::HTTP_NOT_FOUND);
    }

    protected function forbidden(string $message = 'Access denied'): JsonResponse
    {
        return $this->error($message, Response::HTTP_FORBIDDEN);
    }
}
```

### 1.5 Services Configuration

```yaml
# symfony/src/Incident/TrackingBundle/Resources/config/services.yml

services:
    _defaults:
        autowire: true
        autoconfigure: true
        public: false

    # === Support Services ===
    Incident\TrackingBundle\Service\Support\UserContextResolver: ~
    Incident\TrackingBundle\Service\Support\IncidentPermissionResolver: ~
    Incident\TrackingBundle\Service\Support\IncidentMetaLoader: ~

    # === Query Objects ===
    Incident\TrackingBundle\Service\Query\IncidentListQuery: ~
    Incident\TrackingBundle\Service\Query\IncidentDetailQuery: ~

    # === API Services ===
    Incident\TrackingBundle\Service\Api\GetIncidentList: ~
    Incident\TrackingBundle\Service\Api\GetIncidentDetail: ~
    Incident\TrackingBundle\Service\Api\EscalateIncident: ~
    Incident\TrackingBundle\Service\Api\ResolveIncident: ~

    # === API Controllers ===
    Incident\TrackingBundle\Controller\Api\IncidentListController:
        tags: ['controller.service_arguments']

    Incident\TrackingBundle\Controller\Api\IncidentDetailController:
        tags: ['controller.service_arguments']

    Incident\TrackingBundle\Controller\Api\IncidentActionController:
        tags: ['controller.service_arguments']
```

### 1.6 Phase 1 Deliverables Checklist

- [ ] Directory structure created
- [ ] `UserContextResolver` implemented and tested
- [ ] `UserContext` DTO created
- [ ] `AbstractApiController` base class created
- [ ] API routing configured (routes exist, return 501 Not Implemented)
- [ ] Services configuration updated
- [ ] Unit tests for `UserContextResolver`

---

## Phase 2: Incident List API

**Duration**: 1 week
**Goal**: Complete `/api/v1/incidents` endpoint with filters and pagination

### 2.1 Request DTO

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Request/IncidentListCriteria.php

namespace Incident\TrackingBundle\DTO\Request;

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

        #[Assert\Choice(['incidentNumber', 'title', 'dateReport', 'dateIncident', 'status', 'severityLevel', 'location', 'department'])]
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

        public readonly array $accessibleLocationIds = [],
        public readonly ?int $userId = null,
        public readonly string $dashboardType = 'S',
    ) {}

    public static function fromRequest(array $params, int $companyId, array $userContext): self
    {
        $page = max(1, (int) ($params['page'] ?? 1));
        $limit = min(100, max(1, (int) ($params['limit'] ?? 10)));
        $offset = ($page - 1) * $limit;

        return new self(
            companyId: $companyId,
            limit: $limit,
            offset: $offset,
            sortBy: self::validateSortBy($params['sort'] ?? 'dateReport'),
            sortOrder: strtolower($params['order'] ?? 'desc') === 'asc' ? 'asc' : 'desc',
            statuses: self::parseStatuses($params['status'] ?? null),
            dateFrom: self::parseDate($params['dateFrom'] ?? null),
            dateTo: self::parseDate($params['dateTo'] ?? null),
            search: self::sanitizeSearch($params['search'] ?? null),
            locationId: isset($params['locationId']) ? (int) $params['locationId'] : null,
            departmentId: isset($params['departmentId']) ? (int) $params['departmentId'] : null,
            severityLevelId: isset($params['severityLevel']) ? (int) $params['severityLevel'] : null,
            accessibleLocationIds: $userContext['locationIds'] ?? [],
            userId: $userContext['userId'] ?? null,
            dashboardType: $userContext['dashboardType'] ?? 'S',
        );
    }

    private static function validateSortBy(string $value): string
    {
        $allowed = ['incidentNumber', 'title', 'dateReport', 'dateIncident', 'status', 'severityLevel', 'location', 'department'];
        return in_array($value, $allowed, true) ? $value : 'dateReport';
    }

    private static function parseStatuses(?string $value): ?array
    {
        if ($value === null || trim($value) === '') {
            return null;
        }
        return array_filter(array_map('intval', explode(',', $value)));
    }

    private static function parseDate(?string $value): ?\DateTimeInterface
    {
        if ($value === null || trim($value) === '') {
            return null;
        }
        try {
            return new \DateTimeImmutable($value);
        } catch (\Exception) {
            return null;
        }
    }

    private static function sanitizeSearch(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $value = trim($value);
        if ($value === '' || mb_strlen($value) > 100) {
            return mb_strlen($value) > 100 ? mb_substr($value, 0, 100) : null;
        }
        return $value;
    }

    public function getPage(): int
    {
        return $this->limit > 0 ? (int) floor($this->offset / $this->limit) + 1 : 1;
    }
}
```

### 2.2 Response DTOs

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/IncidentListResult.php

namespace Incident\TrackingBundle\DTO\Response;

final class IncidentListResult
{
    /**
     * @param IncidentListItem[] $items
     */
    public function __construct(
        public readonly array $items,
        public readonly int $total,
        public readonly int $page,
        public readonly int $limit,
    ) {}

    public function getTotalPages(): int
    {
        return $this->limit > 0 ? (int) ceil($this->total / $this->limit) : 0;
    }

    public function toArray(): array
    {
        return [
            'data' => array_map(fn(IncidentListItem $item) => $item->toArray(), $this->items),
            'pagination' => [
                'page' => $this->page,
                'limit' => $this->limit,
                'total' => $this->total,
                'totalPages' => $this->getTotalPages(),
            ],
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/IncidentListItem.php

namespace Incident\TrackingBundle\DTO\Response;

use Incident\TrackingBundle\DTO\Response\Components\DepartmentInfo;
use Incident\TrackingBundle\DTO\Response\Components\ElapsedTimeInfo;
use Incident\TrackingBundle\DTO\Response\Components\IncidentDates;
use Incident\TrackingBundle\DTO\Response\Components\IncidentMeta;
use Incident\TrackingBundle\DTO\Response\Components\IncidentPermissions;
use Incident\TrackingBundle\DTO\Response\Components\IncidentStatusInfo;
use Incident\TrackingBundle\DTO\Response\Components\IncidentTypeInfo;
use Incident\TrackingBundle\DTO\Response\Components\LocationInfo;
use Incident\TrackingBundle\DTO\Response\Components\SeverityLevelInfo;

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

### 2.3 Component DTOs

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/IncidentTypeInfo.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class IncidentTypeInfo
{
    public function __construct(
        public readonly int $id,
        public readonly string $name,
    ) {}

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/SeverityLevelInfo.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class SeverityLevelInfo
{
    public function __construct(
        public readonly int $level,
        public readonly string $color,
        public readonly string $description,
    ) {}

    public function toArray(): array
    {
        return [
            'level' => $this->level,
            'color' => $this->color,
            'description' => $this->description,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/LocationInfo.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class LocationInfo
{
    public function __construct(
        public readonly int $id,
        public readonly string $name,
    ) {}

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/DepartmentInfo.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class DepartmentInfo
{
    public function __construct(
        public readonly int $id,
        public readonly string $name,
    ) {}

    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/IncidentDates.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class IncidentDates
{
    public function __construct(
        public readonly ?string $incident,
        public readonly string $reported,
        public readonly ?string $resolved,
    ) {}

    public function toArray(): array
    {
        return [
            'incident' => $this->incident,
            'reported' => $this->reported,
            'resolved' => $this->resolved,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/IncidentStatusInfo.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class IncidentStatusInfo
{
    public const STATUS_NEW = 1;
    public const STATUS_ESCALATED = 2;
    public const STATUS_RESOLVED = 3;
    public const STATUS_PENDING = 4;
    public const STATUS_INITIATED = 5;

    private const LABELS = [
        self::STATUS_NEW => 'New',
        self::STATUS_ESCALATED => 'Escalated',
        self::STATUS_RESOLVED => 'Resolved',
        self::STATUS_PENDING => 'Pending',
        self::STATUS_INITIATED => 'Initiated',
    ];

    public function __construct(
        public readonly int $code,
        public readonly string $label,
    ) {}

    public static function fromCode(int $code): self
    {
        return new self(
            code: $code,
            label: self::LABELS[$code] ?? 'Unknown',
        );
    }

    public function toArray(): array
    {
        return [
            'code' => $this->code,
            'label' => $this->label,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/ElapsedTimeInfo.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class ElapsedTimeInfo
{
    public function __construct(
        public readonly int $hours,
        public readonly string $formatted,
    ) {}

    public static function fromHours(int $hours): self
    {
        return new self(
            hours: $hours,
            formatted: self::format($hours),
        );
    }

    private static function format(int $hours): string
    {
        if ($hours < 24) {
            return $hours . ' hour' . ($hours !== 1 ? 's' : '');
        }

        $days = (int) floor($hours / 24);
        if ($days < 30) {
            return $days . ' day' . ($days !== 1 ? 's' : '');
        }

        $months = (int) floor($days / 30);
        return $months . ' month' . ($months !== 1 ? 's' : '');
    }

    public function toArray(): array
    {
        return [
            'hours' => $this->hours,
            'formatted' => $this->formatted,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/IncidentPermissions.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class IncidentPermissions
{
    public function __construct(
        public readonly bool $canView = true,
        public readonly bool $canEdit = false,
        public readonly bool $canDelete = false,
        public readonly bool $canDownload = true,
        public readonly bool $canEscalate = false,
        public readonly bool $canResolve = false,
    ) {}

    public function toArray(): array
    {
        return [
            'canView' => $this->canView,
            'canEdit' => $this->canEdit,
            'canDelete' => $this->canDelete,
            'canDownload' => $this->canDownload,
            'canEscalate' => $this->canEscalate,
            'canResolve' => $this->canResolve,
        ];
    }
}
```

```php
<?php
// symfony/src/Incident/TrackingBundle/DTO/Response/Components/IncidentMeta.php

namespace Incident\TrackingBundle\DTO\Response\Components;

final class IncidentMeta
{
    public function __construct(
        public readonly bool $isAnonymous = false,
        public readonly bool $isUploaded = false,
        public readonly int $conversationCount = 0,
        public readonly ?string $matrixType = null,
    ) {}

    public function toArray(): array
    {
        return [
            'isAnonymous' => $this->isAnonymous,
            'isUploaded' => $this->isUploaded,
            'conversationCount' => $this->conversationCount,
            'matrixType' => $this->matrixType,
        ];
    }
}
```

### 2.4 Query Object

```php
<?php
// symfony/src/Incident/TrackingBundle/Service/Query/IncidentListQuery.php

namespace Incident\TrackingBundle\Service\Query;

use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\QueryBuilder;
use Incident\TrackingBundle\DTO\QueryResult;
use Incident\TrackingBundle\DTO\Request\IncidentListCriteria;

final class IncidentListQuery
{
    private const COLUMN_MAP = [
        'incidentNumber' => 'isd.incidentNumber',
        'title' => 'title',
        'dateReport' => 'isd.dateReport',
        'dateIncident' => 'isd.dateIncident',
        'status' => 'isd.status',
        'severityLevel' => 'severityLevelId',
        'location' => 'l.name',
        'department' => 'departmentName',
    ];

    public function __construct(
        private readonly EntityManagerInterface $em,
    ) {}

    public function __invoke(IncidentListCriteria $criteria): QueryResult
    {
        $qb = $this->createBaseQuery($criteria);

        // Count total before pagination
        $countQb = clone $qb;
        $countQb->select('COUNT(DISTINCT cir.id)');
        $total = (int) $countQb->getQuery()->getSingleScalarResult();

        // Apply sorting and pagination
        $sortColumn = self::COLUMN_MAP[$criteria->sortBy] ?? 'isd.dateReport';
        $qb->orderBy($sortColumn, $criteria->sortOrder)
           ->addOrderBy('cir.id', $criteria->sortOrder)
           ->setFirstResult($criteria->offset)
           ->setMaxResults($criteria->limit);

        return new QueryResult(
            items: $qb->getQuery()->getArrayResult(),
            total: $total,
        );
    }

    private function createBaseQuery(IncidentListCriteria $criteria): QueryBuilder
    {
        $qb = $this->em->createQueryBuilder();

        $qb->select(
            'cir.id',
            'cir.id AS incidentDataId',
            'isd.id AS incidentScalableDataId',
            'isd.incidentNumber',
            'CASE WHEN cir.title IS NULL OR cir.title = \'\' THEN ir.name ELSE cir.title END AS title',
            'ir.id AS incidentTypeId',
            'ir.name AS incidentTypeName',
            'l.id AS locationId',
            'l.name AS locationName',
            'cd.id AS departmentId',
            'COALESCE(cd.name, isd.department) AS departmentName',
            'DATE_FORMAT(isd.dateIncident, \'%Y-%m-%d\') AS dateIncident',
            'DATE_FORMAT(isd.dateReport, \'%Y-%m-%dT%H:%i:%sZ\') AS dateReport',
            'DATE_FORMAT(isd.resolutionDate, \'%Y-%m-%dT%H:%i:%sZ\') AS resolutionDate',
            'isd.status',
            'TIMESTAMPDIFF(HOUR, isd.dateReport, COALESCE(isd.resolutionDate, CURRENT_TIMESTAMP())) AS elapsedHours',
            'ci.isAnonymous',
            'cir.status AS companyStatus',
            'ismc.escalationType AS matrixType',
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
        ->andWhere('(ci.isAnonymous IS NOT NULL OR ci.id IS NULL)')
        ->setParameter('companyId', $criteria->companyId);

        $this->applyFilters($qb, $criteria);
        $this->applyLocationAccess($qb, $criteria);

        return $qb;
    }

    private function applyFilters(QueryBuilder $qb, IncidentListCriteria $criteria): void
    {
        // Status filter
        if ($criteria->statuses !== null && count($criteria->statuses) > 0) {
            $qb->andWhere('isd.status IN (:statuses)')
               ->setParameter('statuses', $criteria->statuses);
        } else {
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
            $searchTerm = '%' . mb_strtolower(str_replace(['%', '_'], ['\\%', '\\_'], trim($criteria->search))) . '%';
            $qb->andWhere('(
                LOWER(isd.incidentNumber) LIKE :search
                OR LOWER(cir.title) LIKE :search
                OR LOWER(isd.incidentDescription) LIKE :search
                OR LOWER(isd.description) LIKE :search
                OR LOWER(ir.name) LIKE :search
            )')
            ->setParameter('search', $searchTerm);
        }
    }

    private function applyLocationAccess(QueryBuilder $qb, IncidentListCriteria $criteria): void
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

### 2.5 API Service

```php
<?php
// symfony/src/Incident/TrackingBundle/Service/Api/GetIncidentList.php

namespace Incident\TrackingBundle\Service\Api;

use Incident\TrackingBundle\DTO\Request\IncidentListCriteria;
use Incident\TrackingBundle\DTO\Response\Components\DepartmentInfo;
use Incident\TrackingBundle\DTO\Response\Components\ElapsedTimeInfo;
use Incident\TrackingBundle\DTO\Response\Components\IncidentDates;
use Incident\TrackingBundle\DTO\Response\Components\IncidentMeta;
use Incident\TrackingBundle\DTO\Response\Components\IncidentPermissions;
use Incident\TrackingBundle\DTO\Response\Components\IncidentStatusInfo;
use Incident\TrackingBundle\DTO\Response\Components\IncidentTypeInfo;
use Incident\TrackingBundle\DTO\Response\Components\LocationInfo;
use Incident\TrackingBundle\DTO\Response\Components\SeverityLevelInfo;
use Incident\TrackingBundle\DTO\Response\IncidentListItem;
use Incident\TrackingBundle\DTO\Response\IncidentListResult;
use Incident\TrackingBundle\Service\Query\IncidentListQuery;
use Incident\TrackingBundle\Service\Support\IncidentMetaLoader;
use Incident\TrackingBundle\Service\Support\IncidentPermissionResolver;

final class GetIncidentList
{
    public function __construct(
        private readonly IncidentListQuery $query,
        private readonly IncidentPermissionResolver $permissionResolver,
        private readonly IncidentMetaLoader $metaLoader,
    ) {}

    public function __invoke(IncidentListCriteria $criteria): IncidentListResult
    {
        $queryResult = ($this->query)($criteria);

        // Batch load additional data (prevents N+1)
        $incidentIds = array_column($queryResult->items, 'id');

        $permissionsMap = [];
        $metaMap = [];

        if (count($incidentIds) > 0) {
            $permissionsMap = $this->permissionResolver->resolveForIncidents(
                $incidentIds,
                $criteria->userId,
                $criteria->dashboardType
            );
            $metaMap = $this->metaLoader->loadForIncidents($incidentIds);
        }

        $items = array_map(
            fn(array $row) => $this->toListItem(
                $row,
                $permissionsMap[$row['id']] ?? [],
                $metaMap[$row['id']] ?? []
            ),
            $queryResult->items
        );

        return new IncidentListResult(
            items: $items,
            total: $queryResult->total,
            page: $criteria->getPage(),
            limit: $criteria->limit,
        );
    }

    private function toListItem(array $row, array $permissions, array $meta): IncidentListItem
    {
        return new IncidentListItem(
            id: (int) $row['id'],
            incidentNumber: $row['incidentNumber'] ?? '',
            title: $row['title'] ?? '',
            type: new IncidentTypeInfo(
                id: (int) $row['incidentTypeId'],
                name: $row['incidentTypeName'] ?? '',
            ),
            severityLevel: $row['severityLevelId'] !== null
                ? new SeverityLevelInfo(
                    level: (int) ($meta['severityLevel'] ?? $row['severityLevelId']),
                    color: $meta['severityLevelColor'] ?? '#999999',
                    description: $meta['severityLevelDescription'] ?? '',
                )
                : null,
            location: new LocationInfo(
                id: (int) $row['locationId'],
                name: $row['locationName'] ?? '',
            ),
            department: $row['departmentId'] !== null
                ? new DepartmentInfo(
                    id: (int) $row['departmentId'],
                    name: $row['departmentName'] ?? '',
                )
                : null,
            dates: new IncidentDates(
                incident: $row['dateIncident'],
                reported: $row['dateReport'],
                resolved: $row['resolutionDate'],
            ),
            status: IncidentStatusInfo::fromCode((int) $row['status']),
            elapsedTime: ElapsedTimeInfo::fromHours((int) ($row['elapsedHours'] ?? 0)),
            permissions: new IncidentPermissions(
                canView: $permissions['canView'] ?? true,
                canEdit: $permissions['canEdit'] ?? false,
                canDelete: $permissions['canDelete'] ?? false,
                canDownload: $permissions['canDownload'] ?? true,
                canEscalate: $permissions['canEscalate'] ?? false,
                canResolve: $permissions['canResolve'] ?? false,
            ),
            meta: new IncidentMeta(
                isAnonymous: (bool) ($row['isAnonymous'] ?? false),
                isUploaded: ($row['companyStatus'] ?? '') === 'U',
                conversationCount: (int) ($meta['conversationCount'] ?? 0),
                matrixType: $this->getMatrixTypeName($row['matrixType'] ?? null),
            ),
        );
    }

    private function getMatrixTypeName(?int $type): ?string
    {
        return match ($type) {
            1 => 'RACI',
            2 => 'Functional One-Way',
            4 => 'Functional Two-Way',
            5 => 'Group',
            default => null,
        };
    }
}
```

### 2.6 API Controller

```php
<?php
// symfony/src/Incident/TrackingBundle/Controller/Api/IncidentListController.php

namespace Incident\TrackingBundle\Controller\Api;

use Incident\TrackingBundle\DTO\Request\IncidentListCriteria;
use Incident\TrackingBundle\Service\Api\GetIncidentList;
use Incident\TrackingBundle\Service\Support\UserContextResolver;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api/v1/incidents', name: 'api_v1_incidents_')]
final class IncidentListController extends AbstractApiController
{
    public function __construct(
        UserContextResolver $userContextResolver,
        private readonly GetIncidentList $getIncidentList,
    ) {
        parent::__construct($userContextResolver);
    }

    #[Route('', name: 'list', methods: ['GET'])]
    public function list(Request $request): JsonResponse
    {
        $userContext = $this->getUserContext();

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

        return $this->success($result->toArray());
    }

    #[Route('/drafts', name: 'drafts', methods: ['GET'])]
    public function drafts(Request $request): JsonResponse
    {
        // TODO: Implement in Phase 3
        return $this->error('Not implemented', 501);
    }
}
```

### 2.7 Phase 2 Deliverables Checklist

- [ ] All DTOs created and tested
- [ ] `IncidentListQuery` implemented (single optimized query)
- [ ] `IncidentPermissionResolver` implemented
- [ ] `IncidentMetaLoader` implemented (batch loading)
- [ ] `GetIncidentList` service implemented
- [ ] `IncidentListController` implemented
- [ ] Unit tests for all DTOs
- [ ] Unit tests for query object
- [ ] Integration test for full endpoint
- [ ] Manual testing with Postman/curl
- [ ] API returns correct data for all filter combinations

---

## Phase 3: Incident Detail API

**Duration**: 1 week
**Goal**: Complete `/api/v1/incidents/{id}` endpoint

### 3.1 Endpoint Specification

```http
GET /api/v1/incidents/12345
Authorization: Bearer {token}
```

**Response:**

```json
{
  "data": {
    "id": 12345,
    "incidentNumber": "IR-2024-001",
    "title": "Patient Fall in Room 302",
    "description": "Patient fell while attempting to get out of bed...",
    "type": { "id": 5, "name": "Patient Safety" },
    "severityLevel": { "level": 3, "color": "#FF9800", "description": "Moderate" },
    "location": { "id": 10, "name": "Main Hospital" },
    "department": { "id": 25, "name": "Emergency Department" },
    "dates": {
      "incident": "2024-12-01",
      "reported": "2024-12-01T14:30:00Z",
      "resolved": null
    },
    "status": { "code": 2, "label": "Escalated" },
    "reporter": {
      "id": 100,
      "name": "John Doe",
      "email": "john.doe@example.com"
    },
    "currentAssignee": {
      "id": 150,
      "name": "Jane Smith",
      "role": "R"
    },
    "escalations": [
      {
        "id": 1,
        "employeeId": 150,
        "employeeName": "Jane Smith",
        "role": "R",
        "status": "active",
        "assignedAt": "2024-12-01T15:00:00Z"
      }
    ],
    "resolutions": [],
    "attachments": [
      {
        "id": 1,
        "filename": "photo1.jpg",
        "url": "/download/evidence/abc123",
        "uploadedAt": "2024-12-01T14:35:00Z"
      }
    ],
    "conversations": {
      "count": 3,
      "lastActivity": "2024-12-02T10:00:00Z"
    },
    "permissions": {
      "canView": true,
      "canEdit": true,
      "canDelete": false,
      "canEscalate": true,
      "canResolve": false
    },
    "formData": {
      "sections": [...]
    }
  }
}
```

### 3.2 Phase 3 Deliverables Checklist

- [ ] `IncidentDetail` response DTO
- [ ] `IncidentDetailQuery` query object
- [ ] `GetIncidentDetail` service
- [ ] `IncidentDetailController` action
- [ ] Permission validation (IncidentVoter integration)
- [ ] Unit and integration tests

---

## Phase 4: Incident Actions API

**Duration**: 2 weeks
**Goal**: Complete action endpoints (escalate, resolve, assign)

### 4.1 Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/incidents/{id}/escalate` | POST | Escalate incident |
| `/api/v1/incidents/{id}/resolve` | POST | Submit resolution |
| `/api/v1/incidents/{id}/assign` | POST | Assign/reassign incident |
| `/api/v1/incidents/{id}/close` | POST | Close incident |
| `/api/v1/incidents/{id}/conversations` | GET | Get conversations |
| `/api/v1/incidents/{id}/conversations` | POST | Add conversation |

### 4.2 Phase 4 Deliverables Checklist

- [ ] Request DTOs for each action
- [ ] Response DTOs for each action
- [ ] Services for each action
- [ ] Controller actions implemented
- [ ] Validation rules implemented
- [ ] Permission checks implemented
- [ ] Unit and integration tests

---

## Phase 5: Frontend Replacement

**Duration**: 2-3 weeks
**Goal**: New frontend consuming API (old frontend untouched)

### 5.1 Frontend Routes (New)

| New Route | Description | API Endpoint |
|-----------|-------------|--------------|
| `/ir` | Incident list | `GET /api/v1/incidents` |
| `/ir/:id` | Incident detail | `GET /api/v1/incidents/:id` |
| `/ir/:id/edit` | Edit incident | `GET/PUT /api/v1/incidents/:id` |
| `/ir/create` | Create incident | `POST /api/v1/incidents` |

### 5.2 Routing Configuration for New Frontend

```yaml
# symfony/src/Incident/TrackingBundle/Resources/config/routing.yml

# NEW FRONTEND ROUTES (serve SPA shell)
incident_frontend_index:
    path: /ir
    controller: Incident\TrackingBundle\Controller\Frontend\IncidentFrontendController::index
    methods: [GET]

incident_frontend_catchall:
    path: /ir/{path}
    controller: Incident\TrackingBundle\Controller\Frontend\IncidentFrontendController::index
    methods: [GET]
    requirements:
        path: .+
```

### 5.3 Phase 5 Deliverables Checklist

- [ ] New frontend application created
- [ ] API client service implemented
- [ ] Incident list view
- [ ] Incident detail view
- [ ] Filter components
- [ ] Pagination component
- [ ] Action buttons (escalate, resolve, etc.)
- [ ] Error handling
- [ ] Loading states
- [ ] E2E tests

---

## Phase 6: Legacy Deprecation

**Duration**: 1 week
**Goal**: Deprecate and plan removal of legacy code

### 6.1 Deprecation Steps

1. **Add deprecation notices** to legacy controllers
2. **Add redirects** from old routes to new routes
3. **Monitor usage** of deprecated endpoints
4. **Schedule removal** after validation period

### 6.2 Redirect Configuration

```yaml
# After frontend validation (1-2 sprints)
incident_legacy_redirect:
    path: /admin/ir/index
    controller: Symfony\Bundle\FrameworkBundle\Controller\RedirectController
    defaults:
        route: incident_frontend_index
        permanent: true
```

### 6.3 Deprecation Annotations

```php
<?php
// TrackingActionsController.php

/**
 * @deprecated since version 3.0, use /api/v1/incidents instead.
 *             Will be removed in version 4.0.
 */
public function getIncidentCreatedByCompanyAction(Request $request): JsonResponse
{
    trigger_deprecation(
        'incident-module',
        '3.0',
        'The "%s" method is deprecated, use the API at "/api/v1/incidents" instead.',
        __METHOD__
    );

    // Existing implementation continues to work
    // ...
}
```

### 6.4 Phase 6 Deliverables Checklist

- [ ] All legacy endpoints marked `@deprecated`
- [ ] Deprecation logs enabled
- [ ] Redirects configured
- [ ] Documentation updated
- [ ] Removal date scheduled
- [ ] Migration guide for any external consumers

---

## Testing Strategy

### Unit Tests

```php
<?php
// tests/Unit/Incident/TrackingBundle/DTO/Request/IncidentListCriteriaTest.php

namespace Tests\Unit\Incident\TrackingBundle\DTO\Request;

use Incident\TrackingBundle\DTO\Request\IncidentListCriteria;
use PHPUnit\Framework\TestCase;

class IncidentListCriteriaTest extends TestCase
{
    public function testFromRequestWithDefaults(): void
    {
        $criteria = IncidentListCriteria::fromRequest(
            params: [],
            companyId: 1,
            userContext: ['userId' => 10, 'dashboardType' => 'S', 'locationIds' => []],
        );

        $this->assertSame(1, $criteria->companyId);
        $this->assertSame(10, $criteria->limit);
        $this->assertSame(0, $criteria->offset);
        $this->assertSame('dateReport', $criteria->sortBy);
        $this->assertSame('desc', $criteria->sortOrder);
    }

    public function testFromRequestWithPagination(): void
    {
        $criteria = IncidentListCriteria::fromRequest(
            params: ['page' => '3', 'limit' => '25'],
            companyId: 1,
            userContext: ['userId' => 10, 'dashboardType' => 'S', 'locationIds' => []],
        );

        $this->assertSame(25, $criteria->limit);
        $this->assertSame(50, $criteria->offset); // (3-1) * 25
        $this->assertSame(3, $criteria->getPage());
    }

    public function testFromRequestWithFilters(): void
    {
        $criteria = IncidentListCriteria::fromRequest(
            params: [
                'status' => '1,2,3',
                'dateFrom' => '2024-01-01',
                'dateTo' => '2024-12-31',
                'search' => 'patient fall',
                'locationId' => '10',
            ],
            companyId: 1,
            userContext: ['userId' => 10, 'dashboardType' => 'S', 'locationIds' => []],
        );

        $this->assertSame([1, 2, 3], $criteria->statuses);
        $this->assertSame('2024-01-01', $criteria->dateFrom->format('Y-m-d'));
        $this->assertSame('patient fall', $criteria->search);
        $this->assertSame(10, $criteria->locationId);
    }

    public function testLimitIsCappedAt100(): void
    {
        $criteria = IncidentListCriteria::fromRequest(
            params: ['limit' => '500'],
            companyId: 1,
            userContext: [],
        );

        $this->assertSame(100, $criteria->limit);
    }

    public function testSearchIsTruncatedAt100Characters(): void
    {
        $longSearch = str_repeat('a', 150);

        $criteria = IncidentListCriteria::fromRequest(
            params: ['search' => $longSearch],
            companyId: 1,
            userContext: [],
        );

        $this->assertSame(100, mb_strlen($criteria->search));
    }
}
```

### Integration Tests

```php
<?php
// tests/Functional/Incident/TrackingBundle/Controller/Api/IncidentListControllerTest.php

namespace Tests\Functional\Incident\TrackingBundle\Controller\Api;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class IncidentListControllerTest extends WebTestCase
{
    public function testListReturnsJsonResponse(): void
    {
        $client = static::createClient();
        // Setup authenticated session...

        $client->request('GET', '/api/v1/incidents');

        $this->assertResponseIsSuccessful();
        $this->assertResponseHeaderSame('content-type', 'application/json');

        $data = json_decode($client->getResponse()->getContent(), true);

        $this->assertArrayHasKey('data', $data);
        $this->assertArrayHasKey('pagination', $data);
        $this->assertArrayHasKey('page', $data['pagination']);
        $this->assertArrayHasKey('limit', $data['pagination']);
        $this->assertArrayHasKey('total', $data['pagination']);
        $this->assertArrayHasKey('totalPages', $data['pagination']);
    }

    public function testListWithFilters(): void
    {
        $client = static::createClient();
        // Setup authenticated session...

        $client->request('GET', '/api/v1/incidents', [
            'status' => '1,2',
            'page' => '1',
            'limit' => '5',
        ]);

        $this->assertResponseIsSuccessful();

        $data = json_decode($client->getResponse()->getContent(), true);

        $this->assertLessThanOrEqual(5, count($data['data']));
    }
}
```

---

## Rollback Procedures

### API Rollback

```bash
# If new API has issues, simply revert the commit
git log --oneline -10  # Find the problematic commit
git revert <commit-hash>
git push origin master
# Deploy will restore previous version
# Legacy endpoints continue working
```

### Frontend Rollback

```bash
# If new frontend has issues
# Option 1: Revert frontend deploy (new frontend disappears)
git revert <frontend-commit>
git push origin master

# Option 2: Disable new routes temporarily
# Edit routing.yml to comment out /ir/* routes
# Users continue using /admin/ir/* (legacy)
```

---

## Checklist

### Pre-Migration

- [ ] Read and understand this guide
- [ ] Review current codebase metrics
- [ ] Set up development environment
- [ ] Create feature branch

### Phase 1 Complete

- [ ] Directory structure created
- [ ] Base classes implemented
- [ ] Routing configured
- [ ] Unit tests passing

### Phase 2 Complete

- [ ] `/api/v1/incidents` endpoint working
- [ ] All filters working
- [ ] Pagination working
- [ ] Performance acceptable (< 500ms)
- [ ] Unit tests passing
- [ ] Integration tests passing

### Phase 3 Complete

- [ ] `/api/v1/incidents/{id}` endpoint working
- [ ] Permissions enforced
- [ ] Unit tests passing

### Phase 4 Complete

- [ ] All action endpoints working
- [ ] Validation working
- [ ] Permissions enforced
- [ ] Unit tests passing

### Phase 5 Complete

- [ ] New frontend deployed
- [ ] All features working
- [ ] Performance acceptable
- [ ] E2E tests passing
- [ ] User acceptance testing passed

### Phase 6 Complete

- [ ] Legacy endpoints deprecated
- [ ] Redirects in place
- [ ] Monitoring enabled
- [ ] Removal date scheduled

---

*Document Version: 1.0*
*Created: December 2024*
*Last Updated: December 2024*
