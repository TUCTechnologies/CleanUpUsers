
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
$OutputFileLocationPlusName = $OutputFileLocation + $OutputFileName
$TodaysDate = (Get-Date)
$OldDate = $TodaysDate.AddDays(-($OverThisManyDays))
$Timespan = "$OverThisManyDays" + ":00:00:00"
$EnabledUsers = Get-ADUser -Filter * -Properties employeeType, LastLogonDate | where employeeType -eq "user" | where enabled -eq $true
$EnabledNoType = Get-ADUser -Filter * -Properties employeeType, LastLogonDate | where employeeType -eq $null | where enabled -eq $true
$OverLimitTime = (get-date).adddays(-90)

# These need to match positions
$ObjectTypes = @($EnabledUsers,$EnabledNoType)
$OutputFiles = @(".\users.csv",".\notype.csv")
 
#Main Body:
Try {
	For ($i=0; $i -lt $ObjectTypes.length; $i++) {
	
		If((Test-Path -Path $OutputFiles[$i]) -eq $false) {
			Write-Host "Output file location incorrect, please try again." -ForegroundColor Yellow
		}
		Else {
			Write-host "CSV file generated - $OutputFiles[$i]" -ForegroundColor Green
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
}
Catch {
	Write-Host "Generic error caught." -ForegroundColor Red        
}
