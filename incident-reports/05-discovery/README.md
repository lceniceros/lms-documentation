# Discovery Phase Documentation

**Epic:** LSFB-62813 - Incident Reports Workflow Table Revamp  
**Phase:** Discovery & Analysis  
**Status:** Complete

This directory contains all discovery phase documentation including business requirements, technical analysis, and migration strategies.

---

## Directory Structure

### Root Files

- **DOCUMENTATION_PLAN.md** - Overall documentation strategy and organization
- **IncidentTracking_ActionsMatrix_Consolidated.md** - Consolidated actions matrix (primary reference)

### business/

Business requirements and capabilities analysis:

- **business-capabilities.md** - Core business capabilities and requirements
- **matrices/**
  - **IncidentTracking_ActionsMatrix_Analysis.md** - Actions matrix detailed analysis
  - **IncidentTracking_CreatedReportsTab_ActionsMatrix.md** - Created Reports tab specific matrix

### findings/

Discovery findings and analysis documents:

- **incident-module-migration-guide.md** - Migration strategy and guide
- **incident-module-refactoring-strategy.md** - Code refactoring strategy
- **IncidentTracking_ActionsMatrix_Analysis.md** - Actions matrix analysis (findings view)
- **IncidentTracking_ActionsMatrix_ProductView.md** - Product perspective on actions matrix
- **IncidentTracking_ActionsMatrix_Technical.md** - Technical implementation of actions matrix

### technical/

Technical specifications and database design:

- **database-erd.md** - Entity Relationship Diagram and database schema

---

## Key Documents

### 1. Actions Matrix (PRIMARY REFERENCE)

**File:** `IncidentTracking_ActionsMatrix_Consolidated.md`

The definitive source for all action permissions logic:
- canEdit, canDelete, canRestore, canDownload
- Status-based rules
- Matrix membership rules
- Role-based permissions

**Use this document** when implementing permission checks in Phase 4+.

### 2. Business Capabilities

**File:** `business/business-capabilities.md`

Defines the core business requirements:
- User stories
- Acceptance criteria
- Feature requirements
- Performance requirements

### 3. Migration Guide

**File:** `findings/incident-module-migration-guide.md`

Step-by-step migration strategy:
- Legacy to modern architecture
- Database migrations
- Code refactoring steps
- Testing strategy

### 4. Database ERD

**File:** `technical/database-erd.md`

Database schema and relationships:
- Entity definitions
- Field mappings (old → new)
- Indexes required for CTEs
- Foreign key relationships

---

## How to Use This Documentation

### For Developers

1. **Start with:** `IncidentTracking_ActionsMatrix_Consolidated.md` - Understand permission rules
2. **Then read:** `business/business-capabilities.md` - Understand requirements
3. **Reference:** `technical/database-erd.md` - Database structure
4. **Implement using:** `findings/incident-module-migration-guide.md` - Migration steps

### For Product Owners

1. **Primary:** `IncidentTracking_ActionsMatrix_ProductView.md` - Product perspective
2. **Business rules:** `business/business-capabilities.md` - Feature requirements
3. **Strategy:** `findings/incident-module-refactoring-strategy.md` - High-level approach

### For QA

1. **Test scenarios:** `IncidentTracking_ActionsMatrix_Consolidated.md` - All permission combinations
2. **Acceptance criteria:** `business/business-capabilities.md` - What to test
3. **Migration validation:** `findings/incident-module-migration-guide.md` - Migration checkpoints

---

## Document History

| Document | Created | Purpose |
|----------|---------|---------|
| DOCUMENTATION_PLAN.md | 2026-01-27 | Documentation organization strategy |
| IncidentTracking_ActionsMatrix_Consolidated.md | 2026-01-27 | Primary actions matrix reference |
| business-capabilities.md | 2026-01-27 | Business requirements definition |
| incident-module-migration-guide.md | 2026-01-27 | Migration strategy and steps |
| incident-module-refactoring-strategy.md | 2026-01-27 | Refactoring approach |
| database-erd.md | 2026-01-27 | Database schema documentation |
| ActionsMatrix_*.md (5 files) | 2026-01-27 | Various actions matrix views |

---

## Related Documentation

- **Implementation Plan:** `../01-planning/implementation-plan.md` - Master implementation plan
- **Backend Design:** `../01-planning/backend-design.md` - Software design document
- **CTE Implementation:** `../02-technical/cte-implementation-plan.md` - Query optimization
- **OpenAPI Spec:** `../03-api/openapi.yaml` - API specification

---

## Files Summary

**Total:** 11 files, ~236KB

**Categories:**
- Business requirements: 3 files
- Technical findings: 5 files
- Technical specs: 1 file
- Planning: 2 files

---

**Last Updated:** 2026-01-28  
**Phase Status:** Discovery Complete, Implementation In Progress (Phase 4)
