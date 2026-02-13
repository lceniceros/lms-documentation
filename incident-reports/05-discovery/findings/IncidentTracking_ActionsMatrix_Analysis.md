# Incident Reports v3 - Actions Matrix Analysis

**Date:** 2025-11-13
**Status:** Documentation split into separate files for different audiences

---

## Documentation Structure

This analysis has been split into two separate documents for better readability:

### 📋 [Product View - IncidentTracking_ActionsMatrix_ProductView.md](./IncidentTracking_ActionsMatrix_ProductView.md)

**Audience:** Product Managers, Business Analysts, QA, Support Teams

**Contents:**
- Quick reference tables
- Plain-language explanations
- Real-world use case scenarios
- Business rules and rationale
- FAQs for non-technical users
- Discovery validation results

👉 **[Read the Product View Documentation](./IncidentTracking_ActionsMatrix_ProductView.md)**

---

### 🔧 [Technical View - IncidentTracking_ActionsMatrix_Technical.md](./IncidentTracking_ActionsMatrix_Technical.md)

**Audience:** Software Engineers, DevOps, Technical Leads

**Contents:**
- Status code mappings with constants
- Complete code implementation details
- Database schema reference
- Configuration variables
- SQL queries and optimization tips
- Testing and debugging guides
- Performance considerations

👉 **[Read the Technical Documentation](./IncidentTracking_ActionsMatrix_Technical.md)**

---

## Quick Summary

### Actions Available by Status

| Status | Download | Delete | Restore | Edit |
|--------|----------|--------|---------|------|
| New | ✅ | ✅ | ❌ | ✅* |
| Initiated | ✅ | ✅ | ❌ | ✅* |
| Escalated | ✅ | ✅ | ❌ | ✅* |
| Resolution Rejected | ✅ | ✅ | ❌ | ✅* |
| Waiting Resolution Approval | ✅ | ✅ | ❌ | ❌ |
| Resolved | ✅ | ✅ | ❌ | ✅** |
| Deleted | ✅ | ❌ | ✅ | ❌ |

**Legend:**
- `*` Edit requires escalation matrix assignment with matching permission
- `**` Edit requires IR_EAR (Edit After Resolution) feature enabled
- Anonymous reports cannot be deleted

---

## Key Findings

1. **Download** - Always available for all reports
2. **Delete** - Available for active reports (except anonymous)
3. **Restore** - Only for deleted reports
4. **Edit** - Complex rules based on status, matrix assignment, and permissions
5. **Waiting Resolution Approval** - Intentionally blocks editing
6. **Resolved Reports** - Require special IR_EAR feature to be editable
7. **Anonymous Reports** - Protected from deletion

---

## Discovery Validation

✅ **New:** Download, Delete, Edit (confirmed)
✅ **Escalated:** Download, Delete, Edit (confirmed)
✅ **Waiting Approval:** Download, Delete only (confirmed - no edit)
✅ **Resolution Rejected:** Download, Delete, Edit (clarified)
✅ **Initiated:** Same as New (clarified)
⚠️ **Resolved:** Edit only if IR_EAR enabled (corrected)
❌ **Deleted:** No Edit available (corrected)

---

## For More Details

- **Product Teams:** See [Product View Documentation](./IncidentTracking_ActionsMatrix_ProductView.md)
- **Engineering Teams:** See [Technical Documentation](./IncidentTracking_ActionsMatrix_Technical.md)
- **Escalation Matrices:** See [Incident Matrices Guide](./INCIDENT_MATRICES_GUIDE.md)

---

**Last Updated:** 2025-11-13
**Maintained By:** Product & Engineering Teams
