"+------------------------------------+"
"|   BaShD Script                     |"
"|   Language: MS PowerShell v2       |"
"|   Version: v0.3.4-20130210         |"
"|   Author: Matthias Link            |"
"|                                    |"
"+------------------------------------+"

#Error for non defined variables
Set-StrictMode -Version 2

#Important Variables - Please adjust!!!
#---
$sLogFile = "C:\robocopy.txt"

#Following variables define CIFS-ressource, user to connect and password
$sServerBackupDir = "\\server\home" #\\<CIFS-server>\<CIFS-share>
$sServerUser = $env:username #$env:username for environment variable
$sServerPassword = "*" #"*" for prompt

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
    ) #Create of Array for source-directories. An array with @() may have 0,1 or n elements  }
  }
  {$_ -eq "MATTHIAS"} {
    $sSourceDir = @(
      "C:\Users\matthiaslink\Desktop", #Pfad zu den Dateien auf dem Desktop
      "D:\Users\matthiaslink" #Pfad zu den eigenen Dateien
    ) #Create of Array for source-directories. An array with @() may have 0,1 or n elements  }
  }
  {$_ -eq "PoaB"} {
    $sSourceDir = @(
      "E:\Users\matthiaslink\Documents\My Books\Reader", #Pfad zu eBook Dateien
      "E:\Users\matthiaslink\Documents\Programmdateien" #Pfad zu spezifischen Programmdaeien
      #"C:\Documents and Settings\Matthias\Desktop", #Pfad zu den Dateien auf dem Desktop
      #"C:\Documents and Settings\Matthias\My Documents" #Pfad zu den eigenen Dateien
      #"D:\users\zp16884", #Pfad zu den eigenen Dateien
      #"C:\Dokumente und Einstellungen\zp16884\Favoriten", #Pfad zu den IE Favoriten
      #"C:\Dokumente und Einstellungen\zp16884\Anwendungsdaten\Microsoft\Signatures", #Pfad zu den Signaturen (Outlook)
      #"C:\Dokumente und Einstellungen\zp16884\Anwendungsdaten\Microsoft\Internet Explorer\Quick Launch", #Pfad zu den Shortcuts (Quick Launch Leiste Win)
      #"C:\Dokumente und Einstellungen\zp16884\Anwendungsdaten\Windows Desktop Search", #Pfad zu den Desktop Shortcuts der Windows Search Anwendung
      #"C:\Dokumente und Einstellungen\All Users\Anwendungsdaten\Microsoft\Search" #Pfad zum Windows Search Index
    ) #Create of Array for source-directories. An array with @() may have 0,1 or n elements
  }
  default {
    $sSourceDir =@() #No valid configuration - so empty sSourceDir
  }
}
#Target Directory is fixed and connected network drive + computername + yyyymm
$sTargetRootDir = "$sServerBackupDir\backup"
#$sTargetRootDir = "V:\backup" #Path without ending "\"
#---

#---
#Please do not change from this line downwards if you do not know what you do
#---

## Functions
function Use-RunAs 
{    
    # Check if script is running as Adminstrator and if not use RunAs 
    # Use Check Switch to check if admin 
    # For reference see: http://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
     
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }     
 
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
        {  
            try 
            {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Error - Failed to restart script with runas"  
                break               
            } 
            exit # Quit this session of powershell 
        }  
    }  
    else  
    {  
        Write-Warning "Error - Script must be saved as a .ps1 file first"  
        break  
    }  
} 

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
  Write-Host ("Shutdown and Sleep-Well Script v0.3.3-20120906")
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

function Test-BaShDEnv {
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
    #return = 0ge
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
  #Return Set-Returncode $iError
  if ( ( set-returncode $iError ) -eq 1 ) {
    Write-Host "`nTest-ScriptEnv failed!!!" -BackgroundColor red -ForegroundColor white
    #Pausing an script until user pressed a key snippet from MS TechNet (http://technet.microsoft.com/en-us/library/ff730938.aspx)
    Write-Host "`nPress any key to continue ..."
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") #NoEcho and $x prevent from showing information on screen, IncludeKeyDown continues just when pressing a key
    exit #Quits script andgeet- powershell
  }
  
}


