# Documentation Plan - Incident Module

**Objective:** Produce comprehensive documentation for the `symfony/src/Incident/` module to understand its current behavior ahead of the revamp.

**Date:** November 2025  
**Status:** Planning

---

## 📊 Module Structure (Initial Analysis)

- **3 main bundles:** ConfigurationBundle, CreationBundle, TrackingBundle
- **~95 PHP files**
- **23+ Entities**
- **24+ Services**
- **9+ Repositories**
- **12+ Controllers**
- **Utilities, Commands, Voters, Constants**

---

## 🎯 LEVEL 1: STRATEGIC AND BUSINESS VIEW

### 1.1 System Context Diagram (C4 Level 1)
**Goal:** Position Incident module within MedTrainer ecosystem

**Content:**
- External actors (users, roles, systems)
- Information flow to/from other modules
- External integrations (email, storage, etc.)

**Format:** C4 Context diagram with Mermaid  
**File:** `docs/architecture/01-context-diagram.md`

---

### 1.2 Business Capabilities Map
**Goal:** Module functionality from a business perspective

**Content:**
- Incident types configuration
- Incident creation and reporting
- Tracking and escalation
- Severity management
- Notifications and roles (RACI)

**Format:** Hierarchical markdown list  
**File:** `docs/business/business-capabilities.md`

---

### 1.3 Stakeholders and Roles Matrix
**Goal:** System actors and their permissions

**Content:**
- User roles (admin, reviewer, reporter, etc.)
- Permissions by role
- Approval flows

**Format:** Markdown table  
**File:** `docs/business/roles-permissions-matrix.md`

---

## 🗺️ LEVEL 2: ARCHITECTURE AND FLOWS

### 2.1 Components Diagram (C4 Level 2)
**Goal:** The 3 bundles and their responsibilities

**Content:**
- **ConfigurationBundle:** Forms setup, types, severity levels
- **CreationBundle:** Incident report generation
- **TrackingBundle:** States management, escalation, notifications

**Format:** C4 Container diagram with Mermaid  
**File:** `docs/architecture/02-components-diagram.md`

---

### 2.2 Process Flow Diagrams
**Goal:** Main business flows

**Content:**
- Initial configuration flow
- Report creation flow
- Escalation flow (RACI matrix)
- Incident closure flow
- Notifications flow

**Format:** Mermaid flowcharts/sequence diagrams  
**Files:** `docs/flows/*.md` (one file per flow)

---

### 2.3 Incident State Diagram
**Goal:** Incident states and transitions

**Content:**
- States: Draft → Submitted → In Review → Escalated → Resolved → Closed
- Events triggering transitions
- State validations

**Format:** Mermaid state machine diagram  
**File:** `docs/flows/incident-state-machine.md`

---

### 2.4 Bundle Dependencies Map
**Goal:** Communication across bundles

**Content:**
- Shared services among bundles
- Shared entities
- DTOs or contracts

**Format:** Mermaid dependencies diagram  
**File:** `docs/architecture/03-bundle-dependencies.md`

---

## 🏗️ LEVEL 3: TECHNICAL DESIGN

### 3.1 Complete Data Model (ERD)
**Goal:** All entities and relationships

**Content:**
- 23+ identified entities
- Relationships (OneToMany, ManyToOne, ManyToMany)
- Critical fields and constraints
- Relevant indexes

**Format:** Mermaid/PlantUML ERD  
**File:** `docs/technical/database-erd.md`

---

### 3.2 Services Catalog
**Goal:** Complete inventory of services

**Per-service content:**
- Single responsibility
- Input/output parameters
- Injected dependencies
- Use cases

**Format:** Extended markdown table  
**File:** `docs/technical/services-catalog.md`

---

### 3.3 Sequence Diagrams per Use Case
**Goal:** Technical interactions between components

**Content:**
- Sequence: "User creates an incident report"
- Sequence: "System escalates incident"
- Sequence: "Admin configures custom types"

**Format:** Mermaid sequence diagrams  
**Files:** `docs/sequences/*.md`

---

### 3.4 Endpoints Matrix (API Surface)
**Goal:** All HTTP endpoints of the module

**Content:**
- Routes (routing.yml, routing_ajax.yml)
- Controller + Action
- HTTP method, parameters, response
- Allowed roles

**Format:** Markdown table  
**File:** `docs/technical/api-endpoints.md`

---

## 🔬 LEVEL 4: DETAILED IMPLEMENTATION

