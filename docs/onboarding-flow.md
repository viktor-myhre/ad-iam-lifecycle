# Onboarding Flow

## Overview

This document defines the onboarding workflow for the `corp.local` lab. The goal is to create new user accounts in a predictable, auditable way that supports department-based OU placement, baseline group assignment, and least-privilege administration.

## Workflow Summary

1. Collect the user's approved onboarding details.
2. Create the account with standard identity attributes.
3. Place the account in the correct department OU.
4. Assign the baseline department group.
5. Require a password change at first sign-in.
6. Verify the account attributes and group membership.
7. Record the completed onboarding action in lab notes if needed.

## Required Inputs

- First name
- Last name
- Department
- Initial password for lab use

Optional inputs:

- Domain DNS name when different from the current domain context
- Custom OU mapping if the lab is extended later

## Standard Onboarding Logic

Decision:
Generate a predictable username from the user's first and last name.

Reason:
Consistent naming makes account administration easier and reduces ambiguity during verification.

Security impact:
Predictable naming improves operational clarity, but usernames alone should not be treated as a security boundary.

Operational impact:
Administrators can explain and reproduce the naming logic easily during onboarding and troubleshooting.

Verification:
Confirm the created `SamAccountName` and `UserPrincipalName` match the documented standard.

Decision:
Place the new account in a department OU instead of a shared default container.

Reason:
Department placement keeps the directory organized and aligns the account with the intended access model.

Security impact:
Misplaced accounts become easier to detect during review, and delegated or policy-based administration becomes more predictable.

Operational impact:
Provisioning can be standardized by mapping department names to OU paths.

Verification:
Confirm the user object was created in the expected OU under `Corp\Users`.

Decision:
Assign a baseline department group during onboarding.

Reason:
Access should be granted through groups instead of direct user permissions.

Security impact:
This supports least privilege and makes it easier to audit access assignment decisions.

Operational impact:
New users receive baseline departmental access in one repeatable step.

Verification:
Confirm the user is a member of the expected `GG_<Department>_Users` group after creation.

## Security Notes

- The onboarding process should be run from an administrative workstation, not a standard user session.
- The script should support `-WhatIf` before real changes are applied.
- Initial passwords in this lab are for demonstration only and should still be handled carefully.
- Administrative group assignment should remain a separate approval step from standard user provisioning.

## Script Alignment

The onboarding workflow is implemented in [New-CompanyUser.ps1](../scripts/New-CompanyUser.ps1).

The script is expected to:

- validate the department value
- derive the target OU
- derive the baseline department group
- create the user account
- add the user to the baseline group
- provide verbose output and verification guidance

## Live Validation Status

The onboarding workflow has been tested successfully in the live `corp.local` lab.

Validated example:

- user created: `alice.andersson`
- department: `HR`
- target OU: `OU=HR,OU=Users,OU=Corp,DC=corp,DC=local`
- baseline group: `GG_HR_Users`

Validation evidence:

- `Get-ADUser -Identity alice.andersson -Properties Department, Enabled, DistinguishedName`
- `Get-ADPrincipalGroupMembership alice.andersson | Select-Object Name`

Observed result:

- the account was created as enabled
- the `Department` attribute was set to `HR`
- the user object was placed in the expected HR OU
- the user was added to `GG_HR_Users`

## Verification

Use commands like the following after onboarding:

```powershell
Get-ADUser -Identity alice.andersson -Properties Department, Enabled, DistinguishedName
Get-ADPrincipalGroupMembership alice.andersson | Select-Object Name
```

Expected results:

- the user is enabled
- the `Department` attribute is populated
- the user object is in the correct OU
- the user is a member of the expected department group

## Production Difference

In production, onboarding would usually include manager approval, ticket references, mailbox provisioning, application access workflows, stronger password handling, and more formal evidence capture. This lab keeps the workflow intentionally small so the core identity lifecycle steps remain easy to follow and verify.
