# Incident Reports - Date Filters Implementation Guide

**Epic:** LSFB-62813  
**Related Story:** LSFB-64416 (Main Filters), LSFB-64418 (More Filters)  
**Date:** January 2026

---

## Overview

This document provides implementation details for the 4 date range filters in the Incident Reports Workflow Table API. The implementation reuses the existing `DateRange` class pattern established in the Assignments and Employees modules.

---

## Date Fields Available

| Filter Name | DB Column | Entity Property | Type | Nullable | Description |
|-------------|-----------|-----------------|------|----------|-------------|
| `incidentDate` | `date_incident` | `$dateIncident` | `date` | NO | Date when incident occurred |
| `reportDate` | `date_report` | `$dateReport` | `datetime` | NO | Date report was created |
| `resolutionDate` | `resolution_date` | `$resolutionDate` | `datetime` | NO* | Date incident was resolved |
| `lastUpdatedDate` | `last_updated_date` | `$lastUpdatedDate` | `datetime` | YES | Last modification timestamp |

**Note:** While `resolution_date` is marked as NOT NULL in the entity annotation, it can contain empty/NULL values in practice for unresolved incidents.

---

## DateRange Class

**Location:** `symfony/src/MedTrainer/SPABundle/Models/FilterValues/DateRange.php`

**Already implemented and tested** in the codebase. Used by:
- Course Assignments filtering
- Employee filtering
- Learning reports

### Key Features

```php
namespace MedTrainer\SPABundle\Models\FilterValues;

use Carbon\CarbonImmutable;

class DateRange implements FilterValue
{
    /** @var CarbonImmutable */
    private $from;
    
    /** @var CarbonImmutable */
    private $to;
    
    /** @var bool|null */
    private $blanks;
    
    public static function create($value): self;
    public function getFrom(): ?CarbonImmutable;
    public function getTo(): ?CarbonImmutable;
    public function hasBlanks(): bool;
    public function onlyBlanks(): bool;
    public function isEmpty(): bool;
}
```

### Usage Pattern

```php
// Create from request parameters
$dateRange = DateRange::create([
    'from' => '2024-01-01',        // ISO 8601 date/datetime
    'to' => '2024-12-31',          // ISO 8601 date/datetime
    'empty' => true                 // Include NULL values
]);

// Check if empty (skip filtering)
if ($dateRange->isEmpty()) {
    return $this; // No filter applied
}

// Case 1: Only NULL values
if ($dateRange->onlyBlanks()) {
    $qb->andWhere('field IS NULL');
}

// Case 2: Date range
if ($dateRange->getFrom()) {
    $qb->andWhere('field >= :from')
       ->setParameter('from', $dateRange->getFrom());
}

// Case 3: Range + NULL values
if ($dateRange->hasBlanks() && !$dateRange->onlyBlanks()) {
    // Wrap conditions with OR NULL
}
```

---

## Request Parameters Format

### API Query String Examples

**Simple range:**
```
GET /incident-reports?incidentDate[from]=2024-01-01&incidentDate[to]=2024-12-31
```

**Range with NULL values:**
```
GET /incident-reports?resolutionDate[from]=2024-01-01&resolutionDate[to]=2024-12-31&resolutionDate[empty]=true
```

**Only NULL values:**
```
GET /incident-reports?lastUpdatedDate[empty]=true
```

**Multiple date filters combined:**
```
GET /incident-reports?incidentDate[from]=2024-01-01&reportDate[to]=2024-12-31&resolutionDate[empty]=false
```

---

## Implementation Tasks

### Task 1: Add Date Filters to Query Object

**File:** `symfony/src/Incident/WorkflowTableBundle/Request/IncidentListQuery.php`

```php
<?php

declare(strict_types=1);

namespace MedTrainer\Incident\WorkflowTableBundle\Request;

use MedTrainer\SPABundle\Models\FilterValues\DateRange;

class IncidentListQuery
{
    /** @var DateRange|null */
    private $incidentDateRange;
    
    /** @var DateRange|null */
    private $reportDateRange;
    
    /** @var DateRange|null */
    private $resolutionDateRange;
    
    /** @var DateRange|null */
    private $lastUpdatedDateRange;
    
    public function getIncidentDateRange(): ?DateRange
    {
        return $this->incidentDateRange;
    }
    
    public function setIncidentDateRange(?DateRange $incidentDateRange): self
    {
        $this->incidentDateRange = $incidentDateRange;
        return $this;
    }
    
    // Repeat for: reportDate, resolutionDate, lastUpdatedDate
}
```

