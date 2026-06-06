# Offboarding Flow

## Overview

This document defines the offboarding workflow for the `corp.local` lab. The goal is to remove user access quickly, preserve a clear audit trail, and separate disabled identities from active department accounts.

## Workflow Summary

1. Confirm the user account to offboard.
2. Disable the Active Directory account.
3. Remove non-default group memberships.
4. Move the account to the `Disabled Users` OU.
5. Clear or preserve selected attributes based on the lab procedure.
6. Verify the account state, location, and remaining memberships.
7. Record the completed offboarding action in lab notes if needed.

## Required Inputs

- `SamAccountName`

Optional inputs:

- whether manager and department attributes should be cleared
- whether the disabled account OU differs from the default lab path

## Standard Offboarding Logic

Decision:
Disable the account before making additional cleanup changes.

Reason:
Immediate disablement reduces the time window in which a former user could still authenticate.

Security impact:
This is the fastest way to cut off interactive access while the remaining cleanup steps are completed.

Operational impact:
Administrators can then remove access and move the object without working against an active account.

Verification:
Confirm `Enabled` is set to `False` immediately after the offboarding action begins.

Decision:
Remove non-default group memberships during offboarding.

Reason:
A disabled account should not continue to retain unnecessary access assignments.

Security impact:
This reduces the chance that a disabled account is later re-enabled with stale privileges still attached.

Operational impact:
Group cleanup produces a clearer account state for audits and later review.

Verification:
Confirm that only default or explicitly retained groups remain after offboarding.

Decision:
Move disabled accounts into a dedicated OU.

Reason:
Keeping former users in a separate location makes the directory easier to review and helps distinguish active identities from deprovisioned ones.

Security impact:
This reduces confusion during administrative review and makes forgotten accounts easier to spot.

Operational impact:
The directory layout stays cleaner and offboarding results are easier to demonstrate.

Verification:
Confirm the user object has been moved to `OU=Disabled Users,OU=Corp`.

## Security Notes

- Offboarding should be run from an administrative workstation.
- Group cleanup should happen after disablement, not before.
- Privileged memberships should be reviewed carefully as part of deprovisioning.
- The script should support `-WhatIf` so the operator can preview the cleanup scope before applying it.

## Script Alignment

The offboarding workflow is implemented in [Disable-CompanyUser.ps1](../scripts/Disable-CompanyUser.ps1).

The script is expected to:

- locate the target user by `SamAccountName`
- disable the account
- remove non-default group memberships
- move the user object to the disabled users OU
- optionally clear manager and department data
- provide verbose output and verification guidance

## Verification

Use commands like the following after offboarding:

```powershell
Get-ADUser -Identity alice.andersson -Properties Enabled, Department, Manager, DistinguishedName
Get-ADPrincipalGroupMembership alice.andersson | Select-Object Name
```

Expected results:

- the user is disabled
- the user is located in the `Disabled Users` OU
- non-default group memberships have been removed
- selected metadata has been cleared if requested

## Production Difference

In production, offboarding usually involves HR or manager approval, ticket references, mailbox retention rules, device recovery, access reviews, and evidence capture across multiple systems. This lab keeps the workflow focused on core Active Directory identity cleanup so the administrative and security logic remain easy to explain.
