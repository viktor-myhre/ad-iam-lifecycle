# AD IAM Lifecycle Lab

## Project Overview

This repository contains an enterprise-style lab focused on Active Directory identity lifecycle management in a Windows-based environment. The project is designed to demonstrate practical onboarding and offboarding workflows, group-based access control, PowerShell administration, and security-minded documentation in a simulated organization.

## Purpose

The goal of the lab is to show how an IT or IAM administrator could build and document a defensible account lifecycle process in Active Directory. The project emphasizes:

- account provisioning and deprovisioning
- consistent OU placement
- group-based access assignment
- least privilege
- auditability
- reproducible lab steps

## Lab Architecture

The planned lab uses a simple Windows domain environment with the example domain `corp.local`.

- Active Directory Domain Services for user, group, and OU management
- DNS for internal name resolution
- Windows Server for domain services and administration
- Windows client VM for user and admin workflow testing
- PowerShell for repeatable IAM tasks

High-level structure:

```text
corp.local
+-- Domain Controller
+-- Administrative Workstation
`-- Client Workstation
```

## Technologies Used

- Windows Server
- Active Directory Domain Services
- DNS
- PowerShell 5.1 and PowerShell 7
- Git and GitHub
- Markdown documentation

## What Was Implemented

This repository starts by defining the operating model before automation is introduced.

- lab architecture documentation
- OU structure design
- group naming and access strategy
- onboarding workflow documentation
- offboarding workflow documentation
- audit and logging documentation
- user provisioning PowerShell script
- user deprovisioning PowerShell script
- group membership reporting PowerShell script
- repository structure for scripts, diagrams, screenshots, and lab notes

Planned implementation areas:

- compliance and access review checks

## Security Considerations

- Access should be granted through groups rather than direct user permissions.
- Standard and administrative accounts should remain separated.
- Privileged groups should be small, documented, and reviewed regularly.
- Offboarding should remove unnecessary access quickly and preserve verification evidence.
- Scripts that modify Active Directory should support `-WhatIf` and clear verification steps.

## How To Reproduce The Lab

1. Build a Windows Server lab with Active Directory Domain Services and DNS.
2. Create the example domain `corp.local`.
3. Implement the OU structure documented in [docs/ou-structure.md](docs/ou-structure.md).
4. Create security groups using the naming strategy in [docs/group-strategy.md](docs/group-strategy.md).
5. Validate account lifecycle steps against the workflows that will be documented and scripted in this repository.

## Verification

Example verification tasks for the lab:

- confirm users are created in the correct OU
- confirm department attributes are populated
- confirm group membership matches role and department
- confirm disabled users are moved to the disabled users OU
- confirm administrative access is assigned through dedicated groups

## Screenshots And Diagrams

Planned additions:

- AD Users and Computers OU view
- group membership examples
- onboarding and offboarding workflow diagram
- sample verification output from PowerShell

## Lessons Learned

This section will be updated as the lab grows. The expected focus is on how design decisions affect day-to-day administration, auditability, and the security impact of identity lifecycle management.

## Future Improvements

- add privileged access review examples
- add compliance validation and reporting scripts
- add architecture and workflow diagrams
