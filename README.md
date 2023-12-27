# seepssefeu
seepssefeu, of course, stands for "Self extracting & executing PowerShell script—easy for end users".

As the name suggests, this is a tool used to generate a script file which extracts and executes a multi-file PowerShell script, in a way that's easy for an end-user to use, wherein an end-user is potentially someone who finds zip-archives confusing.
seepssefeu supports the generation of a script for Windows and macOS. For Windows, the generated script is a Batch file, whereas on macOS, the generated script is a Bourne Shell script.

For Windows targets, the embedded PowerShell script is executed using the built-in PowerShell, which is expected to be PowerShell 5.1.  
For macOS, the Shell bootstrap script checks for the presence of `pwsh` on the user's system, and if it is present and the minimum version is satisfied it is used, otherwise PowerShell is downloaded from a URL (it will not be installed, a portable tarball is used) and that downloaded PowerShell binary is used.

There are three main reasons for generating a script rather than some kind of executable: there's no need to digitally sign a script to avoid untrusted-software-whatever dialogs on Windows and macOS, there's no need to distribute different scripts for different processor architectures, and a script is more easily inspected by an end-user.

The generated scripts are designed to support being re-encoded with a different character-encoding or different line-endings from what they were originally saved with—they do not rely on fixed byte, code-unit, nor code-point offsets.
Instead, the script delineate files by a special marker referred to as the file-delineator.  
By default, the file-delineator is an 8-character run of code-points from the Private Use Area of Unicode.
seepssefeu has support for automatically finding a file-delineator that won't conflict with the files to be embedded in the generated script. (This also means that seepssefeu-generated scripts can be nested).  
Binary files are encoded as Base64.

## Usage

