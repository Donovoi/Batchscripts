@if (@a)==(@b) @end /* 
:: ─────────────────────────────────────────────────────────────
:: The above line is a trick used in hybrid scripts.
:: For the batch interpreter, the line is parsed as a harmless IF statement.
:: For JScript, it starts a comment block. This allows the file to be both valid batch and JScript.
:: ─────────────────────────────────────────────────────────────

@echo off & setlocal EnableExtensions DisableDelayedExpansion
:: In batch: Turn off echoing and enable command extensions,
:: then disable delayed variable expansion.

>nul 2>&1 net.exe session || (
  cscript.exe //nologo //e:jscript "%~fs0"
  exit /b
)
:: This line attempts to run “net.exe session” redirecting all output to nul.
:: If that command fails (often due to lack of administrative privileges),
:: the batch script uses cscript to re-run the same file (%~fs0) as a JScript,
:: which will then trigger a self-elevation routine.
:: Finally, it exits the batch script.

powershell.exe -nop -ep Bypass -c ^"^
$Env:Path=[Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory();^
[AppDomain]::CurrentDomain.GetAssemblies() ^| %% {^
  if (-not $_.Location) {continue};^
  Write-Host -ForegroundColor Cyan ('Compiling ' + (Split-Path -Leaf $_.Location));^
  ngen.exe install $_.Location;^
  '';^
}^"
:: Next, the batch script calls PowerShell with no profile (-nop) and a bypassed execution policy (-ep Bypass).
:: The command sets the environment PATH to the .NET runtime directory.
:: It then enumerates all loaded assemblies in the current AppDomain.
:: For each assembly that has a physical location, it:
::   – prints the file name in Cyan,
::   – calls ngen.exe install on that assembly to precompile it to native code,
::   – and outputs an empty string for spacing.
:: The caret (^) characters and escaped quotes (^") allow the multi-line command to be passed correctly.

pause
:: Pause the batch script so the user can see the output before closing.

goto :eof
:: End the batch file execution gracefully.

*/ 
:: ─────────────────────────────────────────────────────────────
:: The above "*/" closes the JScript multi-line comment that began at the very start.
:: The following line is only seen by JScript.
:: ─────────────────────────────────────────────────────────────

WScript.CreateObject('Shell.Application').ShellExecute('cmd.exe', ' /c ""' + WScript.ScriptFullName + '""', '', 'runas', 1);
:: In JScript:
:: This creates a Shell.Application object and uses its ShellExecute method
:: to re-run the current script (retrieved via WScript.ScriptFullName) in a new cmd.exe instance.
:: The '/c' argument tells cmd.exe to execute the command and exit.
:: The empty string parameter is for the working directory.
:: The 'runas' verb instructs Windows to run the command with elevated (administrator) privileges.
:: The final argument '1' sets the window style (normal window).
