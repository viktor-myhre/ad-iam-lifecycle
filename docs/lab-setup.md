# Lab Setup

## Overview

This document provides a reproducible build guide for the `corp.local` Active Directory lab. The goal is to create a small, realistic Windows environment that matches the repository design and supports live validation of the onboarding, offboarding, and reporting workflows.

## Lab Goal

Build a minimal domain environment that supports:

- Active Directory Domain Services
- DNS
- department-based OUs
- group-based access control
- an administrative workstation with AD management tools
- a standard client for user sign-in and access testing

## Recommended VM Layout

### Domain Controller

- Operating system: Windows Server
- Suggested hostname: `DC01`
- Planned roles:
  - Active Directory Domain Services
  - DNS

### Administrative Workstation

- Operating system: Windows client
- Suggested hostname: `ADMIN01`
- Planned tools:
  - RSAT Active Directory tools
  - PowerShell 7
  - Git
  - VS Code

### Standard Client

- Operating system: Windows client
- Suggested hostname: `CLIENT01`
- Purpose:
  - test user sign-in
  - test baseline access behavior

## Domain Design

Decision:
Use a single domain named `corp.local`.

Reason:
This keeps the lab easy to build and rebuild while still demonstrating core domain administration and IAM workflows.

Security impact:
A simpler layout makes it easier to verify access decisions and trace lifecycle changes.

Operational impact:
The environment is faster to troubleshoot and more practical for portfolio demonstrations.

Verification:
Confirm that all lab systems can resolve and join `corp.local`.

## Build Order

1. Create the Windows Server VM.
2. Configure a static IP address for the server.
3. Install Active Directory Domain Services and DNS.
4. Promote the server to a new forest using `corp.local`.
5. Restart and validate domain controller health.
6. Create the Windows admin workstation and join it to the domain.
7. Install RSAT and PowerShell 7 on the admin workstation.
8. Create the Windows client workstation and join it to the domain.
9. Build the planned OU structure.
10. Create the baseline department and privileged groups.
11. Validate that the repository scripts align with the live directory paths and names.

## Domain Controller Setup

### Initial Tasks

- assign a static IP address
- set the preferred DNS server to itself after DNS is installed
- rename the host to `DC01`
- apply Windows updates before promotion if practical

### Install Roles

Install:

- Active Directory Domain Services
- DNS Server

Example PowerShell:

```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
```

### Promote The Server

Create a new forest named `corp.local`.

Example PowerShell:

```powershell
Install-ADDSForest `
    -DomainName "corp.local" `
    -DomainNetbiosName "CORP" `
    -InstallDns
```

Verification:

```powershell
Get-ADDomain
Get-ADForest
Get-Service NTDS, DNS
```

## Administrative Workstation Setup

Decision:
Use a dedicated administrative workstation rather than managing the domain primarily from the domain controller console.

Reason:
This better reflects normal administration practice and keeps management activity separate from server hosting.

Security impact:
Administrative actions become easier to reason about and can later be discussed in the context of safer workstation-based administration.

Operational impact:
The workstation becomes the main place to run PowerShell scripts, RSAT, and validation commands.

Verification:
Confirm the workstation can sign in with domain admin credentials and open AD management tools.

### Required Tools

- RSAT Active Directory tools
- PowerShell 7
- Git
- VS Code

Example RSAT install:

```powershell
Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Add-WindowsCapability -Online
```

Example verification:

```powershell
Get-Command Get-ADUser
pwsh --version
```

## OU Creation

Build the OU layout defined in [ou-structure.md](ou-structure.md).

Target structure:

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

Example PowerShell:

```powershell
New-ADOrganizationalUnit -Name "Corp" -Path "DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Users" -Path "OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "IT" -Path "OU=Users,OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "HR" -Path "OU=Users,OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Finance" -Path "OU=Users,OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Operations" -Path "OU=Users,OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Groups" -Path "OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Admin Accounts" -Path "OU=Corp,DC=corp,DC=local"
New-ADOrganizationalUnit -Name "Disabled Users" -Path "OU=Corp,DC=corp,DC=local"
```

Verification:

```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
```

## Group Creation

Build the baseline groups defined in [group-strategy.md](group-strategy.md).

Start with:

- `GG_HR_Users`
- `GG_Finance_Users`
- `GG_IT_Users`
- `GG_Operations_Users`
- `GG_IT_Admins`

Example PowerShell:

```powershell
New-ADGroup -Name "GG_HR_Users" -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
New-ADGroup -Name "GG_Finance_Users" -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
New-ADGroup -Name "GG_IT_Users" -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
New-ADGroup -Name "GG_Operations_Users" -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
New-ADGroup -Name "GG_IT_Admins" -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
```

Verification:

```powershell
Get-ADGroup -Filter "Name -like 'GG_*'" | Select-Object Name, DistinguishedName
```

## Script Readiness Check

Before running the repository scripts live, confirm the directory matches these assumptions:

- domain name is `corp.local`
- top-level OU is `Corp`
- user OUs exist for `IT`, `HR`, `Finance`, and `Operations`
- `Disabled Users` OU exists
- baseline groups exist for each department
- `GG_IT_Admins` exists for privileged-access review

## First Validation Checklist

1. Sign in to `ADMIN01` with a domain admin account.
2. Run `Get-ADDomain` and verify the domain context.
3. Validate OU creation.
4. Validate group creation.
5. Run `New-CompanyUser.ps1` with `-WhatIf`.
6. Create one real test user in a department OU.
7. Confirm baseline group assignment.
8. Run `Export-GroupMembershipReport.ps1` for the user's department group.
9. Run `Disable-CompanyUser.ps1` with `-WhatIf`.
10. Offboard the same test user and verify disablement, group cleanup, and OU move.

## Evidence To Capture

- screenshot of ADUC showing the OU structure
- screenshot of created groups
- PowerShell output from verification commands
- onboarding script output
- offboarding script output
- access review report output

## Security Notes

- Do not use real employee names or real company information.
- Keep screenshots and exported reports sanitized before publishing them.
- Use the lab to demonstrate defensive administration, not production claims.
- Keep privileged memberships intentionally small and documented.

## Production Difference

In production, the build would normally include backup planning, patching standards, delegated administration boundaries, formal naming standards, monitoring retention, and approval workflows. This lab stays intentionally small so the setup remains practical while still supporting realistic IAM lifecycle demonstrations.