---

### Task 2: Repository Filter Methods

**File:** `symfony/src/Incident/WorkflowTableBundle/Repository/IncidentReportRepository.php`

```php
<?php

declare(strict_types=1);

namespace MedTrainer\Incident\WorkflowTableBundle\Repository;

use MedTrainer\SPABundle\Models\FilterValues\DateRange;

class IncidentReportRepository
{
    /**
     * Filter by incident date (when incident occurred)
     */
    public function filterByIncidentDate(DateRange $dateRange): self
    {
        if ($dateRange->isEmpty()) {
            return $this;
        }
        
        $qb = $this->queryBuilder;
        
        // Case 1: Only blanks (NULL values)
        if ($dateRange->onlyBlanks()) {
            $qb->andWhere('incident.dateIncident IS NULL');
            return $this;
        }
        
        // Case 2: Date range
        if ($dateRange->getFrom()) {
            $qb->andWhere('incident.dateIncident >= :incident_date_from')
               ->setParameter('incident_date_from', $dateRange->getFrom());
        }
        
        if ($dateRange->getTo()) {
            $qb->andWhere('incident.dateIncident <= :incident_date_to')
               ->setParameter('incident_date_to', $dateRange->getTo());
        }
        
        // Case 3: Range + blanks (include NULL along with range)
        if ($dateRange->hasBlanks() && !$dateRange->onlyBlanks()) {
            // Wrap previous conditions in OR with NULL check
            $orX = $qb->expr()->orX();
            
            if ($dateRange->getFrom() && $dateRange->getTo()) {
                $orX->add(
                    $qb->expr()->between(
                        'incident.dateIncident',
                        ':incident_date_from',
                        ':incident_date_to'
                    )
                );
            } elseif ($dateRange->getFrom()) {
                $orX->add($qb->expr()->gte('incident.dateIncident', ':incident_date_from'));
            } elseif ($dateRange->getTo()) {
                $orX->add($qb->expr()->lte('incident.dateIncident', ':incident_date_to'));
            }
            
            $orX->add($qb->expr()->isNull('incident.dateIncident'));
            $qb->andWhere($orX);
        }
        
        return $this;
    }
    
    /**
     * Filter by report creation date
     */
    public function filterByReportDate(DateRange $dateRange): self
    {
        // Same pattern as above, use 'incident.dateReport'
        // Note: dateReport is NOT nullable, so blank logic may be unnecessary
        // but kept for consistency with the pattern
    }
    
    /**
     * Filter by resolution date
     */
    public function filterByResolutionDate(DateRange $dateRange): self
    {
        // Same pattern as above, use 'incident.resolutionDate'
    }
    
    /**
     * Filter by last updated date
     */
    public function filterByLastUpdatedDate(DateRange $dateRange): self
    {
        // Same pattern as above, use 'incident.lastUpdatedDate'
        // This field IS nullable, so all blank logic applies
    }
}
```

---

### Task 3: Controller Parameter Parsing

**File:** `symfony/src/Incident/WorkflowTableBundle/Controller/IncidentReportListController.php`

