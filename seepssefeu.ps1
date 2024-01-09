
<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)

	This file contains a number of functions which, when called, emit partially-machine-generated
	source-code: the source-code emitted when those functions are called
	can alternatively be used under the terms of the BSD Zero Clause License
	(also known as 0BSD, see: https://spdx.org/licenses/0BSD.html) instead of the Boost Software License, Version 1.0;
	those functions are: "New-PowerShellBootstrap"; "New-CMDBootstrapForWindows"; "New-ShellBootstrapForMacOS".
	The text for 0BSD is as follows:
		Copyright (C) 2023 by Harry Gillanders <contact@harrygillanders.com>

		Permission to use, copy, modify, and/or distribute this software for
		any purpose with or without fee is hereby granted.

		THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
		WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
		WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
		AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
		DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
		PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
		ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
		THIS SOFTWARE.
#>


$SEEPSSEFEUConstants = @{
	FileDelineatorPrivateUseAreaStart = [Char] 0xF3BF
	FileDelineatorPrivateUseAreaEnd = [Char] 0xF3EF
	FileDelineatorDefaultLength = 8
}


function New-SEEPSSEFEU (
	$Files,
	[String] $ScriptToRun,
	[String] $DestinationBase,
	[String] $DestinationBootstrapScriptName,
	[String] $TerminalWindowTitle,
	[Switch] $MakeZipInWindowsExplorerFriendlyVersion,
	[UInt32] $DestinationBootstrapFileDepth = 0,
	[String] $PowerShellDirectoryName = 'PowerShell',
	[String] $PowerShellTarballName = '_powershell.tar.gz',
	[Int32] $MinimumPowerShellVersionMajor = 7,
	[Int32] $MinimumPowerShellVersionMinor = 0,
	$PowerShellTarballSourceForX86,
	$PowerShellTarballSourceForARM,
	[Int32] $FileDelineatorLength = $SEEPSSEFEUConstants.FileDelineatorDefaultLength,
	[Char] $FileDelineatorCharacterRangeStart = $SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaStart,
	[Char] $FileDelineatorCharacterRangeEnd = $SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaEnd
)
{
	$FileData = New-SEEPSSEFEUFileData `
		-Files $Files `
		-FileDelineatorLength $FileDelineatorLength `
		-FileDelineatorCharacterRangeStart $FileDelineatorCharacterRangeStart `
		-FileDelineatorCharacterRangeEnd $FileDelineatorCharacterRangeEnd

	New-SEEPSSEFEUForMultiplePlatforms `
		-FileData $FileData `
		-ScriptToRun $ScriptToRun `
		-DestinationBase $DestinationBase `
		-DestinationBootstrapScriptName $DestinationBootstrapScriptName `
		-TerminalWindowTitle $TerminalWindowTitle `
		-MakeZipInWindowsExplorerFriendlyVersion:$MakeZipInWindowsExplorerFriendlyVersion `
		-DestinationBootstrapFileDepth $DestinationBootstrapFileDepth `
		-PowerShellDirectoryName $PowerShellDirectoryName `
		-PowerShellTarballName $PowerShellTarballName `
		-MinimumPowerShellVersionMajor $MinimumPowerShellVersionMajor `
		-MinimumPowerShellVersionMinor $MinimumPowerShellVersionMinor `
		-PowerShellTarballSourceForX86 $PowerShellTarballSourceForX86 `
		-PowerShellTarballSourceForARM $PowerShellTarballSourceForARM
}


function New-SEEPSSEFEUForMultiplePlatforms (
	[PSCustomObject] $FileData,
	[String] $ScriptToRun,
	[String] $DestinationBase,
	[String] $DestinationBootstrapScriptName,
	[String] $TerminalWindowTitle,
	[Switch] $MakeZipInWindowsExplorerFriendlyVersion,
	[UInt32] $DestinationBootstrapFileDepth = 0,
	[String] $PowerShellDirectoryName = 'PowerShell',
	[String] $PowerShellTarballName = '_powershell.tar.gz',
	[Int32] $MinimumPowerShellVersionMajor = 7,
	[Int32] $MinimumPowerShellVersionMinor = 0,
	$PowerShellTarballSourceForX86,
	$PowerShellTarballSourceForARM
)
{
	$Result = [Ordered] @{}

	$WindowsArguments = @{
		FileData = $FileData
		ScriptToRun = $ScriptToRun
		DestinationBase = $DestinationBase
		DestinationBootstrapScriptName = $DestinationBootstrapScriptName
		DestinationBootstrapFileDepth = $DestinationBootstrapFileDepth
		TerminalWindowTitle = $TerminalWindowTitle
	}

	$Result.Windows = New-SEEPSSEFEUForWindows @WindowsArguments

	if ($MakeZipInWindowsExplorerFriendlyVersion)
	{
		$Result.WindowsZipInWindowsExplorerFriendly = New-SEEPSSEFEUForWindows @WindowsArguments -ZipInWindowsExplorerFriendly
	}

	$Result.MacOS = (
		New-SEEPSSEFEUForMacOS `
			-FileData $FileData `
			-ScriptToRun $ScriptToRun `
			-DestinationBase $DestinationBase `
			-DestinationBootstrapScriptName $DestinationBootstrapScriptName `
			-DestinationBootstrapFileDepth $DestinationBootstrapFileDepth `
			-PowerShellDirectoryName $PowerShellDirectoryName `
			-PowerShellTarballName $PowerShellTarballName `
			-MinimumPowerShellVersionMajor $MinimumPowerShellVersionMajor `
			-MinimumPowerShellVersionMinor $MinimumPowerShellVersionMinor `
			-PowerShellTarballSourceForX86 $PowerShellTarballSourceForX86 `
			-PowerShellTarballSourceForARM $PowerShellTarballSourceForARM
	)

	[PSCustomObject] $Result
}


