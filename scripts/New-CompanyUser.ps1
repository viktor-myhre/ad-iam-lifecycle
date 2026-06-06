<#
.SYNOPSIS
Creates a new Active Directory user account in the correct department OU and adds the user to a baseline department group.

.DESCRIPTION
This script provisions a standard user account for the corp.local lab. It derives a SamAccountName and
UserPrincipalName from the supplied first and last name, places the account in the correct department OU,
sets common identity attributes, and adds the user to the baseline department security group.

The script is designed for lab use and emphasizes clarity, repeatability, and safe execution through
SupportsShouldProcess and -WhatIf.

.PARAMETER FirstName
The user's given name.

.PARAMETER LastName
The user's surname.

.PARAMETER Department
The user's department. Supported values are IT, HR, Finance, and Operations.

.PARAMETER InitialPassword
The initial password to assign to the account as a SecureString.

.PARAMETER DomainDnsName
The domain DNS name used when building the user principal name. If omitted, the current AD domain DNS root is used.

.EXAMPLE
$Password = Read-Host "Enter initial password" -AsSecureString
.\New-CompanyUser.ps1 -FirstName Alice -LastName Andersson -Department HR -InitialPassword $Password -WhatIf

.EXAMPLE
$Password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
.\New-CompanyUser.ps1 -FirstName David -LastName Berg -Department Finance -InitialPassword $Password -Verbose

.NOTES
Purpose: Provision a new standard user account in the correct OU and baseline department group.
Inputs: First name, last name, department, and initial password.
What it changes: Creates an AD user account and updates group membership.
Safety controls: SupportsShouldProcess, input validation, duplicate account checks, and prerequisite validation.
Example usage: See examples above.
Verification:
Get-ADUser -Identity alice.andersson -Properties Department, Enabled, DistinguishedName
Get-ADPrincipalGroupMembership alice.andersson | Select-Object Name
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$FirstName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$LastName,

    [Parameter(Mandatory)]
    [ValidateSet('IT', 'HR', 'Finance', 'Operations')]
    [string]$Department,

    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [System.Security.SecureString]$InitialPassword,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DomainDnsName
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

    function Convert-ToAccountToken {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Value
        )

        $normalizedValue = $Value.Normalize([Text.NormalizationForm]::FormD)
        $builder = New-Object System.Text.StringBuilder

        foreach ($character in $normalizedValue.ToCharArray()) {
            $unicodeCategory = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($character)
            if ($unicodeCategory -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
                [void]$builder.Append($character)
            }
        }

        return (($builder.ToString() -replace '[^a-zA-Z0-9.-]', '').ToLowerInvariant())
    }

    $departmentOuMap = @{
        IT         = 'OU=IT,OU=Users,OU=Corp'
        HR         = 'OU=HR,OU=Users,OU=Corp'
        Finance    = 'OU=Finance,OU=Users,OU=Corp'
        Operations = 'OU=Operations,OU=Users,OU=Corp'
    }

    $departmentGroupMap = @{
        IT         = 'GG_IT_Users'
        HR         = 'GG_HR_Users'
        Finance    = 'GG_Finance_Users'
        Operations = 'GG_Operations_Users'
    }
}

process {
    $normalizedFirstName = Convert-ToAccountToken -Value $FirstName
    $normalizedLastName = Convert-ToAccountToken -Value $LastName

    if ([string]::IsNullOrWhiteSpace($normalizedFirstName) -or [string]::IsNullOrWhiteSpace($normalizedLastName)) {
        throw 'FirstName and LastName must contain at least one alphanumeric character after normalization.'
    }

    $displayName = '{0} {1}' -f $FirstName.Trim(), $LastName.Trim()
    $samAccountName = '{0}.{1}' -f $normalizedFirstName, $normalizedLastName

    try {
        $domain = Get-ADDomain
    }
    catch {
        throw "Unable to query the current Active Directory domain. $_"
    }

    if (-not $PSBoundParameters.ContainsKey('DomainDnsName')) {
        $DomainDnsName = $domain.DnsRoot
    }

    $userPrincipalName = '{0}@{1}' -f $samAccountName, $DomainDnsName
    $searchBase = '{0},{1}' -f $departmentOuMap[$Department], $domain.DistinguishedName
    $departmentGroup = $departmentGroupMap[$Department]

    Write-Verbose "Resolved department OU: $searchBase"
    Write-Verbose "Resolved baseline group: $departmentGroup"
    Write-Verbose "Resolved SamAccountName: $samAccountName"
    Write-Verbose "Resolved UserPrincipalName: $userPrincipalName"

    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
    if ($existingUser) {
        throw "A user with SamAccountName '$samAccountName' already exists."
    }

    $null = Get-ADOrganizationalUnit -Identity $searchBase -ErrorAction Stop
    $null = Get-ADGroup -Identity $departmentGroup -ErrorAction Stop

    $newUserParameters = @{
        Name                  = $displayName
        GivenName             = $FirstName.Trim()
        Surname               = $LastName.Trim()
        DisplayName           = $displayName
        SamAccountName        = $samAccountName
        UserPrincipalName     = $userPrincipalName
        Department            = $Department
        AccountPassword       = $InitialPassword
        Enabled               = $true
        ChangePasswordAtLogon = $true
        Path                  = $searchBase
    }

    if ($PSCmdlet.ShouldProcess($samAccountName, "Create Active Directory user and add to $departmentGroup")) {
        try {
            New-ADUser @newUserParameters
            Add-ADGroupMember -Identity $departmentGroup -Members $samAccountName
        }
        catch {
            throw "Failed to provision user '$samAccountName'. $_"
        }

        Write-Verbose "Created user '$samAccountName' in '$searchBase'."
        Write-Verbose "Added user '$samAccountName' to '$departmentGroup'."

        [pscustomobject]@{
            SamAccountName    = $samAccountName
            UserPrincipalName = $userPrincipalName
            Department        = $Department
            TargetOu          = $searchBase
            BaselineGroup     = $departmentGroup
            Verification      = "Run: Get-ADUser -Identity $samAccountName -Properties Department, Enabled, DistinguishedName; Get-ADPrincipalGroupMembership $samAccountName | Select-Object Name"
        }
    }
}