```php
<?php

declare(strict_types=1);

namespace MedTrainer\Incident\WorkflowTableBundle\Controller;

use MedTrainer\SPABundle\Models\FilterValues\DateRange;
use Symfony\Component\HttpFoundation\Request;

class IncidentReportListController
{
    public function __invoke(Request $request): JsonResponse
    {
        // ... other code ...
        
        // Parse incident_date filter
        $incidentDateRange = DateRange::create([
            'from' => $request->query->get('incidentDate')['from'] ?? null,
            'to' => $request->query->get('incidentDate')['to'] ?? null,
            'empty' => $request->query->get('incidentDate')['empty'] ?? null
        ]);
        
        // Parse report_date filter
        $reportDateRange = DateRange::create([
            'from' => $request->query->get('reportDate')['from'] ?? null,
            'to' => $request->query->get('reportDate')['to'] ?? null,
            'empty' => $request->query->get('reportDate')['empty'] ?? null
        ]);
        
        // Parse resolution_date filter
        $resolutionDateRange = DateRange::create([
            'from' => $request->query->get('resolutionDate')['from'] ?? null,
            'to' => $request->query->get('resolutionDate')['to'] ?? null,
            'empty' => $request->query->get('resolutionDate')['empty'] ?? null
        ]);
        
        // Parse last_updated_date filter
        $lastUpdatedDateRange = DateRange::create([
            'from' => $request->query->get('lastUpdatedDate')['from'] ?? null,
            'to' => $request->query->get('lastUpdatedDate')['to'] ?? null,
            'empty' => $request->query->get('lastUpdatedDate')['empty'] ?? null
        ]);
        
        // Set to query object
        $query->setIncidentDateRange($incidentDateRange);
        $query->setReportDateRange($reportDateRange);
        $query->setResolutionDateRange($resolutionDateRange);
        $query->setLastUpdatedDateRange($lastUpdatedDateRange);
        
        // Pass to service...
    }
}
```

---

### Task 4: Service Integration

**File:** `symfony/src/Incident/WorkflowTableBundle/Service/GetIncidentListService.php`

```php
<?php

declare(strict_types=1);

namespace MedTrainer\Incident\WorkflowTableBundle\Service;

class GetIncidentListService
{
    public function __invoke(IncidentListQuery $query): array
    {
        // ... repository setup ...
        
        // Apply date filters
        if ($query->getIncidentDateRange() && !$query->getIncidentDateRange()->isEmpty()) {
            $repository->filterByIncidentDate($query->getIncidentDateRange());
        }
        
        if ($query->getReportDateRange() && !$query->getReportDateRange()->isEmpty()) {
            $repository->filterByReportDate($query->getReportDateRange());
        }
        
        if ($query->getResolutionDateRange() && !$query->getResolutionDateRange()->isEmpty()) {
            $repository->filterByResolutionDate($query->getResolutionDateRange());
        }
        
        if ($query->getLastUpdatedDateRange() && !$query->getLastUpdatedDateRange()->isEmpty()) {
            $repository->filterByLastUpdatedDate($query->getLastUpdatedDateRange());
        }
        
        // ... execute query and return results ...
    }
}
```

---

## Testing

### Unit Tests

**File:** `symfony/tests/Unit/Incident/WorkflowTableBundle/Repository/IncidentReportRepositoryTest.php`

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Incident\WorkflowTableBundle\Repository;

use MedTrainer\SPABundle\Models\FilterValues\DateRange;
use PHPUnit\Framework\TestCase;

class IncidentReportRepositoryTest extends TestCase
{
    public function testFilterByIncidentDateWithCompleteRange(): void
    {
        $dateRange = DateRange::create([
            'from' => '2024-01-01',
            'to' => '2024-12-31',
            'empty' => null
        ]);
        
        $repository = $this->createRepository();
        $result = $repository->filterByIncidentDate($dateRange);
        
        $dql = $result->getQuery()->getDQL();
        $this->assertStringContainsString('incident.dateIncident >=', $dql);
        $this->assertStringContainsString('incident.dateIncident <=', $dql);
    }
    
    public function testFilterByIncidentDateOnlyFrom(): void
    {
        $dateRange = DateRange::create([
            'from' => '2024-01-01',
            'to' => null,
            'empty' => null
        ]);
        
        $repository = $this->createRepository();
        $result = $repository->filterByIncidentDate($dateRange);
        
        $dql = $result->getQuery()->getDQL();
        $this->assertStringContainsString('incident.dateIncident >=', $dql);
        $this->assertStringNotContainsString('<=', $dql);
    }
    
    public function testFilterByIncidentDateOnlyBlanks(): void
    {
        $dateRange = DateRange::create([
            'from' => null,
            'to' => null,
            'empty' => true
        ]);
        
        $repository = $this->createRepository();
        $result = $repository->filterByIncidentDate($dateRange);
        
        $dql = $result->getQuery()->getDQL();
        $this->assertStringContainsString('IS NULL', $dql);
    }
    