function New-SEEPSSEFEUForWindows (
	[PSCustomObject] $FileData,
	[String] $ScriptToRun,
	[String] $DestinationBase,
	[String] $DestinationBootstrapScriptName,
	[UInt32] $DestinationBootstrapFileDepth = 0,
	[String] $TerminalWindowTitle,
	[Switch] $ZipInWindowsExplorerFriendly
)
{
	$Script = [Text.StringBuilder]::new()

	$CMDBoostrap = New-CMDBootstrapForWindows `
		-FileDelineator $FileData.FileDelineator `
		-DestinationBase $DestinationBase `
		-DestinationBootstrapScriptName $DestinationBootstrapScriptName `
		-TerminalWindowTitle $TerminalWindowTitle `
		-ZipInWindowsExplorerFriendly:$ZipInWindowsExplorerFriendly

	$Script.Append($CMDBoostrap) > $Null
	$Script.Append("`r`n") > $Null

	$PowerShellBootstrap = New-PowerShellBootstrap `
		-FileDelineator $FileData.FileDelineator `
		-ScriptToRun $ScriptToRun `
		-BootstrapFileDepth $DestinationBootstrapFileDepth

	$Script.Append($PowerShellBootstrap) > $Null
	$Script.Append("`r`n") > $Null

	$Script.Append($FileData.StringBuilder) > $Null
	$Script.Append("`r`n") > $Null

	$Script
}


function New-SEEPSSEFEUForMacOS (
	[PSCustomObject] $FileData,
	[String] $ScriptToRun,
	[String] $DestinationBase,
	[String] $DestinationBootstrapScriptName,
	[UInt32] $DestinationBootstrapFileDepth = 0,
	[String] $PowerShellDirectoryName = 'PowerShell',
	[String] $PowerShellTarballName = '_powershell.tar.gz',
	[Int32] $MinimumPowerShellVersionMajor = 7,
	[Int32] $MinimumPowerShellVersionMinor = 0,
	$PowerShellTarballSourceForX86,
	$PowerShellTarballSourceForARM
)
{
	$Script = [Text.StringBuilder]::new()

	$ShellBootstrap = New-ShellBootstrapForMacOS `
		-FileDelineator $FileData.FileDelineator `
		-DestinationBase $DestinationBase `
		-DestinationBootstrapScriptName $DestinationBootstrapScriptName `
		-PowerShellDirectoryName $PowerShellDirectoryName `
		-PowerShellTarballName $PowerShellTarballName `
		-MinimumPowerShellVersionMajor $MinimumPowerShellVersionMajor `
		-MinimumPowerShellVersionMinor $MinimumPowerShellVersionMinor `
		-PowerShellTarballSourceForX86 $PowerShellTarballSourceForX86 `
		-PowerShellTarballSourceForARM $PowerShellTarballSourceForARM

	$Script.Append($ShellBootstrap) > $Null
	$Script.Append("`n") > $Null

	$PowerShellBootstrap = New-PowerShellBootstrap `
		-FileDelineator $FileData.FileDelineator `
		-ScriptToRun $ScriptToRun `
		-BootstrapFileDepth $DestinationBootstrapFileDepth

	$Script.Append($PowerShellBootstrap) > $Null
	$Script.Append("`n") > $Null

	$Script.Append($FileData.StringBuilder) > $Null
	$Script.Append("`n") > $Null

	$Script
}


