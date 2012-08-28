BaShD
=====

Backup &amp; Shutdown Script for Windows (Powershell 2.0)

##Presumptions
* Installed Robocopy<br>see Microsoft Downloads
* Installed Powershell 2.0<br>see `$PSVersionTable.PSVersion`
* Copy .ps1 in a local file folder
* Check if execution of scripts is allowed with Get-ExecutionPolicy<br>You can change with `Set-ExecutionPolicy RemoteSigned -Confirm`

## Manual
This is a first experimental release. It just do all necessary environment checks and copies all necessary files monthly in a seperate folder.

Please make sure that you adjust the parameters in the script for your environment.

## To-Dos
* copy process paying attention to archive flag (existing month)
* remove ugly percentage progress
* improve logging feature
* do some manual improvement and coding documentation
* deletion of long term (1/2y), running and short term archive(1m)
* ini file and or registry (thinking about different pros/cons)
* installation script

## License (BaShD)

	Copyright 2012 Matthias Link. 

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.