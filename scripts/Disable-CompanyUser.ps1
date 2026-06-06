<#
.SYNOPSIS
Disables an Active Directory user account, removes non-default group memberships, and moves the account to the disabled users OU.

.DESCRIPTION
This script deprovisions a standard user account for the corp.local lab. It disables the account, removes
the user from non-default group memberships, moves the object to the disabled users OU, and can optionally
clear selected business metadata such as Department and Manager.

The script is designed for lab use and emphasizes safe execution through SupportsShouldProcess, clear
logging, and predictable cleanup behavior.

.PARAMETER SamAccountName
The SamAccountName of the user to offboard.

.PARAMETER DisabledUsersOu
The distinguished name of the disabled users OU relative to the current domain.

.PARAMETER ClearDepartment
Clears the Department attribute after the account is disabled.

.PARAMETER ClearManager
Clears the Manager attribute after the account is disabled.

.EXAMPLE
.\Disable-CompanyUser.ps1 -SamAccountName alice.andersson -WhatIf

.EXAMPLE
.\Disable-CompanyUser.ps1 -SamAccountName david.berg -ClearDepartment -ClearManager -Verbose

.NOTES
Purpose: Disable a user account and remove baseline access as part of offboarding.
Inputs: SamAccountName and optional metadata cleanup switches.
What it changes: Disables the AD user, removes non-default groups, clears selected attributes, and moves the object.
Safety controls: SupportsShouldProcess, prerequisite validation, non-default group filtering, and verbose output.
Example usage: See examples above.
Verification:
Get-ADUser -Identity alice.andersson -Properties Enabled, Department, Manager, DistinguishedName
Get-ADPrincipalGroupMembership alice.andersson | Select-Object Name
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SamAccountName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DisabledUsersOu = 'OU=Disabled Users,OU=Corp',

    [Parameter()]
    [switch]$ClearDepartment,

    [Parameter()]
    [switch]$ClearManager
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        throw "The ActiveDirectory module is required to run this script. $_"
    }
}

process {
    try {
        $domain = Get-ADDomain
    }
    catch {
        throw "Unable to query the current Active Directory domain. $_"
    }

    $disabledUsersOuDn = '{0},{1}' -f $DisabledUsersOu, $domain.DistinguishedName
    Write-Verbose "Resolved disabled users OU: $disabledUsersOuDn"

    $user = Get-ADUser -Identity $SamAccountName -Properties Department, Manager, DistinguishedName, MemberOf, PrimaryGroupId -ErrorAction SilentlyContinue
    if (-not $user) {
        throw "No Active Directory user was found with SamAccountName '$SamAccountName'."
    }

    $null = Get-ADOrganizationalUnit -Identity $disabledUsersOuDn -ErrorAction Stop

    $groupsToRemove = @(Get-ADPrincipalGroupMembership -Identity $user |
        Where-Object {
            $_.Name -ne 'Domain Users' -and
            $_.DistinguishedName -notlike 'CN=Denied RODC Password Replication Group,*'
        })

    $attributeCleanup = @()
    if ($ClearDepartment) {
        $attributeCleanup += 'Department'
    }
    if ($ClearManager) {
        $attributeCleanup += 'Manager'
    }

    Write-Verbose "User distinguished name: $($user.DistinguishedName)"
    Write-Verbose "Groups selected for removal: $($groupsToRemove.Name -join ', ')"
    Write-Verbose "Attributes selected for cleanup: $($attributeCleanup -join ', ')"

    if ($PSCmdlet.ShouldProcess($SamAccountName, 'Disable account, remove non-default group memberships, and move to disabled users OU')) {
        try {
            Disable-ADAccount -Identity $user

            foreach ($group in $groupsToRemove) {
                Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
            }

            if ($ClearDepartment -or $ClearManager) {
                $clearParameters = @{}
                if ($ClearDepartment) {
                    $clearParameters['Clear'] = @('Department')
                }

                if ($ClearManager) {
                    if ($clearParameters.ContainsKey('Clear')) {
                        $clearParameters['Clear'] += 'Manager'
                    }
                    else {
                        $clearParameters['Clear'] = @('Manager')
                    }
                }

                Set-ADUser -Identity $user @clearParameters
            }

            Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledUsersOuDn
        }
        catch {
            throw "Failed to offboard user '$SamAccountName'. $_"
        }

        Write-Verbose "Disabled user '$SamAccountName'."
        Write-Verbose "Moved user '$SamAccountName' to '$disabledUsersOuDn'."

        [pscustomobject]@{
            SamAccountName    = $SamAccountName
            DisabledUsersOu   = $disabledUsersOuDn
            RemovedGroups     = @($groupsToRemove.Name)
            ClearedAttributes = $attributeCleanup
            Verification      = "Run: Get-ADUser -Identity $SamAccountName -Properties Enabled, Department, Manager, DistinguishedName; Get-ADPrincipalGroupMembership $SamAccountName | Select-Object Name"
        }
    }
}