### 4.1 Entities Documentation
**Goal:** Detailed specification per entity

**Per-entity content:**
- Purpose
- Fields and types
- Validations
- Relationships
- Indexes and constraints

**Format:** Markdown per entity  
**Directory:** `docs/entities/`

---

### 4.2 Services Documentation
**Goal:** Detailed specification per service

**Per-service content:**
- Responsibility
- Algorithm/business logic
- Fail-fast validations
- Exceptions
- Side-effects (emails, logs)

**Format:** Markdown per service  
**Directory:** `docs/services/`

---

### 4.3 Documented Business Rules
**Goal:** Rules extracted from code

**Examples:**
- "An incident can only be escalated when in 'In Review' state"
- "RACI matrix defines Responsible, Accountable, Consulted, Informed"
- "Severity levels are company-configurable"

**Format:** List with code references (file:line)  
**File:** `docs/business/business-rules.md`

---

### 4.4 Constants and Enums Catalog
**Goal:** All module constants

**Content:**
- `Status.php`, `Roles.php`, `IrEscalationReportStatus.php`
- Allowed values
- Usage locations

**Format:** Markdown table  
**File:** `docs/technical/constants-catalog.md`

---

### 4.5 Technical Debt Analysis
**Goal:** Identified issues in code

**Content:**
- Oversized classes
- Duplicate logic
- Missing tests
- Util vs Services usage
- Pattern violations
- N+1 queries

**Format:** Prioritized issues list  
**File:** `docs/analysis/technical-debt.md`

---

### 4.6 Test Coverage Map
**Goal:** Current testing status

**Content:**
- Existing unit tests
- Existing functional tests
- Coverage % per class
- Critical cases without tests

**Format:** Markdown table  
**File:** `docs/analysis/test-coverage.md`

---

## 🔍 LEVEL 5: DEEP ANALYSIS

### 5.1 Queries and Performance Analysis
**Goal:** Complex SQL queries

**Content:**
- Repository queries
- Complex joins
- Detected N+1 issues
- Recommended indexes

**Format:** Markdown with SQL examples  
**File:** `docs/analysis/database-queries.md`

---

### 5.2 Events and Messaging Map
**Goal:** Symfony events or async messaging

**Content:**
- Triggered events
- Listeners/Subscribers
- Messenger messages
- Handlers

**Format:** Mermaid event diagram  
**File:** `docs/technical/events-messaging.md`

---

### 5.3 Security and Permissions Analysis
**Goal:** Module access control

**Content:**
- Voters (IncidentVoter.php)
- Symfony roles
- ACLs or custom logic
- Validations in services

**Format:** Permissions matrix + code references  
**File:** `docs/analysis/security-permissions.md`

---

### 5.4 Utils Documentation (Legacy)
**Goal:** Analysis of current Util classes

**Content:**
- `CompanyIncidentUtil`, `CustomIncidentReportUtil`, `PDFUtil`
- Mixed responsibilities
- Migration plan to Services

**Format:** Analysis table  
**File:** `docs/analysis/utils-legacy.md`

---

### 5.5 Domain Glossary
**Goal:** Module vocabulary

**Content:**
- Incident Report
- Escalation Matrix
- RACI Matrix
- Severity Level
- Witnesses, Injured, Person Involved
- Company Incident Type

**Format:** Alphabetical glossary  
**File:** `docs/GLOSSARY.md`

---

### 5.6 Legacy vs Modern Code Tracking
**Goal:** Historical evolution

**Content:**
- Pre-refactor code
- Post-refactor code
- Inconsistent patterns

**Format:** Comparative table  
**File:** `docs/analysis/legacy-vs-modern.md`

---

## 📦 LEVEL 6: OPERATIONAL ARTIFACTS

### 6.1 Troubleshooting Guide
**Goal:** Common issues and solutions

**Content:**
- "Incidents do not escalate correctly"
- "Notifications do not arrive"
- "Errors generating PDF"

**Format:** FAQ-style markdown  
**File:** `docs/operations/troubleshooting.md`

---

### 6.2 Documented CLI Commands
**Goal:** Module commands

**Content:**
- `SetCompaniesDefaultSeverityLevelsCommand`
- `PopulateNewSeverityLevelIdCommand`
- `IncidentReportDepartmentFixerCommand`

**Format:** Markdown with examples  
**File:** `docs/operations/cli-commands.md`

---

### 6.3 Configuration Guide
**Goal:** Module configuration

