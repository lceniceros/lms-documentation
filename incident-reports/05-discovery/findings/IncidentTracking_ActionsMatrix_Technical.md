# Incident Reports v3 - Actions Matrix (Technical Documentation)

**Date:** 2025-11-13
**Audience:** Software Engineers, DevOps, Technical Leads
**Purpose:** Technical implementation details for incident report action display rules

---

## Architecture Overview

The action display logic is implemented client-side in JavaScript using DataTables rendering functions. Actions are determined dynamically based on:

1. **Incident Status** (database field `IncidentScalableData.status`)
2. **Company Status** (database field `CompanyIncidentScalable.status`)
3. **User Permissions** (escalation matrix assignments)
4. **Feature Flags** (company settings: `IR_EAR`)

---

## Status Code Mapping

### IncidentScalableData Status Codes

| Code | Constant | Display Name | Description |
|------|----------|--------------|-------------|
| `-5` | `INCIDENT_SCALABLE_DATA_STATUS_PREVIEW` | Preview | Preview mode (filtered out) |
| `0` | `INCIDENT_SCALABLE_DATA_STATUS_DRAFT` | Draft | Incident in draft state |
| `1` | `INCIDENT_SCALABLE_DATA_STATUS_NEW` | New | Newly created incident |
| `I` | `INCIDENT_SCALABLE_DATA_STATUS_INITIATED` | Initiated | Derived status (1 + conversations) |
| `2` | `INCIDENT_SCALABLE_DATA_STATUS_ESCALATED` | Escalated | Incident escalated |
| `3` | `INCIDENT_SCALABLE_DATA_STATUS_RESOLVED` | Resolved | Incident resolved |
| `4` | `INCIDENT_SCALABLE_DATA_STATUS_ESCALATED_V2` | Escalated | Legacy IRv2 |
| `5` | `INCIDENT_SCALABLE_DATA_STATUS_RESOLUTION_REJECTED` | Resolution Rejected | Resolution denied |
| `6` | `INCIDENT_SCALABLE_DATA_STATUS_WAITING_RESOLUTION_APROVAL` | Waiting Resolution Approval | Awaiting approval |