function Get-SEEPSSEFEUFileDefinitionsforDirectory ([IO.DirectoryInfo] $BaseDirectory, [ScriptBlock] $DetermineEncodingForFile)
{
	$Definitions = [Collections.Generic.List[PSCustomObject]]::new()

	$DrillDown = `
	{
		Param ([IO.DirectoryInfo] $Directory, [String] $Prefix)

		foreach ($Item in ($Directory.EnumerateFileSystemInfos() | Sort-Object Name))
		{
			$Destination = if ($Prefix.Length -eq 0) {$Item.Name} else {"$Prefix/$($Item.Name)"}

			if ($Item -is [IO.FileInfo])
			{
				$Definitions.Add(
					[PSCustomObject] @{
						File = $Item
						Encoding = & $DetermineEncodingForFile -File $Item -Destination $Destination
						Destination = $Destination
					}
				)
			}
			else
			{
				& $DrillDown $Item $Destination
			}
		}
	}

	& $DrillDown $BaseDirectory

	$Definitions
}


function New-SEEPSSEFEUFileData
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, Position = 0)]
				$Files,

		[Parameter()]
				[Text.StringBuilder] $StringBuilder,

		[Parameter()]
				[String] $LineEnding = "`r`n",

		[Parameter()]
				[Int32] $FileDelineatorLength = $SEEPSSEFEUConstants.FileDelineatorDefaultLength,
		[Parameter()]
				[Char] $FileDelineatorCharacterRangeStart = $SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaStart,
		[Parameter()]
				[Char] $FileDelineatorCharacterRangeEnd = $SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaEnd
	)

	$RangeOverlaps = {Param ($A, $B) $A -le [UInt32] $FileDelineatorCharacterRangeEnd -and [UInt32] $FileDelineatorCharacterRangeStart -le $B}

	$FileDelineatorMightBeBase64 = (
		    (& $RangeOverlaps ([UInt32] [Char] 'A') ([UInt32] [Char] 'Z')) `
		-or (& $RangeOverlaps ([UInt32] [Char] 'a') ([UInt32] [Char] 'z')) `
		-or (& $RangeOverlaps ([UInt32] [Char] '0') ([UInt32] [Char] '9')) `
		-or (& $RangeOverlaps ([UInt32] [Char] '+') ([UInt32] [Char] '+')) `
		-or (& $RangeOverlaps ([UInt32] [Char] '=') ([UInt32] [Char] '='))
	)

	if ($Null -ne [IO.File]::ReadAllTextAsync)
	{
		$ReadFileTasks = [Threading.Tasks.Task[]] $(
			foreach ($File in $Files)
			{
				if ($Null -ne $File.Encoding)
				{
					[IO.File]::ReadAllTextAsync($File.File.FullName, $File.Encoding)
				}
				else
				{
					[IO.File]::ReadAllBytesAsync($File.File.FullName)
				}
			}
		)

		[Threading.Tasks.Task]::WaitAll($ReadFileTasks)

		$FileContents = foreach ($Task in $ReadFileTasks)
		{
			,$Task.Result
			$Task.Dispose()
		}
	}
	else
	{
		$FileContents = foreach ($File in $Files)
		{
			if ($Null -ne $File.Encoding)
			{
				[IO.File]::ReadAllText($File.File.FullName, $File.Encoding)
			}
			else
			{
				,[IO.File]::ReadAllBytes($File.File.FullName)
			}
		}
	}

	$Strings = [Collections.Generic.List[String]]::new(($Files.Count -shl 1))

	for ($Index = 0; $Index -lt $Files.Count; ++$Index)
	{
		$Strings.Add($Files[$Index].Destination)
	}

	for ($Index = 0; $Index -lt $Files.Count; ++$Index)
	{
		$String = if ($Null -ne $Files[$Index].Encoding)
		{
			$FileContents[$Index]
		}
		elseif ($FileDelineatorMightBeBase64)
		{
			[Convert]::ToBase64String($FileContents[$Index], [Base64FormattingOptions]::InsertLineBreaks)
		}

		if ($Null -ne $String)
		{
			$Strings.Add($String)
		}
	}

	$FileDelineator = Find-UnusedFileDelineator $Strings $FileDelineatorLength $FileDelineatorCharacterRangeStart $FileDelineatorCharacterRangeEnd

	$EstimatedSize = 0

	for ($Index = $Files.Count; ($Index--);)
	{
		$Length = $FileContents[$Index].Length
		$EstimatedSize += $(if ($Null -ne $Files[$Index].Encoding) {$Length} else {$Length + ($Length -shr 2)}) + $FileDelineatorLength * 3 + 1024
	}

	$Builder = if ($Null -ne $StringBuilder) {$StringBuilder} else {[Text.StringBuilder]::new($EstimatedSize)}

	for ($Index = 0; $Index -lt $Files.Count; ++$Index)
	{
		$File = $Files[$Index]
		$Builder.Append($FileDelineator) > $Null
		$Builder.Append($File.Destination) > $Null
		$Builder.Append($FileDelineator) > $Null

		if ($Null -ne $File.Encoding)
		{
			$Builder.Append('TEXT__') > $Null
			$Builder.Append($FileDelineator) > $Null
			$Builder.Append($FileContents[$Index]) > $Null
		}
		else
		{
			$Builder.Append('BINARY') > $Null
			$Builder.Append($FileDelineator) > $Null

			$AsBase64 = if ($FileDelineatorMightBeBase64)
			{
				$Strings[$Files.Count + $Index]
			}
			else
			{
				[Convert]::ToBase64String($FileContents[$Index], [Base64FormattingOptions]::InsertLineBreaks)
			}

			$Builder.Append($AsBase64) > $Null
		}

		$Builder.Append($LineEnding) > $Null
	}

	[PSCustomObject] @{FileDelineator = $FileDelineator; StringBuilder = $Builder}
}


function Find-UnusedFileDelineator (
	[String[]] $InStrings,
	[Int32] $DelineatorLength = $SEEPSSEFEUConstants.FileDelineatorDefaultLength,
	[Char] $CharacterRangeStart = $SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaStart,
	[Char] $CharacterRangeEnd = $SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaEnd
)
{
	$CharacterRange = [Int32] ([UInt32] $CharacterRangeEnd - [UInt32] $CharacterRangeStart + [UInt32] 1)
	$AttemptCounter = 0
	$Delineator = [Char[]]::new($DelineatorLength)
	$DelineatorString = $Null

	for (;;)
	{
		$Value = $AttemptCounter

		for ($Index = $DelineatorLength; ($Index--) -gt 0;)
		{
			$Remainder = 0
			$Quotient = [Math]::DivRem($Value, $CharacterRange, [Ref] $Remainder)
			$Value = $Quotient

			$Delineator[$Index] = [Char] ([UInt32] $CharacterRangeStart + $Remainder)
		}

		$DelineatorString = [String]::new($Delineator)

		if ($Null -eq $InStrings.Where({$_.IndexOf($DelineatorString) -ne -1}, 'First')[0])
		{
			break
		}

		++$AttemptCounter
	}

	$DelineatorString
}


function New-PowerShellBootstrap ([String] $FileDelineator, [String] $ScriptToRun, [UInt32] $BootstrapFileDepth = 0)
{
$BootstrapToRoot = '../' * $BootstrapFileDepth

@"
Param (`$SEEPSSEFEUPath)

