"+------------------------------------+"
"|   BaShD Script                     |"
"|   Language: MS PowerShell v2       |"
"|   Version: v0.3.1-20120821         |"
"|   Author: Matthias Link            |"
"|                                    |"
"+------------------------------------+"

#Error for non defined variables
Set-StrictMode -Version 2

#Important Variables - Please adjust!!!
#---
$sLogFile = "C:\robocopy.txt"

#Follwing Variables are defined to find out if we are in right environment (LAN connection, right router, server online)
$sIntranetMask = "192.168.1.*"
$sDNSDomain = "fritz.box" #Router identifier
$sServerIP = "192.168.1.100" #This and next are used to validate server with nslookup
$sServerName ="server"

#Select Source Directory dependent from Computername
switch($env:computername) {
  {$_ -eq "WINXP-DEVELOPER"} {
    $sSourceDir = @(
      "C:\Documents and Settings\Matthias\Desktop", #Pfad zu den Dateien auf dem Desktop
      "C:\Documents and Settings\Matthias\My Documents" #Pfad zu den eigenen Dateien
      #"D:\users\zp16884", #Pfad zu den eigenen Dateien
      #"C:\Dokumente und Einstellungen\zp16884\Favoriten", #Pfad zu den IE Favoriten
      #"C:\Dokumente und Einstellungen\zp16884\Anwendungsdaten\Microsoft\Signatures", #Pfad zu den Signaturen (Outlook)
      #"C:\Dokumente und Einstellungen\zp16884\Anwendungsdaten\Microsoft\Internet Explorer\Quick Launch", #Pfad zu den Shortcuts (Quick Launch Leiste Win)
      #"C:\Dokumente und Einstellungen\zp16884\Anwendungsdaten\Windows Desktop Search", #Pfad zu den Desktop Shortcuts der Windows Search Anwendung
      #"C:\Dokumente und Einstellungen\All Users\Anwendungsdaten\Microsoft\Search" #Pfad zum Windows Search Index
    ) #Anlage eines Arrays für die Source-Directories. Mit @() kann es 0,1 oder n Elemente haben.
  }
  default {
    $sSourceDir =@() #No valid configuration - so empty sSourceDir
  }
}
#Target Directory is fixed and connected network drive + computername + yyyymm
$sTargetRootDir = "H:\backup" #Path without ending "\"
#---

#---
#Please do not change from this line downwards if you do not know what you do
#---

## Functions
function Lock-Workstation {
  rundll32.exe user32.dll,LockWorkStation
}

function Set-Returncode($iInput) {
  if ( $iInput -ne 0 ) {
    return 1
  }
  else {
    return 0
  }
}

function Show-SkriptParameter {
  Write-Host "`n---Script Runtime Information---"
  #Write-Output ("BaShD Backup & Shutdown Script v0.3.1-20120821") | Out-File -FilePath $sLogFile -Width 2147483647
  Write-Host ("Shutdown and Sleep-Well Script v0.3.1-20120819")
  Write-Host ("Skript Start Time:", ( get-date -uformat %Y%m%d%H%M%S ) )  
  Write-Host -NoNewLine "Source Directories:"
  # List of array "sSourceDir" with element in new line and "," as divider
  $i = 1
  foreach($element in $sSourceDir) {
    Write-Host -NoNewLine " $element"
    if ($i -ne $sSourceDir.Count) {
      Write-Host ", "
    }
    else {
      Write-Host ""
    }
    $i++
  }
Write-Host "Target Directory: $sTargetDir" #Variblen in Texten werden durch Inhalt ersetzt
Write-Host "Intranet Address Room: $sIntranetMask"
Write-Host "Intranet DNS: $sDNSDomain"
Write-Host "Backup-Server Name: $sServerName"
Write-Host "Backup-Server IP: $sServerIP"
Write-Host "Output Log-File: $sLogFile"
}