##Main-Script

Start-Transcript ( $sLogFile +"2" )

Use-RunAs #Make sure that script runs with admin priviledges (see function)
#net use v: /delete
#net use v: $sServerBackupDir $sServerPassword /user:$sServerUser
#Get-PSDrive

#Define final target directory
$sTargetSubDirCompName = $env:computername
$sTargetSubDirTimestamp = get-date -uformat %Y%m #Aktuelles Jahr/Monat abfragen; für kompletten Zeitstempel %Y%m%d%H%M%S
$sTargetDir = $sTargetRootDir + "\" +$sTargetSubDirCompName + "\" + $sTargetSubDirTimestamp

#Show Information what parameters are set
Show-SkriptParameter

#Testing Scripting Environment and validity of parameters
Test-BaShDEnv

$sShutdownSelection = Read-Host "[Y] Shutdown and backup files or [N] Shutdown only?"
if ( $sShutdownSelection -eq "Y" ) {
 Write-Debug "Locking Workstation..."
 #Lock-Workstation
}      

Write-Host "`n---Start Processing---"

#Creat subdirectories if necessary
if ( ( Test-Path -Path ( $sTargetRootDir + "\" +$sTargetSubDirCompName ) ) -eq $False ) {
  #Create Path with computername in backup-directory
  Write-Host "Create subdirectory $sTargetSubDirCompName in $sTargetRootDir"
  New-Item -path $sTargetRootDir -name $sTargetSubDirCompName -type directory 
}

#Incremental copy logic
if ( ( Test-Path -Path $sTargetDir ) -eq $False ) {
  #Create path in Backup-Root-Directory
  Write-Host "Create subdirectory $sTargetSubDirTimestamp in $sTargetRootDir\$sTargetSubDirCompName"
  #mkdir $sTargetDir
  new-item -path ( $sTargetRootDir + "\" +$sTargetSubDirCompName ) -name $sTargetSubDirTimestamp -type directory
  #Inital Copy-Process for a month (Archiv-Flag will be ignored)
  #Out-Host ist experimental (see S.258 PSB)
  Write-Host "Execute Initial Copy Process..."
  foreach ($element in $sSourceDir) {
    robocopy.exe $element ( $sTargetDir + "\" + $element.Replace( ":", "") ) /S /ZB /PURGE /R:10 /W:10 /NP /LOG+:$sLogFile /TEE /V | Out-Host #/L letzter Param für Tests
  }
}
else {
  #Regular Copy-Process during month (pay attention to Archiv-Flag and reset in source)
  #Out-Host ist experimental (see S.258 PSB)
  Write-Host "Execute Regular Copy Process..."
  foreach ($element in $sSourceDir) {
    robocopy.exe $element ( $sTargetDir + "\" + $element.Replace( ":", "") ) /S /ZB /PURGE /R:10 /W:10 /NP /LOG+:$sLogFile /TEE /V /M | Out-Host #/L letzter Param für Tests
    #Parameter /M -> Copy only files with archive attribute set and turn off in source
  }
}

#Cleanup backup-directory process
Write-Host "Cleanup Backup Directory $sTargetRootDir\$sTargetSubDirCompName ..."
Write-Host $sTargetSubDirTimestamp
Write-Host ( Get-Childitem ( $sTargetRootDir + "\" +$sTargetSubDirCompName ) )
#Select directories older than t-1 month and save in array $aOldSubDir (Array include Objects -> .name)
Write-Host "jetzt wirds komploex"
$aOldSubDir = Get-Childitem H:\backup\WINXP-DEVELOPER | select-object name | sort-object name | where-object {$_.name -lt ( get-date -uformat %Y%m ) -1 }
 $aOldSubDir
 $aOldSubDir | Select-Object name | Out-String -Stream | ForEach-Object { $_.ToString().Length }
 #$aOldSubDir | Select-Object name | Out-String -Stream | get-member

Stop-Transcript

if ( $sShutdownSelection -eq "Y" ) {
  #(Get-WmiObject -Class Win32_OperatingSystem -ComputerName .).Win32Shutdown(1)
  #shutdown -s -f
  stop-computer
}

