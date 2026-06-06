# OU Structure

## Overview

This document defines the planned organizational unit layout for the `corp.local` lab. The goal is to keep administration clear, support delegated management where appropriate, and separate active and disabled identities.

## Planned OU Layout

```text
Corp
+-- Users
|   +-- IT
|   +-- HR
|   +-- Finance
|   `-- Operations
+-- Groups
+-- Workstations
+-- Servers
+-- Admin Accounts
`-- Disabled Users
```

## Design Decisions

Decision:
Place user accounts into department-specific OUs under `Corp\Users`.

Reason:
Department-based placement supports cleaner administration, easier browsing in ADUC, and more predictable onboarding workflows.

Security impact:
It becomes easier to review where identities belong and easier to spot misplaced accounts during audits.

Operational impact:
Onboarding scripts can map a department value to a target OU path without hard-to-explain logic.

Verification:
Create test users in each department and confirm they are stored in the expected OU.

Decision:
Maintain a dedicated `Disabled Users` OU.

Reason:
Disabled accounts should remain separated from active users so offboarding results are easy to review and verify.

Security impact:
This supports faster confirmation that former users are no longer active and helps reduce the chance of forgotten accounts blending into active user containers.

Operational impact:
Offboarding steps become consistent: disable the account, remove non-default access, move the object, and verify the result.

Verification:
Disable a test user, move it to `Disabled Users`, and confirm the account no longer appears in the department OU.

Decision:
Keep `Admin Accounts` separate from standard user OUs.

Reason:
Administrative identities should be visible, intentionally managed, and kept distinct from normal day-to-day user accounts.

Security impact:
This supports least privilege and helps highlight privileged identities during access reviews.

Operational impact:
Admin account management becomes more deliberate and easier to document.

Verification:
Confirm privileged accounts are stored in the dedicated OU and assigned only to approved admin groups.

## Naming Notes

- The top-level business OU is `Corp`.
- User OUs follow department names to keep account placement understandable.
- The structure is optimized for a small portfolio lab rather than large-scale enterprise delegation.