function Test-ScriptEnv {
  $iError = 0
  Write-Host "`n---Testing Script Environment---"
  
  #Check LAN connectivity
  Write-Host -NoNewLine "Expected LAN connectivit  "
  try {
    #Auswerten der Netzwerkadapter mit IP-Adresse
    $sLanInformation = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object -FilterScript {$_.IPAddress -like $sIntranetMask}
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    if ( $sLanInformation.DNSDomain -eq $sDNSDomain ) {
      Write-Host -NoNewLine "Check Domain  "
      Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    }
    else {
      Write-Host "Failed" -BackgroundColor red -ForegroundColor white
      Return 1
    }
  }
  catch {
    Write-Host "Failed" -BackgroundColor red -ForegroundColor white
    Return 1
  }
  
  #Source Directories set
  Write-Host -NoNewLine "Configured Source Directories  "
  if ($sSourceDir.Count -eq 0) {
    Write-Host "Failed" -BackgroundColor red -ForegroundColor white
    #return = 1
    $iError =+ 1
  }
  else {
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    #return = 0
  }
  
  #Target Directory accessable
  Write-Host -NoNewLine "Accessable Target Directory  "
  if ( ( Test-Path -Path $sTargetRootDir ) -ne $True ) {
    Write-Host "Failed" -BackgroundColor red -ForegroundColor white
    #return = 1
    $iError =+ 1
  }
  else {
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    #return = 0
  }
 
  #Generate Testfile
  Write-Host -NoNewLine "Generate Test-File  "
  try {
    Write-Output "Don't be afraid. You can delete this file." | Out-File "$sTargetRootDir\bashdtest.tmp"
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    #return = 0
   }
  catch {
    Write-Host "Failed" -BackgroundColor red -ForegroundColor white
    #return = 1
    $iError =+ 1
  }
  
  #Robocopy Test
  Write-Host -NoNewLine "Robocopy Test-Copy  "
  try {
    robocopy "$sTargetDir\bashdtest.tmp" "$sTargetDir\bashdtest.copy.tmp" >$null
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    #return = 0
  }  
  catch {
    Write-Host "Failed" -BackgroundColor red -ForegroundColor white
    #return = 1
    $iError =+ 1
  }
  
  #Delete temporary generated Files for above mentioned tests; surpress error messages
  Write-Debug "Delete testfile: $sTargetRootDir\bashdtest.tmp"
  Remove-Item "$sTargetRootDir\bashdtest.tmp" -ErrorAction SilentlyContinue
  Write-Debug "Delete copied testfile: $sTargetRootDir\bashdtest.copy.tmp"
  Remove-Item "$sTargetRootDir\bashdtest.copy.tmp" -ErrorAction SilentlyContinue

  #Test Network Environment
  #Existent Backup Server with .NET Class - see http://msdn.microsoft.com/en-us/library/system.net.dns(v=vs.100)
  Write-Host -NoNewLine "Nslookup to Server  "
  try {
    $sNslookup = ( [system.net.dns]::GetHostAddresses($sServerName) | Select-Object IPAddressToString ) #.Net Method for doing nslookup to given Server in $sServer
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    #return = 0
  }
  catch {
    Write-Host "Failed" -BackgroundColor green -ForegroundColor white
    #return = 1
    $iError =+ 1
  }
  
  #Compare result if it contains expected IP-Address
  Write-Host -NoNewLine "CIFS Server Name to IP-Address  "
  if ( ( $sNslookup ) -like "*$sServerIP*" -eq $True ) {
    Write-Host "Passed" -BackgroundColor green -ForegroundColor white
    #return = 0
  }
  else {
    Write-Host "Failed" -BackgroundColor red -ForegroundColor white
    #return = 1
    $iError =+ 1
  }
  
  #In case of an Error exit function now with returncode 1. Return 0 if no error.
  Return Set-Returncode $iError
  
}


##Main-Script

#Define final target directory
$sTargetSubDirCompName = $env:computername
$sTargetSubDirTimestamp = get-date -uformat %Y%m #Aktuelles Jahr/Monat abfragen; für kompletten Zeitstempel %Y%m%d%H%M%S
$sTargetDir = $sTargetRootDir + "\" +$sTargetSubDirCompName + "\" + $sTargetSubDirTimestamp

#Show Information what parameters are set
Show-SkriptParameter

#Testing Scripting Environment and validity of parameters
Test-ScriptEnv

$sShutdownSelection = Read-Host "[Y] Shutdown and backup files or [N] Shutdown only?"
if ( $sShutdownSelection -eq "Y" ) {
 Write-Debug "Lock Workstation"
 Lock-Workstation
}      

Write-Host "`n---Start Processing---"

#Creat subdirectories if necessary
if ( ( Test-Path -Path ( $sTargetRootDir + "\" +$sTargetSubDirCompName ) ) -eq $False ) {
  #Create Path with computername in backup-directory
  Write-Host "Create subdirectory $sTargetSubDirCompName in $sTargetRootDir"
  New-Item -path $sTargetRootDir -name $sTargetSubDirCompName -type directory 
}
    
if ( ( Test-Path -Path $sTargetDir ) -eq $False ) {
  #Pfad im Backupverzeichnis anlegen
  Write-Host "Create subdirectory $sTargetSubDirTimestamp in $sTargetRootDir\$sTargetSubDirCompName"
  new-item -path ( $sTargetRootDir + "\" +$sTargetSubDirCompName ) -name $sTargetSubDirTimestamp -type directory
  #mkdir $sTargetDir
  #Initialen Kopiervorgang durchführen (Archiv-Flag wird nicht berücksichtigt)
  foreach ($element in $sSourceDir) {
    robocopy.exe $element ( $sTargetDir + "\" + $element.Replace( ":", "") ) /S /ZB /PURGE /M /LOG+:$sLogFile /TEE /V #/L letzter Param für Tests
  }
}    

<#
#Kopiervorgang durchführen (Archiv-Flag berücksichtigt und in Quelle zurückgesetzt)
foreach ($element in $sSourceDir) {
  #robocopy.exe $element ( $sTargetDir + "\" + $element.Replace( ":", "") ) /S /ZB /PURGE /M /LOG+:$sLogFile /TEE /V /M #/L letzter Param für Tests
  #Parameter /M -> Copy only files with archive attribute set and turn off in source
}
#>

if ( $sShutdownSelection -eq "Y" ) {
  #(Get-WmiObject -Class Win32_OperatingSystem -ComputerName .).Win32Shutdown(1)
  #shutdown -s -f
}

