# Lab Architecture

## Overview

This lab simulates a small Windows-based organization named `corp.local`. The environment is intentionally limited in scope so the identity lifecycle processes remain easy to understand, test, and explain in an interview.

## Design

Decision:
Use a single-domain lab with one primary domain controller, one administrative workstation, and one client workstation.

Reason:
This design keeps the environment small enough to build and maintain while still demonstrating core Active Directory administration and IAM workflow concepts.

Security impact:
A smaller lab reduces complexity and makes it easier to observe how OU placement, group assignment, and account disablement affect user access.

Operational impact:
The environment is fast to rebuild and practical for repeatable portfolio demonstrations.

Verification:
Validate domain join, DNS resolution, administrative sign-in, and account management from the administrative workstation.

## Planned Components

- Domain: `corp.local`
- Domain controller running Active Directory Domain Services and DNS
- One administrative workstation for running PowerShell and AD management tools
- One standard client workstation for user access testing

## Logical Layout

```text
corp.local
+-- Domain Controller
|   +-- Active Directory Domain Services
|   `-- DNS
+-- Admin Workstation
|   +-- RSAT tools
|   `-- PowerShell administration
`-- Client Workstation
    `-- User sign-in and access testing
```

## Administrative Model

Decision:
Separate administrative activity from standard user activity.

Reason:
This reflects a safer operating model and supports the principle of least privilege.

Security impact:
Administrative privileges are easier to monitor when they are tied to dedicated groups and, where possible, dedicated admin accounts.

Operational impact:
This adds a small amount of overhead but makes the lab more realistic and easier to discuss in a portfolio or interview setting.

Verification:
Confirm that privileged group membership is limited and documented, and test that standard users do not receive administrative access by default.

## Production Difference

This lab is intentionally simpler than a production environment. A production design would likely include additional domain controllers, stronger monitoring, backup strategy, delegated administration boundaries, and more formal approval processes around identity changes.