**Content:**
- services.yml, config.yml, routing
- Registered services
- Configurable parameters

**Format:** Explanatory markdown  
**File:** `docs/operations/configuration.md`

---

## 🎨 TECHNICAL TOOLS

| Type | Tool | Use |
|------|------|-----|
| UML/C4 Diagrams | **Mermaid.js** | Components, sequence, states |
| ERD Diagrams | **Mermaid/PlantUML** | Data model |
| Documentation | **Markdown** | Text documentation |
| Static Analysis | **PHPStan/Psalm** | Detect issues |
| Coverage | **PHPUnit --coverage** | Tests |
| Metrics | **PhpMetrics** | Complexity, coupling |
| Git History | **git log** | Evolution |

---

## 📅 EXECUTION ROADMAP

### **Phase 1: General Understanding** (Days 1-2)
- [X] 1.2 Business Capabilities Map
- [X] 1.1 Context Diagram
- [X] 2.1 Components Diagram
- [X] 5.5 Glossary of Terms

### **Phase 2: Architecture and Flows** (Days 3-5)
- [ ] 2.2 Process Flow Diagrams
- [ ] 2.3 State Diagram
- [ ] 2.4 Dependencies Map
- [ ] 3.1 Data Model (ERD)

### **Phase 3: Technical Inventory** (Days 6-8)
- [ ] 3.2 Services Catalog
- [ ] 3.4 Endpoints Matrix
- [ ] 4.4 Constants Catalog
- [ ] 6.2 CLI Commands Docs

### **Phase 4: Implementation Details** (Days 9-12)
- [ ] 4.1 Entities Documentation
- [ ] 4.2 Services Documentation
- [ ] 4.3 Business Rules
- [ ] 3.3 Sequence Diagrams

### **Phase 5: Analysis and Improvements** (Days 13-15)
- [ ] 4.5 Technical Debt Analysis
- [ ] 4.6 Test Coverage Map
- [ ] 5.1 Queries Analysis
- [ ] 5.3 Security Analysis

---

## 📁 PROPOSED FOLDER STRUCTURE

```
symfony/src/Incident/
├── docs/
│   ├── README.md                          # Main index
│   ├── GLOSSARY.md                        # Glossary
│   ├── architecture/
│   │   ├── 01-context-diagram.md
│   │   ├── 02-components-diagram.md
│   │   └── 03-bundle-dependencies.md
│   ├── business/
│   │   ├── business-capabilities.md
│   │   ├── business-rules.md
│   │   └── roles-permissions-matrix.md
│   ├── technical/
│   │   ├── database-erd.md
│   │   ├── services-catalog.md
│   │   ├── api-endpoints.md
│   │   ├── constants-catalog.md
│   │   └── events-messaging.md
│   ├── flows/
│   │   ├── incident-state-machine.md
│   │   ├── configuration-flow.md
│   │   ├── creation-flow.md
│   │   ├── escalation-flow.md
│   │   └── closure-flow.md
│   ├── sequences/
│   │   ├── create-incident-report.md
│   │   ├── escalate-incident.md
│   │   └── configure-types.md
│   ├── entities/
│   │   ├── CompanyIncident.md
│   │   ├── IncidentReport.md
│   │   └── [... other entities]
│   ├── services/
│   │   ├── CreateSeverityLevelService.md
│   │   ├── GenerateIncidentReport.md
│   │   └── [... other services]
│   ├── analysis/
│   │   ├── technical-debt.md
│   │   ├── test-coverage.md
│   │   ├── database-queries.md
│   │   ├── security-permissions.md
│   │   ├── utils-legacy.md
│   │   └── legacy-vs-modern.md
│   └── operations/
│       ├── troubleshooting.md
│       ├── cli-commands.md
│       └── configuration.md
├── ConfigurationBundle/
├── CreationBundle/
└── TrackingBundle/
```

---

## 🎯 EXPECTED OUTCOME

Upon completion of this plan:

✅ **Strategic documentation** for non-technical stakeholders  
✅ **Visual architecture** for new developers  
✅ **Technical specifications** for refactor  
✅ **Complete module inventory**  
✅ **Prioritized technical debt analysis**  
✅ **Evidence-based improvement roadmap**

---

## 📝 NOTES

- Generate all diagrams using **Mermaid** to keep them as code
- Always reference source code using `file.php:line`
- Keep documents up to date during the refactor
- Use consistent templates for entities and services

---

**Next steps:** Start Phase 1 - General Understanding
