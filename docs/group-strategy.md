# Group Strategy

## Overview

This lab uses group-based access control instead of direct user permissions. The goal is to model a simple, explainable approach that demonstrates least privilege and supports repeatable onboarding and offboarding.

## Naming Convention

The planned naming convention is:

- `GG_<Department>_Users` for role or department membership groups
- `GG_<Department>_Admins` for privileged department groups where needed
- `DL_<Resource>_<Permission>` for resource access groups

Examples:

```text
GG_HR_Users
GG_Finance_Users
GG_IT_Admins
DL_HR_Share_Read
DL_HR_Share_Modify
```

## Group Model

Decision:
Use groups to assign access and avoid direct permission assignment to user accounts.

Reason:
Group-based administration is easier to scale, easier to review, and easier to reverse during offboarding.

Security impact:
This reduces inconsistent access assignment and makes it simpler to review who should have access to a resource.

Operational impact:
Onboarding scripts can add users to the correct department group, while offboarding can remove non-default memberships in a consistent way.

Verification:
Assign a test user to a department group and verify resource access through group membership rather than direct ACL changes.

Decision:
Separate standard department groups from privileged admin groups.

Reason:
A user being part of a department does not automatically mean the user needs administrative capability.

Security impact:
This supports least privilege and makes privileged access easier to monitor.

Operational impact:
Privilege reviews become simpler because administrative rights are tied to a smaller set of clearly named groups.

Verification:
Review membership of `GG_IT_Admins` separately from standard department groups and confirm the membership is intentional.

## Operational Guidance

- New users should be added to baseline department groups during onboarding.
- Resource access should be granted to groups, not directly to users.
- Privileged groups should require deliberate assignment and verification.
- Offboarding should remove non-default group memberships before the account is moved to the disabled users OU.

## Production Difference

In a larger environment, this model could expand toward a more formal AGDLP-style pattern. For this lab, the design stays intentionally small so the reasoning remains easy to explain while still showing sound administrative practice.
