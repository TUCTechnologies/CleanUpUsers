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
$EnabledPCs = Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan $Timespan

 
##Used for testing on a single system.Replace Investigations with any PC name and remove the ## in front of the next line. That will enable targeting only that system.
##$EnabledPCs = $EnabledPCs | ?{$_.Name -eq "Investigations"}
##
$TooLongSinceLogon = $EnabledPCs | ?{$_.LastLogonDate -lt $OldDate} 


#Main Body:
Try
    {
        If((Test-Path -Path $OutputFileLocation) -eq $false)
            {
                Write-Host "Output file location incorrect, please try again." -ForegroundColor Yellow
                New-Item -Path $OutputFileLocation -ItemType Directory
            }
        else #It's Working
            {
                Write-host "Not Borked. Check the CSV when complete." -ForegroundColor Green
                $TooLongSinceLogon |Select-Object Name, DistinguishedName, LastLogonDate| Sort-Object LastLogonDate| Export-Csv -Path $OutputFileLocationPlusName -Force -NoTypeInformation
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
    Catch #If it all goes haywire 
    {
        Write-Host "Generic error caught." -ForegroundColor Red        
    }