For the most part, seepssefeu is used via one function and quite a few parameters. (It is assumed that `seepssefeu.ps1` has already been dot-sourced).
A seepssefeu script for Windows and macOS can be generated through one call to `New-SEEPSSEFEU`, which takes the following parameters:  
`Files`: a sequence of files to embed in the seepssefeu script—more on this later. The order in which the files are supplied is the order that the files are embedded into the seepssefeu script in.  
`ScriptToRun`: the file-name of the PowerShell script to run automatically after the seepssefeu script extracts all its files. This is relative to `DestinationBootstrapScriptName`.  
`DestinationBase`: the name of the folder that the seepssefeu script creates and extracts all its files into. This is relative to the seepssefeu script when it is run.  
`DestinationBootstrapScriptName`: the name of the PowerShell bootstrap script that the seepssefeu script creates to extract all its files with. This is relative to `DestinationBase`. This needs not include a file-extension, as `.ps1` is added automatically.  If this is `$Null`, it defaults to `"$DestinationBase-Bootstrap"`.  
`DestinationBootstrapFileDepth`: this is used to specify the directory-depth of the PowerShell bootstrap script, which is controlled by `DestinationBootstrapScriptName`, if `DestinationBootstrapScriptName` was `bootstrap` this would be `0`, otherwise if `DestinationBootstrapScriptName` was `one/two/bootstrap` this would be `2` (as it's two directories deep), if `DestinationBootstrapScriptName` was `one/two/../bootstrap` this would be `1` as it resolves to being one directory deep.  
`TerminalWindowTitle`:  this is the title of the window used for the PowerShell terminal that the script is run with, for Windows targets.  
`MakeZipInWindowsExplorerFriendlyVersion`: when this switch is supplied, an additional version of the Batch file for Windows will be generated, this version is capable of detecting if it's been run from within a zip-archive opened in Windows Explorer, and when that's detected it will copy itself to the user's local app-data folder so that file extraction succeeds. The heuristic used for this is: if the Batch file is located in the user's `%TEMP%` directory, and the working-directory is `%SYSTEMROOT%\system32`.  
`PowerShellDirectoryName`: this is the name of the directory that a downloaded PowerShell tarball gets extracted into, for macOS targets, it defaults to `PowerShell`. This is relative to `DestinationBase`.  
`PowerShellTarballName`: this is the name that is used for a downloaded PowerShell tarball, for macOS targets, it defaults to `_powershell.tar.gz`. This is relative to `PowerShellDirectoryName`.  
`MinimumPowerShellVersionMajor`: this is the minimum major-version of PowerShell required for macOS targets, it defaults to `7`.  
`MinimumPowerShellVersionMinor`: this is the minimum minor-version of PowerShell required for macOS targets, it defaults to `0`.  
`PowerShellTarballSourceForX86`: this is used to specify where PowerShell is downloaded from, for x86 macOS targets—more on this later.  
`PowerShellTarballSourceForARM`: this is used to specify where PowerShell is downloaded from, for ARM macOS targets—more on this later.  
`FileDelineatorLength`: this is used to specify the length used for the file-delineator, in UTF-16 code-units, it defaults to `$SEEPSSEFEUConstants.FileDelineatorDefaultLength`, which defaults to `8`.  
`FileDelineatorCharacterRangeStart`: this is used to specify the starting UTF-16 code-unit used for the file-delineator, it defaults to `$SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaStart`, which defaults to `[Char] 0xF3BF`.  
`FileDelineatorCharacterRangeEnd`: this is used to specify the ending (inclusive) UTF-16 code-unit used for the file-delineator, it defaults to `$SEEPSSEFEUConstants.FileDelineatorPrivateUseAreaEnd`, which defaults to `[Char] 0xF3EF`.  

The structure expected by the `Files` parameter:  
The `Files` parameter expects a sequence of hash-table-like objects, each containing three members:  
`File`: An `IO.FileInfo` instance for a file that is to be embedded in the seepssefeu script.  
`Encoding`: A `Text.Encoding` instance corresponding to the character-encoding that `File` is using, or `$Null` if it is to be treated as a binary file.  
`Destination`: A `String` instance which is used specify where the seepssefeu script is to extract the file to, this is relative to `DestinationBase`.

The `Get-SEEPSSEFEUFileDefinitionsforDirectory` function can be used to generate a sequence of file objects for a directory of existing files, it expects a script-block for the `DetermineEncodingForFile` parameter, which takes an `IO.FileInfo` instance and returns a `Text.Encoding` instance.

The structure expected by the `PowerShellTarballSourceForX86` and `PowerShellTarballSourceForARM` parameters:  
These two parameters expect a hash-table-like object with four members:  
`Length`: An integer specifying the file-size, in bytes, of the PowerShell tarball to be downloaded.  
`SHA256Hash`: A string specifying the SHA256 hash of the PowerShell tarball to be downloaded.  
`URL`: A string specifying the URL that the PowerShell tarball is to be downloaded from.  
`BackupURL`: A string specifying the URL that the PowerShell tarball is to be downloaded from if it can't be downloaded from `URL`. (Use a link from the Wayback Machine, or something like that).

`New-SEEPSSEFEU` returns a `PSCustomObject` with at-least two members, `Windows` and `MacOS`, each being a `Text.StringBuilder` instance with the contents of the generated script ready to save.  
If the `MakeZipInWindowsExplorerFriendlyVersion` switch was provided, then an additional member with a generated script, `WindowsZipInWindowsExplorerFriendly`, will be present.

### Example

Say we have a PowerShell script called "The Script", this is how it could be packaged using seepssefeu.

```powershell
$UTF8 = [Text.UTF8Encoding]::new($False, $False)
$UTF16LE = [Text.UnicodeEncoding]::new($False, $True, $False)

$Files = @(
	@{File = Get-Item -LiteralPath Use-TheScript.ps1; Encoding = $UTF8; Destination = 'Use-TheScript.ps1'},
	@{File = Get-Item -LiteralPath PictureOfBanana.jpg; Destination = 'Fruit/Banana.jpg'},
	@{File = Get-Item -LiteralPath CompositionOfABanana.txt; Encoding = $UTF16LE; Destination = 'Fruit/Banana.txt'}
)

$X86PowerShell = @{
	Length = 66352798
	SHA256Hash = '4b6ca38156561d028ad346ad7539592c04ea2c09bfdf6da59b3a72a1dd39d2ee'
	URL = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.9/powershell-7.2.9-osx-x64.tar.gz'
	BackupURL = 'https://example.com/powershell-7.2.9-osx-x64.tar.gz'
}
$ARMPowerShell = @{
	Length = 62638308
	SHA256Hash = 'd34572d97ef4002b361fdedac51a9bca39b4b2d1e526e7355de062063ae9f8bf'
	URL = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.9/powershell-7.2.9-osx-arm64.tar.gz'
	BackupURL = 'https://example.com/powershell-7.2.9-osx-arm64.tar.gz'
}

$Scripts = New-SEEPSSEFEU `
	-Files $Files `
	-DestinationBase the-script `
	-ScriptToRun Use-TheScript.ps1 `
	-TerminalWindowTitle 'The Script' `
	-PowerShellTarballSourceForX86 $X86PowerShell `
	-PowerShellTarballSourceForARM $ARMPowerShell

[IO.File]::WriteAllText((Join-Path $PWD the-script.bat), $Scripts.Windows.ToString(), $UTF8)
[IO.File]::WriteAllText((Join-Path $PWD the-script.command), $Scripts.MacOS.ToString(), $UTF8)
```

## Limitations

- There is no way to forward arguments supplied to a generated seepssefeu script to the actual PowerShell script that gets run—this will not be supported.
- The current implementation is very simple, and so all the file IO is done synchronously, and everything is loaded into memory all at once. So, its handling of very-large scripts isn't good.
- Linux targets aren't supported.

## Licensing

seepssefeu, and its accompanying documentation, is distributed under the [Boost Software License, Version 1.0](https://www.boost.org/LICENSE_1_0.txt).
Though, the bootstrap scripts generated by seepssefeu can alternatively be used under the terms of the [BSD Zero Clause License](https://spdx.org/licenses/0BSD.html)—so there's no need to worry about copyright notices in the generated scripts.

