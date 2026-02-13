# Incident Reports v3 - Actions Matrix Analysis

**Date:** 2025-11-13
**Purpose:** Document the rules that control which actions are displayed in the incident reports table based on status and permissions.

---

## Executive Summary (Product View)

This document explains **when users can perform actions** (Download, Delete, Edit, etc.) on incident reports based on the report's current status.

### Quick Reference: Actions by Status

| Status | What Users See |
|--------|----------------|
| **New** | Download, Delete, Edit* |
| **Initiated** | Download, Delete, Edit* |
| **Escalated** | Download, Delete, Edit* |
| **Resolution Rejected** | Download, Delete, Edit* |
| **Waiting Resolution Approval** | Download, Delete only |
| **Resolved** | Download, Delete, Edit** |
| **Deleted** | Download, Restore |

**Notes:**
- `*` Edit requires escalation matrix assignment
- `**` Edit on resolved reports requires special "Edit After Resolution" (IR_EAR) feature enabled
- Anonymous reports cannot be deleted
- Draft reports appear in a separate tab with different actions

---

## Product Rules Explanation

### 1. **Download** - Always Available ✅
Everyone can always download the PDF of any incident report, regardless of status.

### 2. **Delete** (aka "Deprecate") - Available for Active Reports
- **When visible:** All active reports (not already deleted)
- **Exception:** Cannot delete anonymous reports
- **What it does:** Moves the report to the "Deleted reports" tab (soft delete)
- **Who can use it:** Users with appropriate permissions

### 3. **Restore** (aka "Undeprecate") - Only for Deleted Reports
- **When visible:** Only in the "Deleted reports" tab
- **What it does:** Restores the report back to active status
- **Who can use it:** Users with appropriate permissions

### 4. **Edit** - Complex Permission System ⚠️

Edit availability depends on **three factors**: Status, Matrix Assignment, and Feature Settings.

#### Edit is Available for These Statuses:
1. **New** - Report just created
2. **Initiated** - Report has started conversations
3. **Escalated** - Report has been escalated
4. **Resolution Rejected** - Resolution was rejected
5. **Resolved** - ONLY if "Edit After Resolution" (IR_EAR) feature is enabled

#### Edit is NOT Available for:
- **Waiting Resolution Approval** - Cannot edit while waiting for approval
- **Deleted** - Cannot edit deleted reports
- **Draft** - Drafts have different edit mechanisms

#### Who Can Edit (Escalation Matrix Permissions):

The user must be **assigned to the incident through an escalation matrix** AND have the correct permission type:

| Matrix Type | Required Permission | Who Has Access |
|-------------|---------------------|----------------|
| **RACI** | 'R' permission | Users with RACI responsibility |
| **Functional** | 'F' permission | Users in functional roles |
| **Group** | 'G' permission | Users in specific groups |

**Important:** Just being assigned to the matrix is not enough - you need the matching permission type for that matrix.

#### Special Case: Resolved Reports

For **Resolved** reports, editing requires:
1. Company has **IR_EAR (Edit After Resolution)** feature enabled
2. User is assigned to the matrix with appropriate permission
3. The permission must be configured in the IR_EAR extras settings

This is a controlled feature to prevent unwanted modifications to closed incidents.

### 5. **Legacy IRv2 Actions** (Old Reports Only)

Older incident reports created in version 2 have additional actions:

- **Open Discussion** - Available for unresolved reports
- **Close Incident** - Available for unresolved reports
- **Post Closure** - Available for resolved reports
- **Change Follow Up Date** - Available for resolved reports

These actions do NOT apply to new IRv3 reports.

---

## Use Case Scenarios

### Scenario 1: New Incident Report
**Status:** New
**User:** Manager assigned to RACI matrix with 'R' permission
**Actions Available:** Download, Delete, Edit

### Scenario 2: Escalated Incident
**Status:** Escalated
**User:** Team member assigned to Functional matrix with 'F' permission
**Actions Available:** Download, Delete, Edit

### Scenario 3: Waiting for Approval
**Status:** Waiting Resolution Approval
**User:** Any user
**Actions Available:** Download, Delete only (no editing allowed)

### Scenario 4: Resolved Incident (IR_EAR Disabled)
**Status:** Resolved
**User:** Manager with matrix assignment
**Actions Available:** Download, Delete (no editing - feature not enabled)

### Scenario 5: Resolved Incident (IR_EAR Enabled)
**Status:** Resolved
**User:** Manager assigned to matrix with IR_EAR 'R' permission
**Actions Available:** Download, Delete, Edit

