# Incident Reports v3 - Actions Matrix (Product Guide)

**Date:** 2025-11-13
**Audience:** Product Managers, Business Analysts, QA, Support Teams
**Purpose:** Understand when users can perform actions on incident reports

---

## Quick Reference: Actions by Status

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

## Understanding Each Action

### 1. Download - Always Available ✅

**What it does:** Downloads the incident report as a PDF file

**When it's visible:** Always, for all reports regardless of status

**Who can use it:** All users with access to view the incident report

**Why this rule:** Transparency - users should always be able to access report documentation

---

### 2. Delete (aka "Deprecate") - For Active Reports

**What it does:** Soft deletes the report (moves it to "Deleted reports" tab)

**When it's visible:**
- All active reports (not already deleted)
- ❌ **Exception:** NOT visible for anonymous reports

**Who can use it:** Users with incident management permissions

**Why this rule:**
- Allows cleanup of incorrect or duplicate reports
- Anonymous reports are protected to maintain whistleblower trust
- Soft delete preserves data for audit purposes

---

### 3. Restore (aka "Undeprecate") - For Deleted Reports Only

**What it does:** Restores a deleted report back to active status

**When it's visible:** Only in the "Deleted reports" tab

**Who can use it:** Users with incident management permissions

**Why this rule:** Allows recovery from accidental deletions

---

### 4. Edit - Complex Permission System ⚠️

**What it does:** Allows modification of incident report details

#### When Edit is Available

Edit appears based on **three factors**:

##### Factor 1: Report Status
Edit is available for:
- ✅ **New** - Report just created
- ✅ **Initiated** - Report has started conversations
- ✅ **Escalated** - Report has been escalated
- ✅ **Resolution Rejected** - Resolution was rejected
- ✅ **Resolved** - ONLY if "Edit After Resolution" feature is enabled

Edit is NOT available for:
- ❌ **Waiting Resolution Approval** - Locked during approval process
- ❌ **Deleted** - Cannot edit deleted reports
- ❌ **Draft** - Drafts use a different edit mechanism

##### Factor 2: Matrix Assignment

The user must be **assigned to the incident through an escalation matrix**. There are three types of matrices:

| Matrix Type | Required Permission | Typical Users |
|-------------|---------------------|---------------|
| **RACI** | 'R' permission | Responsible parties, accountable owners |
| **Functional** | 'F' permission | Department heads, functional managers |
| **Group** | 'G' permission | Specific workgroups or teams |

**Important:** Being assigned to the matrix is not enough - you need the **matching permission type** for that specific matrix.

##### Factor 3: Feature Settings (for Resolved Reports)

For **Resolved** reports, editing requires:
1. ✅ Company has **IR_EAR (Edit After Resolution)** feature enabled
2. ✅ User is assigned to the matrix
3. ✅ User's permission is configured in IR_EAR extras settings

**Why this rule:** Resolved incidents represent closed cases. Allowing edits requires special approval to maintain audit trail integrity and prevent unwanted modifications to historical records.

---

### 5. Legacy IRv2 Actions (Old Reports Only)

Older incident reports created in version 2 have additional actions that do NOT apply to new IRv3 reports:

| Action | When Visible | What It Does |
|--------|--------------|--------------|
| **Open Discussion** | Unresolved reports | Opens conversation thread |
| **Close Incident** | Unresolved reports | Marks incident as resolved |
| **Post Closure** | Resolved reports | Access post-closure documentation |
| **Change Follow Up Date** | Resolved reports | Updates follow-up date |

---

## Real-World Scenarios

### Scenario 1: New Incident Report
**Situation:** Safety manager creates a new incident report
**Status:** New
**User Role:** Manager assigned to RACI matrix with 'R' permission
**Actions Available:** Download, Delete, Edit
**Explanation:** Full control since report is fresh and user has responsibility

---

### Scenario 2: Escalated Incident
**Situation:** Incident escalated to department head
**Status:** Escalated
**User Role:** Department head assigned to Functional matrix with 'F' permission
**Actions Available:** Download, Delete, Edit
**Explanation:** Functional manager can edit to add department-specific details

---

### Scenario 3: Waiting for Management Approval
**Situation:** Incident resolution submitted for approval
**Status:** Waiting Resolution Approval
**User Role:** Any user
**Actions Available:** Download, Delete only
**Explanation:** Edit is locked during approval to prevent changes while decision pending

---

### Scenario 4: Resolved Incident (Standard Configuration)
**Situation:** Incident is closed
**Status:** Resolved
**Company Setting:** IR_EAR feature is **disabled** (default)
**User Role:** Manager with matrix assignment
**Actions Available:** Download, Delete
**Explanation:** No editing allowed - closed incidents are locked by default

---

### Scenario 5: Resolved Incident (IR_EAR Enabled)
**Situation:** Company needs to correct resolved incident documentation
**Status:** Resolved
**Company Setting:** IR_EAR feature is **enabled**
**User Role:** Manager assigned to matrix with IR_EAR 'R' permission
**Actions Available:** Download, Delete, Edit
**Explanation:** Special feature allows corrections to closed incidents for compliance

---

### Scenario 6: Anonymous Report Protection
**Situation:** Employee submits anonymous safety concern
**Status:** Any active status
**User Role:** Any user
**Actions Available:** Download only (NO delete)
**Explanation:** Anonymous reports cannot be deleted to protect whistleblower identity and maintain trust in anonymous reporting system

---

