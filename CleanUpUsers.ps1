
<#
Requirements:
Active Directory module or run from DC
#>

#User Variables: 
$FileLocation = Get-Location
$OutputFileLocation = "."
$OutputFileName = "\users.csv"
[INT]$OverThisManyDays = 90
$TargetOU = "" #This has to be the OUs distinguished name

#Script Variables:
$TodaysDate = (Get-Date)
$OldDate = $TodaysDate.AddDays(-($OverThisManyDays))
$Timespan = "$OverThisManyDays" + ":00:00:00"

# Types of objects to review
$EnabledUsers = Get-ADUser -Filter * -Properties employeeType, LastLogonDate | where employeeType -eq "user" | where enabled -eq $true
$EnabledServiceAccounts = Get-ADUser -Filter * -Properties employeeType, LastLogonDate | where employeeType -eq "service" | where enabled -eq $true
$EnabledNoType = Get-ADUser -Filter * -Properties employeeType, LastLogonDate | where employeeType -eq $null | where enabled -eq $true
$PasswordNoExpire = Get-ADUser -filter * -properties SamAccountName, Name, PasswordNeverExpires, Enabled, employeeType | where {$_.passwordNeverExpires -eq "true" -And $_.Enabled -eq "True" -And $_.employeeType -eq "user" } |  Select-Object DistinguishedName,Name,Enabled,SamAccountName

# Set user accounts to not expire
#Get-ADUser -filter * -properties SamAccountName, Name, PasswordNeverExpires, Enabled, employeeType | where {$_.passwordNeverExpires -eq "true" -And $_.Enabled -eq "True" -And $_.employeeType -eq "user" } |  Select-Object DistinguishedName,Name,Enabled,SamAccountName | ForEach-Object {Set-ADUser -Identity $_.SamAccountName -PasswordNeverExpires:$FALSE}

# These need to match positions
$ObjectTypes = @($EnabledUsers,$EnabledServiceAccounts,$EnabledNoType, $PasswordNoExpire)
$OutputFiles = @(".\users.csv",".\services.csv",".\notype.csv",".\users-not-expired")

Try {
	For ($i=0; $i -lt $ObjectTypes.length; $i++) {
		Write-Host "CSV file generated -" $OutputFiles[$i] -ForegroundColor Green
		$ObjectTypes[$i] | ?{$_.LastLogonDate -lt $OldDate} |Select-Object Name, DistinguishedName, LastLogonDate| Sort-Object LastLogonDate| Export-Csv -Path $OutputFiles[$i] -Force -NoTypeInformation
			#Be real careful here:
			#Delete the # at the end of the next line if you want to disable the systems found.
			<#
			ForEach ($oldsystem in $TooLongSinceLogon)
			{
				Write-host ""$oldsystem" is being disabled" -ForegroundColor Yellow
				$UserDN = (Get-ADUser -Identity $_.SamAccountName).distinguishedName
				Get-ADComputer "$oldsystem"| Set-ADComputer -Enabled $False
				Move-ADObject -Identity $UserDN -TargetPath $TargetOU -WhatIf
				Write-Host ""$oldsystem" is disabled" -ForegroundColor Green
			}
			#>
			##Stop being careful here:	
	}
}
Catch {
	Write-Host "Generic error caught." -ForegroundColor Red        
}