### Scenario 6: Anonymous Report
**Status:** Any active status
**User:** Any user
**Actions Available:** Download only (cannot delete anonymous reports)

### Scenario 7: Deleted Report
**Status:** Deleted
**User:** User with restore permissions
**Actions Available:** Download, Restore

---

## Business Rules Summary

### Permission Hierarchy

1. **Download** - Universal permission, everyone can download
2. **Delete/Restore** - Requires incident management permissions
3. **Edit** - Most restrictive, requires:
   - Specific status (see list above)
   - Matrix assignment
   - Correct permission type (R/F/G)
   - Special feature for resolved reports

### Why These Rules Exist

1. **Status-Based Editing**
   - Prevents editing during sensitive phases (e.g., waiting for approval)
   - Maintains incident workflow integrity

2. **Matrix-Based Permissions**
   - Ensures only responsible parties can make changes
   - Follows organizational accountability structure

3. **Anonymous Protection**
   - Protects whistleblower reports from deletion
   - Maintains trust in anonymous reporting system

4. **Resolved Report Protection**
   - Requires special feature to edit closed incidents
   - Prevents accidental modifications to historical records
   - Maintains audit trail integrity

---

## Technical Implementation Details

### Status Code Mapping

| Code | Display Name | Database Value |
|------|--------------|----------------|
| 0 | Draft | IncidentScalableData status |
| 1 | New | IncidentScalableData status |
| I | Initiated | Derived (status 1 + has conversations) |
| 2 | Escalated | IncidentScalableData status |
| 3 | Resolved | IncidentScalableData status |
| 4 | Escalated | Legacy IRv2 status |
| 5 | Resolution Rejected | IncidentScalableData status |
| 6 | Waiting Resolution Approval | IncidentScalableData status |
| D | Deleted | CompanyIncidentScalable status |
| S | Draft | CompanyIncidentScalable status |