    public function testFilterByIncidentDateRangeWithBlanks(): void
    {
        $dateRange = DateRange::create([
            'from' => '2024-01-01',
            'to' => '2024-12-31',
            'empty' => false // This means: include blanks along with range
        ]);
        
        $repository = $this->createRepository();
        $result = $repository->filterByIncidentDate($dateRange);
        
        $dql = $result->getQuery()->getDQL();
        $this->assertStringContainsString('OR', $dql);
        $this->assertStringContainsString('IS NULL', $dql);
    }
    
    // Repeat for: reportDate, resolutionDate, lastUpdatedDate
}
```

### Functional Test

**File:** `symfony/tests/Functional/Incident/WorkflowTableBundle/Controller/IncidentReportListControllerTest.php`

```php
<?php

declare(strict_types=1);

namespace Tests\Functional\Incident\WorkflowTableBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class IncidentReportListControllerTest extends WebTestCase
{
    public function testListEndpointWithDateFilters(): void
    {
        $client = static::createClient();
        
        $client->request('GET', '/incident-reports', [
            'incidentDate' => [
                'from' => '2024-01-01',
                'to' => '2024-12-31'
            ],
            'reportDate' => [
                'from' => '2024-06-01'
            ],
            'resolutionDate' => [
                'empty' => true
            ]
        ]);
        
        $this->assertResponseIsSuccessful();
        
        $response = json_decode($client->getResponse()->getContent(), true);
        
        $this->assertArrayHasKey('rows', $response);
        $this->assertArrayHasKey('meta', $response);
        
        // Verify filtering logic
        foreach ($response['rows'] as $incident) {
            $this->assertGreaterThanOrEqual('2024-01-01', $incident['incidentDate']);
            $this->assertLessThanOrEqual('2024-12-31', $incident['incidentDate']);
            $this->assertNull($incident['resolutionDate']);
        }
    }
}
```

---

## Reference Files

Copy patterns from existing implementations:

1. **DateRange class:** `symfony/src/MedTrainer/SPABundle/Models/FilterValues/DateRange.php`
2. **Query Object pattern:** `symfony/src/MedTrainer/CourseAssignmentsBundle/src/DTO/AssignmentFilters.php` (lines 108-440)
3. **Repository filtering:** `symfony/src/MedTrainer/CourseAssignmentsBundle/src/QueryBuilder/AssignmentQueryBuilder.php` (lines 420-549)
4. **Controller parsing:** `symfony/src/MedTrainer/CourseAssignmentsBundle/src/Service/AssignmentManagement/SetAssignmentFilters.php` (lines 79-117)
5. **Unit tests:** `symfony/tests/Unit/MedTrainer/SPABundle/Models/Filters/DateRangeTest.php`

---

## Estimated Effort

| Task | Time |
|------|------|
| Add properties to Query Object | 30 min |
| Create 4 repository filter methods | 1 hour |
| Parse parameters in Controller | 30 min |
| Integrate in Service | 15 min |
| Update OpenAPI spec | 20 min |
| Write unit tests (16 total) | 2 hours |
| Write functional test | 1 hour |
| **Total** | **~5.5 hours** |

---

## Database Field Mapping Summary

| API Parameter | DB Column | Entity Property | Type | Format |
|---------------|-----------|-----------------|------|--------|
| `incidentDate` | `date_incident` | `$dateIncident` | `date` | `YYYY-MM-DD` |
| `reportDate` | `date_report` | `$dateReport` | `datetime` | `YYYY-MM-DD HH:MM:SS` |
| `resolutionDate` | `resolution_date` | `$resolutionDate` | `datetime` | `YYYY-MM-DD HH:MM:SS` |
| `lastUpdatedDate` | `last_updated_date` | `$lastUpdatedDate` | `datetime` | `YYYY-MM-DD HH:MM:SS` |

**Response Format:** All datetime fields are returned as ISO 8601 strings in UTC timezone (e.g., `2024-01-15T14:30:00Z`).

---

## Notes

- **No `created_at` field:** The entity does not have a `created_at` field. Use `reportDate` (which maps to `date_report`) as the creation timestamp.
- **Nullable handling:** While some fields are marked as NOT NULL in the entity, implement blank/NULL filtering for all 4 fields for consistency and to handle edge cases in production data.
- **CarbonImmutable:** The `DateRange` class uses `CarbonImmutable` internally for immutable date operations.
- **Timezone:** All dates are stored and returned in UTC. The frontend is responsible for timezone conversion if needed.
