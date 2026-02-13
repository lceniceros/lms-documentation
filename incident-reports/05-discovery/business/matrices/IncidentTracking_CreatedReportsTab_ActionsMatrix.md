---
applyTo: '**'
---

# Incident Tracking: Created Reports Tab — Actions & Permissions Matrix

## Overview
This document summarizes the business logic, display, and action permissions for the main incident list table ("Created Reports" tab) in the Incident Tracking system. It details the real-world options shown in the Actions column, the conditions for their visibility, and a matrix mapping actions to user roles.

---

## Actions Column: Real-World Options

| Action                  | Icon                | When/Who Can See It                                                                                   |
|-------------------------|---------------------|-------------------------------------------------------------------------------------------------------|
| Download                | fa-download         | Always (if file exists)                                                                               |
| Delete                  | fa-trash            | Published, not anonymous                                                                              |
| Undelete                | fa-undo             | Deleted                                                                                               |
| Edit                    | fa-pencil-square-o  | User with edit permission, incident has matrix, status is New/Escalated/Waiting Approval, user in matrix |
| Discussion (Comments)   | fa-comments-o       | "Old" type, not resolved, user has a role                                                             |
| Close Incident          | fa-floppy-o         | "Old" type, not resolved                                                                              |
| Post Closure            | fa-envelope         | "Old" type, resolved                                                                                  |
| Change Follow Up Date   | fa-calendar         | "Old" type, resolved                                                                                  |

---

## User Roles
- **Admin** (`userType = 'A'`)
- **Manager** (`userType = 'M'`)
- **Employee** (`userType = 'E'`)
- **Matrix Member** (RACI, Functional, Group — via escalation matrix)

Permissions are further refined by:
- `userAllowEditIncident` (allowed matrix types)
- Membership in the incident’s escalation matrix (`matrixUsers`)
- Incident status (`statusData`)
- Incident type (`typeIr`)

---

## Matrix of Actions by Role

| Action                  | Admin (A) | Manager (M) | Employee (E) | Matrix Member (R/F/G) | Not in Matrix | Notes/Conditions                                                                                   |
|-------------------------|:---------:|:-----------:|:------------:|:---------------------:|:-------------:|---------------------------------------------------------------------------------------------------|
| **Download**            | ✅        | ✅          | ✅           | ✅                   | ✅            | Always available if file exists                                                                   |
| **Delete**              | ✅        | ✅          | ✅           | ✅                   | ✅            | Published, not anonymous                                                                          |
| **Undelete**            | ✅        | ✅          | ✅           | ✅                   | ✅            | Deleted                                                                                           |
| **Edit**                | ✅        | ✅          | ❌           | ✅                   | ❌            | Only if user is in matrix, has edit permission, and status is New/Escalated/Waiting Approval      |
| **Discussion (Comments)**| ✅        | ✅          | ✅           | ✅                   | ✅            | "Old" type, not resolved, user has a role                                                         |
| **Close Incident**      | ✅        | ✅          | ✅           | ✅                   | ✅            | "Old" type, not resolved                                                                          |
| **Post Closure**        | ✅        | ✅          | ✅           | ✅                   | ✅            | "Old" type, resolved                                                                              |
| **Change Follow Up Date**| ✅        | ✅          | ✅           | ✅                   | ✅            | "Old" type, resolved                                                                              |

---

## Key Logic Details
- **Edit** is strictly limited by matrix membership and `userAllowEditIncident`.
- Other actions are available to all roles if the incident’s status/type matches the action’s requirements.
- Employee users generally cannot edit unless they are matrix members with the correct permissions.

---

## Example Scenarios
- **Admin viewing a New incident:**
  - Can Download, Delete, Edit (if in matrix), Discussion, Close
- **Manager viewing a Resolved "Old" incident:**
  - Can Download, Undelete (if deleted), Post Closure, Change Follow Up Date
- **Employee not in matrix:**
  - Can Download, Delete, Discussion, Close, but **cannot Edit**
- **Matrix Member (RACI, Functional, Group):**
  - Can Edit if their matrix type matches and status is New/Escalated/Waiting Approval

---

## Notes
- No "Escalate" or "Resolve" actions are present in the main list table Actions column.
- The actual set of actions for each incident row is dynamically built based on incident status, type, user permissions, and company configuration.
- Some actions (Edit, Discussion, Close, Post Closure, Change Follow Up Date) are only available for specific incident types ("Old") and statuses.

---

## References
- JS: `incident-table-by-status.js`
- Controller: `TrackingActionsController.php`
- Template: `incidentReports.html.twig`

---

This document provides a complete, actionable reference for the Actions column in the "Created Reports" tab of the Incident Tracking system.