**Code Reference:** [IncidentScalableData.php:14-22](../src/PlanetMedia/MedTrainerBundle/Entity/IncidentScalableData.php#L14-L22)

### CompanyIncidentScalable Status Codes

| Code | Constant | Display Name | Description |
|------|----------|--------------|-------------|
| `D` | `COMPANY_INCIDENT_SCALABLE_STATUS_DELETED` | Deleted | Soft deleted |
| `S` | `COMPANY_INCIDENT_SCALABLE_STATUS_DRAFT` | Draft | Draft state |
| `-1` | `DELETED_DRAFT` | Deleted Draft | Draft deletion |

**Code Reference:** [Status.php:39-53](../src/Incident/TrackingBundle/Constants/Status.php#L39-L53)

### Status Label Rendering Function

**Location:** [incident_report_nv.js:1-26](../web/js/incident_report_nv.js#L1-L26)

```javascript
function getLabelStatus(statusD) {
    var statusData = "";
    switch (statusD) {
        case 1:
            statusData = ' <span class="label label-info">New</span>';
            break;
        case 2:
            statusData = ' <span class="label label-info">Escalated</span>';
            break;
        case 4:
            statusData = ' <span class="label label-info">Escalated</span>';
            break;
        case 3:
            statusData = ' <span class="label label-success">Resolved</span>';
            break;
        case 5:
            statusData = ' <span class="label label-danger">Resolution Rejected</span>';
            break;
        case 6:
            statusData = ' <span class="label label-warning">Waiting Resolution Approval</span>';
            break;
        default:
            statusData = ' <span class="label label-default">Pending</span>';
    }
    return statusData;
}
```

---

## Action Rendering Implementation

**Main File:** [incident-table-by-status.js](../web/js/incident-table-by-status.js)
**Function:** `initDataTableIncidetsByStatus()` - DataTables column renderer
**Lines:** 140-226

### DataTable Column Configuration

```javascript
{
    "className": cellAlign,
    "render": function (data, type, full) {
        // Action rendering logic
    },
    "data": null,
    "width": cellWidth,
    'sortable': false
}
```

---

## Action Logic Breakdown

### 1. Download Action (Always Visible)

**Lines:** 143-153

```javascript
let incident = data.incidentReport;
let statusD = incident.statusData;
let idIncidentData = incident.idIncidentData;
let matrixType = incident.matrixType;
let statusType = status === '' ? 'published' : 'deleted';
let urlFile = urlCheckFile.replace('NAMEFILE', incident.fileUrl);

if (matrixType != '' && matrixType != null) {
    urlFile += '&idIncident=' + idIncidentData;
}

let actions = '<a title="Download" href="' + urlFile + '" target="_blank">
    <i class="fa fa-download"></i>
</a>&nbsp;';
```

**Variables:**
- `urlCheckFile`: Route pattern `incident_tracking_ajax_request_file`
- `incident.fileUrl`: PDF filename
- `idIncidentData`: Incident report ID

---

### 2. Delete/Undelete Action

**Lines:** 154-160

```javascript
let deleteAc = createDeleteButton(idIncidentData, statusType);
let undeleteAc = createUndeleteButton(idIncidentData, statusType);

// Anonymous report protection
if (statusType === 'published' && parseInt(incident.isAnonymous) === 1) {
    deleteAc = '';
}

// Conditional rendering based on tab
actions = (status === "") ? actions + deleteAc : actions + undeleteAc;
```

**Helper Functions:** [incident-report.js:240-264](../web/js/incident-report.js#L240-L264)

#### createDeleteButton()
```javascript
function createDeleteButton(idIncident, status) {
    var title = status === 'draft' ? 'Delete Incident Report Draft' : 'Delete Incident Report';

    return $('<a />', {
        'title': title,
        'class': "btnDeleteIncident",
        'data-id-incident': idIncident,
        'data-status': status,
        'href': "#"
    }).append($('<i class="fa fa-trash-o"/>'))[0].outerHTML;
}
```

#### createUndeleteButton()
```javascript
function createUndeleteButton(idIncident, status) {
    var title = status === 'draft' ? 'Undelete Incident Report Draft' : 'Undelete Incident Report';

    return $('<a />', {
        'title': title,
        'class': "btnUndeleteIncident",
        'data-id-incident': idIncident,
        'data-status': status,
        'href': "#"
    }).append($('<i class="fa fa-history"/>'))[0].outerHTML;
}
```

**Event Handlers:** [incident-report.js:203-238](../web/js/incident-report.js#L203-L238)

---

### 3. Edit Action - Rule Set A (New, Escalated, Resolution Rejected)

**Lines:** 162-184
**Statuses:** 1 (New), 2 (Escalated), 5 (Resolution Rejected)

```javascript
let editAc = '';

if ((userAllowEditIncident !== '' && userAllowEditIncident !== null)
    && matrixType !== '' && matrixType !== null
    && (statusD === 2 || statusD === 1 || statusD === 5)) {

    let urlIR = urlIRDefault.replace('IDIR', idIncidentData);
    let users = incident.matrixUsers;
    let editAcDefault = '<a title="Edit Incident Report" href="' + urlIR + '">
        <i class="fa fa-pencil-square-o" aria-hidden="true"></i>
    </a>&nbsp;';

    users = users.length > 0
        ? users.map(function (us) { return us.idEmployee; }).join()
        : 'no hay';

    if (statusD == 2 || statusD == 1 || statusD == 5) {
        if (userType != 'E') {
            // RACI Matrix (type 1)
            if ((userAllowEditIncident.indexOf('R') != -1)
                && (matrixType == 1)
                && (users.indexOf(userId) != -1)) {
                editAc = editAcDefault;
            }
            // Functional Matrix (type 2 or 4)
            else if ((userAllowEditIncident.indexOf('F') != -1)
                && (matrixType == 2 || matrixType == 4)
                && (users.indexOf(userId) != -1)) {
                editAc = editAcDefault;
            }
            // Group Matrix (type 5)
            else if ((userAllowEditIncident.indexOf('G') != -1)
                && (matrixType == 5)
                && (users.indexOf(userId) != -1)) {
                editAc = editAcDefault;
            }
            else {
                editAc = '';
            }
        }
    }
}
```

**Conditions:**
1. `userAllowEditIncident` exists and not null
2. `matrixType` exists and not null
3. Status is 1, 2, or 5
4. User type is NOT 'E' (Employee)
5. User ID is in `incident.matrixUsers` array
6. Permission type matches matrix type:
   - 'R' for RACI (type 1)
   - 'F' for Functional (type 2, 4)
   - 'G' for Group (type 5)

---

### 4. Edit Action - Rule Set B (Resolved with IR_EAR)

**Lines:** 185-203
**Status:** 3 (Resolved)
**Feature Flag:** `newSettings.IR_EAR.value === 1`

```javascript
else if (newSettings.IR_EAR.value == 1) {
    let urlIR = urlIRDefault.replace('IDIR', idIncidentData);
    let users = incident.matrixUsers;
    let editAcDefault = '<a title="Edit Incident Report" href="' + urlIR + '">
        <i class="fa fa-pencil-square-o" aria-hidden="true"></i>
    </a>&nbsp;';

    users = users.length > 0
        ? users.map(function (us) { return us.idEmployee; }).join()
        : 'no hay';

    if (incident.statusData == 3) { // Resolved status
        // RACI Matrix (type 1)
        if ((newSettings.IR_EAR.extras.indexOf('R') != -1)
            && (matrixType == 1)
            && (users.indexOf(userId) != -1)) {
            editAc = editAcDefault;
        }
        // Functional Matrix (type 2 or 4)
        else if ((newSettings.IR_EAR.extras.indexOf('F') != -1)
            && (matrixType == 2 || matrixType == 4)
            && (users.indexOf(userId) != -1)) {
            editAc = editAcDefault;
        }
        // Group Matrix (type 5)
        else if ((newSettings.IR_EAR.extras.indexOf('G') != -1)
            && (matrixType == 5)
            && (users.indexOf(userId) != -1)) {
            editAc = editAcDefault;
        }
        else {
            editAc = '';
        }
    }
}
```

**Conditions:**
1. `newSettings.IR_EAR.value == 1` (feature enabled)
2. Status is 3 (Resolved)
3. User ID is in `incident.matrixUsers` array
4. Permission type in `IR_EAR.extras` matches matrix type:
   - 'R' for RACI (type 1)
   - 'F' for Functional (type 2, 4)
   - 'G' for Group (type 5)

---

### 5. Legacy IRv2 Actions

**Lines:** 206-218

#### Open Discussion & Close Incident
```javascript
let typeIr = incident.typeIr;

if (typeIr == "Old" && incident['role'] != "-" && statusD != 3) {
    urlChat = urlChat.replace('IDREPORT', idIncidentData);
    urlClose = urlClose.replace('IDREPORT', idIncidentData);

    actions += '<a title="Open Discussion" href="' + urlChat + '">
        <i class="fa fa-comments-o"></i>
    </a>&nbsp;';
    actions += '<a title="Close Incident" href="' + urlClose + '">
        <i class="fa fa-floppy-o"></i>
    </a>&nbsp;';
}
```

**Conditions:**
- `typeIr == "Old"` (IRv2 report)
- `role != "-"` (user has role)
- Status is NOT 3 (not resolved)

#### Post Closure & Change Follow Up Date
```javascript
if (typeIr == "Old" && statusD == 3) {
    urlPost = urlPost.replace('IDREPORT', incident.id);

    actions += '<a title="Post Closure" href="' + urlPost + '">
        <i class="fa fa-envelope"></i>
    </a>&nbsp;';
    actions += '<a title="Change Follow Up Date" data-toggle="modal"
        data-target="#followDate-modal" data-closure-id="' + idIncidentData + '">
        <i class="fa fa-calendar"></i>
    </a>';
}
```

**Conditions:**
- `typeIr == "Old"` (IRv2 report)
- Status is 3 (resolved)

---

## Configuration Variables

### Frontend Variables (Twig Template)

**Template:** [incidentReports.html.twig](../src/Incident/TrackingBundle/Resources/views/irAdmin/incidentReports.html.twig)
**Lines:** 342-370

```javascript
var userAllowEditIncident = '{{ userAllowEditIncident }}';
userType = '{{ userType }}';
userId = '{{ idLogged }}';
reports = [];
newSettings = {
    IR_EAR: {{ companySettingsNew.detail.IR_EAR | json_encode | raw }}
};
```

### Variable Descriptions

| Variable | Type | Description | Example Values |
|----------|------|-------------|----------------|
| `userAllowEditIncident` | string | User's edit permissions | 'R', 'F', 'G', 'RF', 'RFG' |
| `userType` | string | User type code | 'S' (admin), 'E' (employee) |
| `userId` | string | Current user ID | '123' |
| `newSettings.IR_EAR.value` | integer | IR_EAR feature flag | 0 (disabled), 1 (enabled) |
| `newSettings.IR_EAR.extras` | string | IR_EAR permissions | 'R', 'F', 'G', 'RFG' |

### URL Patterns

```javascript
var urlIRDefault = "{{ path('incident_creation_admin_renderCustomIncidentReport',
    {'idIncident': 'IDIR'}) }}";
var urlGetIncidentCreated = "{{ path('incident_tracking_admin_getIncidentCreatedByCompany') }}";
var urlCheckFile = "{{ path('incident_tracking_ajax_request_file', {'fileName': 'NAMEFILE'}) }}";
var urlPathDetail = "{{ path('incident_tracking_admin_incidentDetailView',
    {'idIncidentReport':'IDIR'}) }}";
var urlChat = "{{ path('planet_media_med_trainer_admin_incidentConversations',
    {'idIncidentData':'IDREPORT', 'iV':'3'}) }}";
var urlClose = "{{ path('planet_media_med_trainer_admin_closeIncident',
    {'idIncidentData':'IDREPORT', 'iV':'3'}) }}";
var urlPost = "{{ path('planet_media_med_trainer_admin_postClosureForm',
    {'idCompanyIncident':'IDREPORT'}) }}";
var urlDeleteIncident = "{{ path('planet_media_med_trainer_admin_deleteIncident') }}";
var urlUndeleteIncident = "{{ path('planet_media_med_trainer_admin_undeleteIncident') }}";
```

---

## Matrix Type Constants

| Matrix Type Code | Matrix Name | Permission Flag | Entity Relationship |
|------------------|-------------|-----------------|---------------------|
| `1` | RACI | 'R' | `IrScaleMatrixCompany` (RACI type) |
| `2` | Functional | 'F' | `IrScaleMatrixCompany` (Functional) |
| `4` | Functional (legacy) | 'F' | Legacy IRv2 functional matrix |
| `5` | Group | 'G' | `IrScaleMatrixCompany` (Group type) |

**Database Table:** `ir_escalations_report`
**Entity:** [IrEscalationsReport.php](../src/Incident/TrackingBundle/Entity/IrEscalationsReport.php)

---

## Database Schema

### Key Tables

#### `incident_scalable_data`
Primary incident data table

| Column | Type | Description |
|--------|------|-------------|
| `id` | int | Primary key |
| `status` | varchar(2) | Status code (1, 2, 3, 5, 6, 0, -5) |
| `incident_number` | varchar(50) | Display number |
| `resolution_date` | datetime | When resolved |

#### `company_incident_scalable`
Company-level incident tracking

| Column | Type | Description |
|--------|------|-------------|
| `id` | int | Primary key |
| `status` | varchar(1) | 'D' (deleted), 'S' (draft) |
| `id_incident_scalable_detail` | int | FK to incident_scalable_data |
| `is_anonymous` | tinyint | 1 if anonymous |
| `file_url` | varchar(255) | PDF filename |

#### `ir_escalations_report`
Matrix assignments

| Column | Type | Description |
|--------|------|-------------|
| `id` | int | Primary key |
| `id_incident_scalable_data` | int | FK to incident |
| `id_employee` | int | Assigned user |
| `status` | tinyint | 1 = active |

---

## Server-Side Data Loading

**Controller:** [TrackingActionsController.php](../src/Incident/TrackingBundle/Controller/TrackingActionsController.php)
**Action:** `getIncidentCreatedByCompanyAction()`

### Query Structure

```sql
SELECT
    cir.id, cir.title, ir.name,
    isd.employeeName,
    DATE_FORMAT(isd.dateIncident, '%m/%d/%Y') as dateIncident,
    DATE_FORMAT(cir.creationDate, '%m/%d/%Y') as dateReport,
    l.name as nameLocation,
    cir.idIncidentScalableDetail,
    cir.fileUrl,
    cir.status,
    cir.oldId,
    isd.status as statusData,
    isd.id as idIncidentData,
    DATE_FORMAT(isd.resolutionDate, '%m/%d/%Y') as resolutionDate,
    isd.incidentNumber,
    cir.isAnonymous
FROM company_incident_scalable cir
INNER JOIN incident_scalable_data isd ON cir.idIncidentScalableDetail = isd.id
LEFT JOIN incident_report ir ON isd.idIncidentReport = ir.id
LEFT JOIN location l ON isd.idLocation = l.id
WHERE cir.status != 'D' -- Filter deleted (or = 'D' for deleted tab)
ORDER BY cir.creationDate DESC
```

### Matrix Users Query

```sql
SELECT DISTINCT e.id as idEmployee
FROM ir_escalations_report ier
INNER JOIN employee e ON ier.idEmployee = e.id
WHERE ier.idIncidentScalableData = :incidentId
AND ier.status = 1
```

---

## Action Matrix (Technical Reference)

| Status Code | Download | Delete | Restore | Edit (Rule A) | Edit (Rule B) | IRv2 Actions |
|-------------|----------|--------|---------|---------------|---------------|--------------|
| 0 (Draft) | ✅ | ✅¹ | ❌ | ❌ | ❌ | ❌ |
| 1 (New) | ✅ | ✅¹ | ❌ | ✅² | ❌ | ✅³ |
| I (Initiated) | ✅ | ✅¹ | ❌ | ✅² | ❌ | ✅³ |
| 2 (Escalated) | ✅ | ✅¹ | ❌ | ✅² | ❌ | ✅³ |
| 3 (Resolved) | ✅ | ✅¹ | ❌ | ❌ | ✅⁴ | ✅⁵ |
| 5 (Rej. Res.) | ✅ | ✅¹ | ❌ | ✅² | ❌ | ✅³ |
| 6 (Wait. Appr.) | ✅ | ✅¹ | ❌ | ❌ | ❌ | ✅³ |
| D (Deleted) | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

**Footnotes:**
1. `!isAnonymous` - Not for anonymous reports
2. Lines 162-184: Matrix + permission + user assigned
3. Lines 207-212: `typeIr === "Old"` + `statusData != 3`
4. Lines 185-203: `IR_EAR.value === 1` + matrix + permission
5. Lines 215-218: `typeIr === "Old"` + `statusData === 3`

---

## Testing & Debugging

### Debug Console Output

Add to `incident-table-by-status.js` line 142:

```javascript
console.log('Incident Debug:', {
    id: incident.idIncidentData,
    status: statusD,
    matrixType: matrixType,
    isAnonymous: incident.isAnonymous,
    matrixUsers: incident.matrixUsers,
    userAllowEditIncident: userAllowEditIncident,
    userId: userId,
    userType: userType,
    IR_EAR: newSettings.IR_EAR
});
```

### Unit Test Scenarios

```javascript
// Test Edit visibility for New status with RACI matrix
const testData = {
    incidentReport: {
        statusData: 1, // New
        matrixType: 1, // RACI
        matrixUsers: [{idEmployee: '123'}],
        isAnonymous: 0
    }
};
const userAllowEditIncident = 'R';
const userId = '123';
const userType = 'S';
// Expected: Edit button visible
```

### SQL Queries for Verification

#### Check incident status
```sql
SELECT id, status, incident_number, resolution_date
FROM incident_scalable_data
WHERE id = ?;
```

#### Check company status
```sql
SELECT id, status, is_anonymous
FROM company_incident_scalable
WHERE id_incident_scalable_detail = ?;
```

#### Check matrix assignments
```sql
SELECT ier.id, e.id as employee_id, e.first_name, e.last_name
FROM ir_escalations_report ier
INNER JOIN employee e ON ier.id_employee = e.id
WHERE ier.id_incident_scalable_data = ?
AND ier.status = 1;
```

---

## Performance Considerations

### DataTables Server-Side Processing

- **Enabled:** Yes (`"serverSide": true`)
- **AJAX URL:** `urlGetIncidentCreated`
- **Pagination:** 10 records per page
- **Sorting:** Default by creation date DESC

### Query Optimization

1. **Index on `company_incident_scalable.status`** - For tab filtering
2. **Index on `incident_scalable_data.status`** - For status filtering
3. **Index on `ir_escalations_report.id_incident_scalable_data`** - For matrix lookups
4. **Composite index:** `(id_incident_scalable_data, status)` on `ir_escalations_report`

### Caching Strategy

- **Matrix users:** Cached per incident in DataTables data
- **User permissions:** Retrieved once on page load
- **Company settings:** Retrieved once on page load

---

## Related Code Files

| File | Purpose |
|------|---------|
| [incident-table-by-status.js](../web/js/incident-table-by-status.js) | Main action rendering |
| [incident-report.js](../web/js/incident-report.js) | Event handlers, button creators |
| [incident_report_nv.js](../web/js/incident_report_nv.js) | Status labels, utilities |
| [TrackingActionsController.php](../src/Incident/TrackingBundle/Controller/TrackingActionsController.php) | Backend data endpoints |
| [incidentReports.html.twig](../src/Incident/TrackingBundle/Resources/views/irAdmin/incidentReports.html.twig) | Frontend template |
| [Status.php](../src/Incident/TrackingBundle/Constants/Status.php) | Status constants |
| [IncidentScalableData.php](../src/PlanetMedia/MedTrainerBundle/Entity/IncidentScalableData.php) | Entity constants |

---

## Change History

| Date | Author | Changes |
|------|--------|---------|
| 2025-11-13 | Claude Code | Initial technical documentation |

---

**Document Status:** ✅ Complete
**Last Updated:** 2025-11-13
**For Product View See:** [IncidentTracking_ActionsMatrix_ProductView.md](./IncidentTracking_ActionsMatrix_ProductView.md)
**Maintained By:** Engineering Team