`$FileDelineator = [String]::new([Char[]] @($(([UInt32[]] $FileDelineator.ToCharArray()) -join ', ')))

`$UTF8 = [Text.UTF8Encoding]::new(`$False, `$False)

`$Reader = `$Null

try
{
	`$Reader = [IO.StreamReader]::new([IO.FileStream]::new(`$SEEPSSEFEUPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete), `$UTF8, `$True)
	`$Data = `$Reader.ReadToEnd()
}
finally
{
	if (`$Null -ne `$Reader)
	{
		`$Reader.Dispose()
	}
}

`$Index = `$Data.IndexOf(`$FileDelineator, `$Index)
`$Index += `$FileDelineator.Length

for (;;)
{
	`$Index = `$Data.IndexOf(`$FileDelineator, `$Index)

	if (`$Index -eq -1)
	{
		break
	}

	`$Index += `$FileDelineator.Length
	`$StartOfFileDestination = `$Index

	`$Index = `$Data.IndexOf(`$FileDelineator, `$Index)
	`$EndOfFileDestination = `$Index

	`$Index += `$FileDelineator.Length
	`$StartOfFileType = `$Index
	`$Index = `$Data.IndexOf(`$FileDelineator, `$Index)
	`$EndOfFileType = `$Index

	`$Index += `$FileDelineator.Length
	`$StartOfFileContents = `$Index

	`$Index = `$Data.IndexOf(`$FileDelineator, `$Index)
	`$EndOfFileContents = if (`$Index -eq -1) {`$Data.Length} else {`$Index}

	`$Destination = `$Data.Substring(`$StartOfFileDestination, `$EndOfFileDestination - `$StartOfFileDestination)
	`$FileType = `$Data.Substring(`$StartOfFileType, `$EndOfFileType - `$StartOfFileType)
	`$DestinationPath = Join-Path `$PSScriptRoot "$BootstrapToRoot`$Destination"

	New-Item -ItemType Directory -Force -Path (Split-Path `$DestinationPath) > `$Null

	if (`$FileType -eq 'TEXT__')
	{
		[IO.File]::WriteAllText(`$DestinationPath, `$Data.Substring(`$StartOfFileContents, `$EndOfFileContents - `$StartOfFileContents), `$UTF8)
	}
	elseif (`$FileType -eq 'BINARY')
	{
		[IO.File]::WriteAllBytes(`$DestinationPath, [Convert]::FromBase64String(`$Data.Substring(`$StartOfFileContents, `$EndOfFileContents - `$StartOfFileContents)))
	}

	if (`$Index -eq -1)
	{
		break
	}
}

Remove-Item -LiteralPath `$PSCommandPath -Force -ErrorAction Ignore

& (Join-Path `$PSScriptRoot '$BootstrapToRoot$($ScriptToRun.Replace('''', ''''''))')
"@
}


function New-CMDBootstrapForWindows (
	[String] $FileDelineator,
	[String] $DestinationBase,
	[String] $DestinationBootstrapScriptName,
	[String] $TerminalWindowTitle,
	[Switch] $ZipInWindowsExplorerFriendly
)
{
	if ($DestinationBootstrapScriptName.Length -eq 0)
	{
		$DestinationBootstrapScriptName = "$DestinationBase-Bootstrap"
	}

	$Escape = {Param ($Text) $(if ($Null -ne $Text) {$Text} else {[String]::Empty}).ToString().Replace('"', '\"')}

	# $P = Path
	# $B = BootstrapPathBase
	# $U = UTF8
	# $D = Delineator
	# $R = Reader
	# $S = Script
	# $I = Index
	# $J = Jindex (...what?)
@"
@echo off
$(
	if ($ZipInWindowsExplorerFriendly)
	{
@"
set "currentDirectory=%CD%"
set "scriptPath=%~dp0"
call set "sansTempPrefix=%%scriptPath:%TEMP%=%%"

rem If we're in the TEMP directory...
if not "%sansTempPrefix%"=="%scriptPath%" (
	rem And the working-directory is System32, then the script has probably been opened
	rem from within a zip-file opened in Windows explorer, so we'll move to the local app-data folder.
	if /I "%currentDirectory%"=="%SYSTEMROOT%\system32" (
		>NUL: copy /Y /B "%~dpnx0" "%LOCALAPPDATA%\%~nx0"
		cd "%LOCALAPPDATA%"
	)
)
"@
	}
)
mkdir "$DestinationBase"
start "$(& $Escape $TerminalWindowTitle)" powershell.exe -ExecutionPolicy Bypass -NoExit -Command "& {`$P = Resolve-Path -LiteralPath \"%~nx0\"; `$B = `$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(\"$DestinationBase/$DestinationBootstrapScriptName\"); `$U = [Text.UTF8Encoding]::new(`$False, `$False); `$D = [String]::new([Char[]] @($(([UInt32[]] $FileDelineator.ToCharArray()) -join ', '))); `$R = `$Null; try {`$R = [IO.StreamReader]::new([IO.FileStream]::new(`$P, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete), `$U, `$True); `$S = `$R.ReadToEnd(); `$I = `$S.IndexOf(`$D); `$J = `$S.IndexOf(`$D, `$I + $($FileDelineator.Length)); [IO.File]::WriteAllText(\"`$B.ps1\", `$S.Substring(`$I + $($FileDelineator.Length), `$J - (`$I + $($FileDelineator.Length))), `$U)} finally {if (`$Null -ne `$R) {`$R.Dispose()}}; & \"`$B.ps1\" `$P}"
exit /b

$FileDelineator
"@
}


function New-ShellBootstrapForMacOS (
	[String] $FileDelineator,
	[String] $DestinationBase,
	[String] $DestinationBootstrapScriptName,
	[String] $PowerShellDirectoryName = 'PowerShell',
	[String] $PowerShellTarballName = '_powershell.tar.gz',
	[Int32] $MinimumPowerShellVersionMajor = 7,
	[Int32] $MinimumPowerShellVersionMinor = 0,
	$PowerShellTarballSourceForX86,
	$PowerShellTarballSourceForARM
)
{
	if ($DestinationBootstrapScriptName.Length -eq 0)
	{
		$DestinationBootstrapScriptName = "$DestinationBase-Bootstrap"
	}

	$Escape = {Param ($Text) $(if ($Null -ne $Text) {$Text} else {[String]::Empty}).ToString().Replace('\', '\\').Replace('"', '\"')}

@"
#!/bin/sh

set -e

destination="$(& $Escape $DestinationBase)"
bootstrap_name="$(& $Escape $DestinationBootstrapScriptName)"
powershell_directory="`$destination/$(& $Escape $PowerShellDirectoryName)"
powershell_download_path="`$powershell_directory/$(& $Escape $PowerShellTarballName)"
pwsh_path="`$powershell_directory/pwsh"

if which pwsh > /dev/null
then
	powershell_version="`$(pwsh --version)"
	powershell_version_major="`$(echo "`$powershell_version" | LC_ALL=C sed -n -E 's/^.*([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)?$/\1/p')"
	powershell_version_minor="`$(echo "`$powershell_version" | LC_ALL=C sed -n -E 's/^.*([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)?$/\2/p')"

	echo "Detected PowerShell v$powershell_version_major.$powershell_version_minor"

	if [ "`$powershell_version_major" -ge "$MinimumPowerShellVersionMajor" ] && [ "`$powershell_version_minor" -ge "$MinimumPowerShellVersionMinor" ]
	then
		pwsh_path="pwsh"
	fi
fi

if [ ! -x "`$pwsh_path" ]
then
	pwsh_path="`$powershell_directory/pwsh"

	if [ -f "`$pwsh_path" ]
	then
		chmod +x "`$pwsh_path"
	else
		processor_architecture="`$(uname -p)"

		if [ "`$processor_architecture" = "i386" ]
		then
			powershell_size="$(& $Escape $PowerShellTarballSourceForX86.Length)"
			powershell_hash="$(& $Escape $PowerShellTarballSourceForX86.SHA256Hash)"
			powershell_url="$(& $Escape $PowerShellTarballSourceForX86.URL)"
			powershell_backup_url="$(& $Escape $PowerShellTarballSourceForX86.BackupURL)"
		elif [ "`$processor_architecture" = "arm" ]
		then
			powershell_size="$(& $Escape $PowerShellTarballSourceForARM.Length)"
			powershell_hash="$(& $Escape $PowerShellTarballSourceForARM.SHA256Hash)"
			powershell_url="$(& $Escape $PowerShellTarballSourceForARM.URL)"
			powershell_backup_url="$(& $Escape $PowerShellTarballSourceForARM.BackupURL)"
		else
			echo "The processor architecture (`$processor_architecture) of this device was unexpected. Only x86 and ARM are supported by this script."
			exit 1
		fi

		printf 'This script requires at-least version v$MinimumPowerShellVersionMajor.$MinimumPowerShellVersionMinor of PowerShell, which could not be found on this device. Would you like to download PowerShell, now? (y/n): '
		read should_download_powershell

		if [ "`$should_download_powershell" != "`${should_download_powershell#[yY]}" ]
		then
			powershell_hash_check="`$powershell_hash *`$powershell_download_path"

			if [ ! -d "`$powershell_directory" ]
			then
				mkdir -p "`$powershell_directory"
			fi

			if [ ! -f "`$powershell_download_path" ] || [ ! "`$(LC_ALL=C stat -f '%z' -- "`$powershell_download_path")" = "`$powershell_size" ] || ! echo "`$powershell_hash_check" | shasum -a 256 -b -s -c -
			then
				echo "Downloading PowerShell from `$powershell_url, please stand-by as it downloads."

				if ! curl -L --fail "`$powershell_url" -o "`$powershell_download_path"
				then
					echo "PowerShell could not be downloaded from `$powershell_url."
					echo "Downloading PowerShell from `$powershell_backup_url, please stand-by as it downloads."

					if ! curl -L --fail "`$powershell_backup_url" -o "`$powershell_download_path"
					then
						echo "PowerShell could not be downloaded from `$powershell_backup_url."
						echo "PowerShell failed to download."
						exit 2
					fi
				else
					if [ ! "`$(LC_ALL=C stat -f '%z' -- "`$powershell_download_path")" = "`$powershell_size" ] || ! echo "`$powershell_hash_check" | shasum -a 256 -b -s -c -
					then
						echo "`$powershell_download_path downloaded from `$powershell_url either: did not match the expected file-size of `$powershell_size-bytes, or did not match the expected SHA-256 hash of `$powershell_hash. The file may have been corrupted, or tampered with."
						echo "Downloading PowerShell from `$powershell_backup_url, please stand-by as it downloads."

						if ! curl -L --fail "`$powershell_backup_url" -o "`$powershell_download_path"
						then
							echo "PowerShell could not be downloaded from `$powershell_backup_url."
							echo "PowerShell failed to download."
							exit 2
						else
							if [ ! "`$(LC_ALL=C stat -f '%z' -- "`$powershell_download_path")" = "`$powershell_size" ] || ! echo "`$powershell_hash_check" | shasum -a 256 -b -s -c -
							then
								echo "`$powershell_download_path downloaded from `$powershell_backup_url either: did not match the expected file-size of `$powershell_size-bytes, or did not match the expected SHA-256 hash of `$powershell_hash. The file may have been corrupted, or tampered with."
								echo "PowerShell failed to download."
								exit 3
							fi
						fi
					fi
				fi
			fi

			tar -x -C "`$powershell_directory" -f "`$powershell_download_path"
			chmod +x "`$pwsh_path"

			if [ ! -x "`$pwsh_path" ]
			then
				echo "PowerShell was downloaded, but could not be found at `$pwsh_path after it was extracted."
				exit 4
			fi
		fi
	fi
fi
$(
	# $P = Path
	# $B = BootstrapPath
	# $U = UTF8
	# $D = Delineator
	# $R = Reader
	# $S = Script
	# $I = Index
	# $J = Jindex (...what?)
)
"`$pwsh_path" -NoExit -Command "& {\`$P = Resolve-Path -LiteralPath \"`$0\"; \`$B = \`$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(\"`$destination/`$bootstrap_name\"); \`$U = [Text.UTF8Encoding]::new(\`$False, \`$False); \`$D = [String]::new([Char[]] @($(([UInt32[]] $FileDelineator.ToCharArray()) -join ', '))); \`$R = \`$Null; try {\`$R = [IO.StreamReader]::new([IO.FileStream]::new(\`$P, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete), \`$U, \`$True); \`$S = \`$R.ReadToEnd(); \`$I = \`$S.IndexOf(\`$D); \`$J = \`$S.IndexOf(\`$D, \`$I + $($FileDelineator.Length)); [IO.File]::WriteAllText(\"\`$B.ps1\", \`$S.Substring(\`$I + $($FileDelineator.Length), \`$J - (\`$I + $($FileDelineator.Length))), \`$U)} finally {if (\`$Null -ne \`$R) {\`$R.Dispose()}}; & \"\`$B.ps1\" \`$P}"

exit 0

$FileDelineator
"@.Replace("`r`n", "`n")
}


