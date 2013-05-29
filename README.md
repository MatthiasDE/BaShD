BaShD
=====

Backup &amp; Shutdown Script for Windows (Powershell >=2.0)

##Use at your own risk!
This is a beta release with not all implemented features.

##Presumptions
* Installed Robocopy<br>see Microsoft Downloads
* Installed Powershell 2.0 or 3.0<br>see `$PSVersionTable.PSVersion`
* Copy .ps1 in a local file folder
* Check if execution of scripts is allowed with Get-ExecutionPolicy<br>You can change with `Set-ExecutionPolicy RemoteSigned -Confirm`

##Tested Windows Versions
* Windows XP
* Windows Vista
* Windows 7
* Windows 8

##Features
* Checks necessary environment and presumptions mentioned above
* Copies all defined folders and files in seperate folders
* Supports different systems over network via one central skript (including configuration)
* Copy process paying attention to archive flag (in existing month)
* Creates one new full archive for new month
* File based copy log
* Documented coding
* Self-calling with higher user rights due to UAC (User Account Control) on Windows 7 and 8

Please make sure that you adjust the parameters in the script for your environment.

## To-Dos
* deletion of long term (1/2y), running and short term archive(1m)
* ini file and or registry (thinking about different pros/cons)
* installation script

## License (BaShD)

	Copyright 2013 Matthias Link. 

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
