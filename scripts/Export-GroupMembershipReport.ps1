<#
.SYNOPSIS
Exports Active Directory group membership data for access review.

.DESCRIPTION
This script collects group membership information from Active Directory and returns a readable report
for access review in the corp.local lab. It can target a single group, all baseline department groups,
or privileged groups only. Results may be written to the pipeline or exported to CSV.

.PARAMETER GroupName
The name of a specific Active Directory group to report on.

.PARAMETER IncludeDepartmentGroups
Includes the baseline department groups defined for the lab.

.PARAMETER PrivilegedOnly
Reports on privileged groups only.

.PARAMETER OutputPath
Optional path for a CSV export of the report.

.EXAMPLE
.\Export-GroupMembershipReport.ps1 -GroupName GG_HR_Users

.EXAMPLE
.\Export-GroupMembershipReport.ps1 -PrivilegedOnly -OutputPath .\reports\privileged-groups.csv

.NOTES
Purpose: Export group membership information for access review and verification.
Inputs: A specific group name, a report mode, and an optional export path.
What it changes: No directory changes. This script reads AD data and can write a report file.
Safety controls: Read-only behavior, input validation, duplicate group handling, and verbose output.
Example usage: See examples above.
Verification:
Get-ADGroupMember -Identity GG_HR_Users
Import-Csv .\reports\privileged-groups.csv
#>
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'SpecificGroup', Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupName,

    [Parameter(ParameterSetName = 'DepartmentGroups', Mandatory)]
    [switch]$IncludeDepartmentGroups,

    [Parameter(ParameterSetName = 'PrivilegedGroups', Mandatory)]
    [switch]$PrivilegedOnly,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $selectedParameterSet = $PSCmdlet.ParameterSetName

    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        throw "The ActiveDirectory module is required to run this script. $_"
    }

    $departmentGroups = @(
        'GG_HR_Users',
        'GG_Finance_Users',
        'GG_IT_Users',
        'GG_Operations_Users'
    )

    $privilegedGroups = @(
        'GG_IT_Admins'
    )

    function Resolve-ReportGroups {
        [CmdletBinding()]
        param()

        switch ($selectedParameterSet) {
            'SpecificGroup' {
                return @($GroupName)
            }
            'DepartmentGroups' {
                return $departmentGroups
            }
            'PrivilegedGroups' {
                return $privilegedGroups
            }
            default {
                throw 'A report mode must be selected.'
            }
        }
    }
}

process {
    $targetGroups = Resolve-ReportGroups | Sort-Object -Unique
    $reportRows = foreach ($targetGroup in $targetGroups) {
        Write-Verbose "Collecting membership for group '$targetGroup'."

        $group = Get-ADGroup -Identity $targetGroup -ErrorAction Stop
        $members = @(Get-ADGroupMember -Identity $group -Recursive:$false -ErrorAction Stop)

        if (-not $members) {
            [pscustomobject]@{
                GroupName          = $group.Name
                GroupCategory      = if ($privilegedGroups -contains $group.Name) { 'Privileged' } else { 'Standard' }
                MemberName         = $null
                SamAccountName     = $null
                Department         = $null
                Enabled            = $null
                ObjectClass        = $null
                DistinguishedName  = $null
            }
            continue
        }

        foreach ($member in $members) {
            $memberDetails = $null
            if ($member.objectClass -eq 'user') {
                $memberDetails = Get-ADUser -Identity $member.DistinguishedName -Properties Department, Enabled -ErrorAction Stop
            }

            [pscustomobject]@{
                GroupName         = $group.Name
                GroupCategory     = if ($privilegedGroups -contains $group.Name) { 'Privileged' } else { 'Standard' }
                MemberName        = $member.Name
                SamAccountName    = if ($memberDetails) { $memberDetails.SamAccountName } else { $null }
                Department        = if ($memberDetails) { $memberDetails.Department } else { $null }
                Enabled           = if ($memberDetails) { $memberDetails.Enabled } else { $null }
                ObjectClass       = $member.objectClass
                DistinguishedName = $member.DistinguishedName
            }
        }
    }

    if ($OutputPath) {
        $outputDirectory = Split-Path -Path $OutputPath -Parent
        if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }

        $reportRows | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Verbose "Exported report to '$OutputPath'."
    }

    $reportRows
}