**Code References:**
- [Status.php:39-48](../src/Incident/TrackingBundle/Constants/Status.php#L39-L48)
- [IncidentScalableData.php:14-22](../src/PlanetMedia/MedTrainerBundle/Entity/IncidentScalableData.php#L14-L22)

### Action Rendering Logic

**Location:** [incident-table-by-status.js:140-226](../web/js/incident-table-by-status.js#L140-L226)

#### Download Action
```javascript
// Line 153 - Always rendered
let actions = '<a title="Download" href="' + urlFile + '" target="_blank">
    <i class="fa fa-download"></i>
</a>';
```

#### Delete/Undelete Action
```javascript
// Lines 154-160
let deleteAc = createDeleteButton(idIncidentData, statusType);
let undeleteAc = createUndeleteButton(idIncidentData, statusType);

// Exception for anonymous reports
if (statusType === 'published' && parseInt(incident.isAnonymous) === 1) {
    deleteAc = '';
}

// Show delete for published, undelete for deleted
actions = (status === "") ? actions + deleteAc : actions + undeleteAc;
```

#### Edit Action - Rule Set A (New, Escalated, Resolution Rejected)
```javascript
// Lines 162-184
if ((userAllowEditIncident !== '' && userAllowEditIncident !== null)
    && matrixType !== '' && matrixType !== null
    && (statusD === 2 || statusD === 1 || statusD === 5)) {

    let users = incident.matrixUsers;

    if (statusD == 2 || statusD == 1 || statusD == 5) {
        if (userType != 'E') {
            // RACI Matrix
            if ((userAllowEditIncident.indexOf('R') != -1)
                && (matrixType == 1)
                && (users.indexOf(userId) != -1)) {
                editAc = editAcDefault;
            }
            // Functional Matrix
            else if ((userAllowEditIncident.indexOf('F') != -1)
                && (matrixType == 2 || matrixType == 4)
                && (users.indexOf(userId) != -1)) {
                editAc = editAcDefault;
            }
            // Group Matrix
            else if ((userAllowEditIncident.indexOf('G') != -1)
                && (matrixType == 5)
                && (users.indexOf(userId) != -1)) {
                editAc = editAcDefault;
            }
        }
    }
}
```

#### Edit Action - Rule Set B (Resolved with IR_EAR)
```javascript
// Lines 185-203
else if (newSettings.IR_EAR.value == 1) {
    let users = incident.matrixUsers;

    if (incident.statusData == 3) { // Resolved status
        // RACI Matrix
        if ((newSettings.IR_EAR.extras.indexOf('R') != -1)
            && (matrixType == 1)
            && (users.indexOf(userId) != -1)) {
            editAc = editAcDefault;
        }
        // Functional Matrix
        else if ((newSettings.IR_EAR.extras.indexOf('F') != -1)
            && (matrixType == 2 || matrixType == 4)
            && (users.indexOf(userId) != -1)) {
            editAc = editAcDefault;
        }
        // Group Matrix
        else if ((newSettings.IR_EAR.extras.indexOf('G') != -1)
            && (matrixType == 5)
            && (users.indexOf(userId) != -1)) {
            editAc = editAcDefault;
        }
    }
}
```

### Matrix Type Constants

| Type | Description | Permission Flag |
|------|-------------|-----------------|
| 1 | RACI Matrix | 'R' |
| 2 | Functional Matrix | 'F' |
| 4 | Functional Matrix (legacy) | 'F' |
| 5 | Group Matrix | 'G' |

### Configuration Variables

**Frontend Variables** (set in Twig template):
- `userAllowEditIncident` - User's edit permissions string (contains 'R', 'F', or 'G')
- `userType` - User type ('E' for employee, 'S' for admin, etc.)
- `userId` - Current user ID
- `newSettings.IR_EAR.value` - Edit After Resolution feature flag (0/1)
- `newSettings.IR_EAR.extras` - Edit After Resolution permission string

**Template Reference:** [incidentReports.html.twig:344-347](../src/Incident/TrackingBundle/Resources/views/irAdmin/incidentReports.html.twig#L344-L347)

---

## Complete Action Matrix

| Status | Code | Download | Delete | Restore | Edit | Discussion† | Close† | Post Closure† |
|--------|------|----------|--------|---------|------|-------------|--------|---------------|
| Draft | 0 | ✅ | ✅* | ❌ | ❌ | ❌ | ❌ | ❌ |
| New | 1 | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ |
| Initiated | I | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ |
| Escalated | 2 | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ |
| Resolved | 3 | ✅ | ✅* | ❌ | ✅² | ❌ | ❌ | ✅ |
| Resolution Rejected | 5 | ✅ | ✅* | ❌ | ✅¹ | ✅ | ✅ | ❌ |
| Waiting Approval | 6 | ✅ | ✅* | ❌ | ❌ | ✅ | ✅ | ❌ |
| Deleted | D | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |

**Legend:**
- `*` Not available for anonymous reports
- `¹` Requires matrix assignment + matching permission (Rule Set A)
- `²` Requires IR_EAR enabled + matrix assignment + matching permission (Rule Set B)
- `†` Only for legacy IRv2 reports (`typeIr === "Old"`)

---

## Discovery Validation

### Comparison with Initial Discovery Findings

| Discovery Finding | Validation Result | Notes |
|-------------------|-------------------|-------|
| New: Download, Deprecate | ✅ **CONFIRMED** | Plus Edit if matrix permissions |
| Escalated: Download, Deprecate | ✅ **CONFIRMED** | Plus Edit if matrix permissions |
| Waiting for approval: Download, Deprecate | ✅ **CONFIRMED** | Edit is NOT available |
| Resolution rejected: Not clear | ✅ **CLARIFIED** | Download, Delete, Edit (with matrix) |
| Initiated: Not clear | ✅ **CLARIFIED** | Same as "New" status |
| Draft: Edit, Deprecate | ✅ **CONFIRMED** | Appears in separate tab |
| Resolved: Download, Edit, Deprecated | ⚠️ **PARTIALLY CORRECT** | Edit only if IR_EAR enabled |
| Deprecated: Undeprecate, Edit, Download | ❌ **INCORRECT** | No Edit on deleted reports |

### Key Corrections to Discovery

1. **"Deprecate" = "Delete"** - Terminology confirmed
2. **Resolved reports** - Edit requires IR_EAR feature enabled
3. **Deleted reports** - NO edit action available
4. **Resolution Rejected** - Full edit capability with matrix permissions
5. **Initiated status** - Derived status, behaves like "New"

---

## Related Documentation

- [Incident Tracking Best Practices](./best-practices.md)
- [Escalation Matrix Guide](./INCIDENT_MATRICES_GUIDE.md)
- [Frontend Development Patterns](./frontend/README.md)

---

## Change History

| Date | Author | Changes |
|------|--------|---------|
| 2025-11-13 | Claude Code | Initial analysis and documentation |

---

**Document Status:** ✅ Complete
**Last Updated:** 2025-11-13
**Maintained By:** Engineering Team