### Scenario 7: Accidental Deletion Recovery
**Situation:** User accidentally deleted an important report
**Status:** Deleted
**User Role:** Manager with restore permissions
**Actions Available:** Download, Restore
**Explanation:** Soft delete allows recovery - report can be restored to active status

---

## Business Rules Summary

### Permission Hierarchy

From least to most restrictive:

1. **Download** 🟢
   - Universal access
   - No special permissions needed
   - Always available

2. **Delete/Restore** 🟡
   - Requires incident management permissions
   - Protected for anonymous reports
   - Soft delete preserves data

3. **Edit** 🔴
   - Most restrictive action
   - Requires specific status
   - Requires matrix assignment
   - Requires matching permission type
   - Special feature needed for resolved reports

---

## Why These Rules Exist

### 1. Status-Based Editing
**Purpose:** Maintain workflow integrity

**Example:** Preventing edits during "Waiting Resolution Approval" ensures the approval decision is based on the submitted information, not modified data.

### 2. Matrix-Based Permissions
**Purpose:** Ensure organizational accountability

**Example:** Only users assigned through escalation matrices can edit - this follows the organization's responsibility structure (RACI, Functional, or Group-based).

### 3. Anonymous Report Protection
**Purpose:** Protect whistleblowers

**Example:** Preventing deletion of anonymous reports maintains trust in the anonymous reporting system and protects employee identities.

### 4. Resolved Report Protection (IR_EAR Feature)
**Purpose:** Maintain historical accuracy

**Example:** Requiring a special feature to edit resolved incidents prevents accidental modifications to closed cases while still allowing legitimate corrections when needed.

---

## Frequently Asked Questions

### Q: Why can't I edit an incident that's waiting for approval?
**A:** The system locks editing during the approval phase to ensure the approver reviews exactly what was submitted, without changes occurring mid-review.

### Q: I'm assigned to the matrix but don't see the Edit button. Why?
**A:** Check these three things:
1. Is the incident status editable? (Not "Waiting Approval" or "Deleted")
2. Does your permission type match the matrix type? (R for RACI, F for Functional, G for Group)
3. If resolved, is the IR_EAR feature enabled?

### Q: Can I delete an anonymous report?
**A:** No. Anonymous reports cannot be deleted to protect the reporter's identity and maintain trust in the anonymous reporting system.

### Q: What's the difference between "New" and "Initiated" status?
**A:** "Initiated" is a derived status - it's a "New" incident that has conversation threads started. The available actions are the same.

### Q: Why do some old reports have extra buttons?
**A:** Reports created in Incident Reporting v2 (legacy system) have additional actions like "Open Discussion" and "Close Incident" that don't apply to new IRv3 reports.

### Q: What does "Edit After Resolution" (IR_EAR) mean?
**A:** It's a company-level feature that allows editing of resolved (closed) incidents. When disabled (default), resolved incidents are locked. When enabled, authorized users can make corrections to closed incidents.

### Q: If I delete a report, is it gone forever?
**A:** No. Delete is a "soft delete" - the report moves to the "Deleted reports" tab and can be restored using the Restore action.

---

## Status Reference

| Status Name | What It Means | Typical Next Steps |
|-------------|---------------|-------------------|
| **New** | Just created, no action taken | Investigate, escalate, or resolve |
| **Initiated** | Conversations started | Continue investigation |
| **Escalated** | Sent to higher authority | Await response from escalated party |
| **Resolution Rejected** | Proposed resolution denied | Revise resolution approach |
| **Waiting Resolution Approval** | Awaiting management sign-off | Management reviews and approves/rejects |
| **Resolved** | Incident closed | Archive, post-closure activities |
| **Deleted** | Soft deleted | Can be restored if needed |

---

## Discovery Validation Results

Based on product team's initial discovery, here are the clarifications:

| Discovery Finding | Actual Behavior | Notes |
|-------------------|-----------------|-------|
| New: Download, Deprecate | ✅ **Correct** | Plus Edit if user has matrix permissions |
| Escalated: Download, Deprecate | ✅ **Correct** | Plus Edit if user has matrix permissions |
| Waiting for approval: Download, Deprecate | ✅ **Correct** | Edit is intentionally blocked |
| Resolution rejected: Not clear | ✅ **Clarified** | Download, Delete, Edit (with matrix) |
| Initiated: Not clear | ✅ **Clarified** | Same actions as "New" status |
| Draft: Edit, Deprecate | ✅ **Correct** | Drafts in separate tab |
| Resolved: Download, Edit, Deprecated | ⚠️ **Partially Correct** | Edit only if IR_EAR enabled |
| Deprecated: Undeprecate, Edit, Download | ❌ **Incorrect** | NO Edit on deleted reports |

### Key Corrections:
1. **Terminology:** "Deprecate" = "Delete" in the code
2. **Resolved Reports:** Edit requires IR_EAR feature to be enabled
3. **Deleted Reports:** Cannot be edited, only restored
4. **Resolution Rejected:** Has full edit capability (with matrix permissions)

---

## Related Documentation

- [Incident Matrices Guide](./INCIDENT_MATRICES_GUIDE.md) - Understanding escalation matrices
- [Technical Implementation Details](./IncidentTracking_ActionsMatrix_Technical.md) - For developers

---

**Document Status:** ✅ Complete
**Last Updated:** 2025-11-13
**For Technical Details See:** [IncidentTracking_ActionsMatrix_Technical.md](./IncidentTracking_ActionsMatrix_Technical.md)
**Maintained By:** Product Team
