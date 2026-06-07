# Audit And Logging

## Overview

This document defines the audit and logging approach for the `corp.local` lab. The goal is to show that identity lifecycle changes are not only performed, but also reviewed, verified, and explained from a security perspective.

## Audit Objectives

- confirm onboarding creates the expected account and baseline access
- confirm offboarding removes unnecessary access and isolates disabled accounts
- review current group memberships for standard and privileged access
- identify changes that deserve closer attention during administrative review
- produce evidence that can be shown in a portfolio or interview setting

## Logging Priorities

Decision:
Prioritize visibility into user creation, user disablement, and group membership changes.

Reason:
These events are directly tied to the lifecycle controls this lab is designed to demonstrate.

Security impact:
Monitoring these actions improves the ability to detect unintended access assignment or incomplete offboarding.

Operational impact:
Administrators can validate whether the process worked as intended without relying only on memory or screenshots.

Verification:
Compare lifecycle actions with user state, group membership, and relevant event records after each change.

Decision:
Treat privileged group membership as a higher-review area than standard department access.

Reason:
Changes to privileged access carry a higher security impact and deserve more deliberate review.

Security impact:
This supports least privilege and helps detect risky changes earlier.

Operational impact:
Review time can be focused on the groups that matter most from a control standpoint.

Verification:
Review membership in groups such as `GG_IT_Admins` separately from baseline department groups.

## What To Review In This Lab

### Onboarding

- Was the user created in the correct department OU?
- Was the `Department` attribute populated correctly?
- Was the user added to the correct baseline group?
- Was the account created as enabled with password change at next sign-in?

### Offboarding

- Was the account disabled?
- Were non-default group memberships removed?
- Was the user moved to the `Disabled Users` OU?
- Were manager or department attributes cleared if that was part of the procedure?

### Access Review

- Who is currently in each department group?
- Who is currently in privileged groups?
- Are disabled users still present in groups they should no longer belong to?
- Do any memberships appear inconsistent with the user's department or lifecycle state?

## Example Data Sources

- Active Directory user properties
- Active Directory group membership
- Windows Security event logs on the domain controller
- exported CSV reports from access review scripts
- screenshots of verification commands and ADUC views

## Example Events To Discuss

This lab does not depend on a fully built detection pipeline, but these are reasonable Windows event areas to mention and review:

- user account creation activity
- user account disablement activity
- group membership changes
- privileged group membership changes

The exact event IDs can be documented later once the live lab is built and tested.

## Reporting Approach

The group membership review process is implemented in [Export-GroupMembershipReport.ps1](../scripts/Export-GroupMembershipReport.ps1).

The script is intended to support:

- export of one specified group
- export of all baseline department groups
- export of privileged groups only
- review of user identity details alongside membership data

## Live Validation Status

The reporting workflow has been tested successfully in the live `corp.local` lab.

Validated example:

```powershell
.\Export-GroupMembershipReport.ps1 -GroupName GG_HR_Users -Verbose
```

Observed result:

- the script returned membership data for `GG_HR_Users`
- the report included `alice.andersson`
- the output included `SamAccountName`, `Department`, `Enabled`, and `DistinguishedName`

Validation note:

During live testing, a bug was identified in the report mode selection logic for the `-GroupName` parameter set. The script was corrected so the selected parameter set is resolved from the parent script scope before group collection begins.

## Verification

Use reporting and verification commands such as:

```powershell
.\Export-GroupMembershipReport.ps1 -GroupName GG_HR_Users
.\Export-GroupMembershipReport.ps1 -PrivilegedOnly
Get-ADPrincipalGroupMembership alice.andersson | Select-Object Name
```

Expected results:

- membership data can be reviewed in a readable format
- CSV exports can be generated for evidence or comparison
- privileged groups can be reviewed separately from baseline access groups

## Security Notes

- Reports should not include real personal data in a public portfolio repository.
- Screenshots should be reviewed before publication to avoid exposing unnecessary hostnames, usernames, or internal details.
- Exported reports should be treated as review artifacts and kept out of Git unless intentionally sanitized.

## Production Difference

In production, audit and logging would usually include centralized collection, longer retention, formal review frequency, alerting for privileged access changes, and evidence tied to change requests or tickets. This lab keeps the scope intentionally small while still demonstrating the administrative reasoning behind access review and verification.
