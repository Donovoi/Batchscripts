@if (@CodeSection == @Batch) @then

@echo off

REM BinToBat.bat: Create an installer Batch program for binary and text data files
REM Antonio Perez Ayala

if "%~1" neq "" if "%~1" neq "/?" goto begin

echo Create an installer Batch program for data files of any type
echo/
echo BINTOBAT [/T:.ext1.ext2...] [/L:lineSize] [/F[:fileSize]] filename ...
echo/
echo   /T:.ext1.ext2    Specify the extensions of text type files that will not be
echo                    encoded as hexadecimal digits, but preserved as text.
echo   /L:lineSize      Specify the size of output lines (default: 78).
echo   /F[:fileSize]    /F switch specify to generate a Full installer file.
echo                    The optional fileSize specify the maximum output file size.
echo/
echo BinToBat encode the given data files as hexadecimal digits (or preserve they
echo as compressed text) and insert they into InstallFiles.bat program; when this
echo program run, it generates the original data files.
echo/
echo You may rename the InstallFiles.bat program as you wish, but preserving the
echo "Install" prefix is suggested.
echo/
echo You may use wild-cards in the filename list.
echo/
echo If the /F switch is not given, a Partial installer is created:
echo - You may insert a short description for each file.
echo - You may insert divisions in the file listing via a dash in the parameters.
echo - The installer allows to select which files will be downloaded and ask
echo   before overwrite existent files.
echo/
echo If the /F switch is given, a Full installer is created:
echo - The installer always download all files.
echo - You may specify commands that will be executed after the files were copied.
echo - You may specify the maximum size of the output file via /F:fileFize, so in
echo   this case the output file will be divided in parts with a numeric postfix.
echo/
echo   If you use /F switch you can NOT rename the InstallFiles??.bat files; the
echo   first one is the installer and the rest just contain data.
echo/
goto :EOF

:begin
setlocal EnableDelayedExpansion
set atSign=@

rem Process parameters: BinToBat /T:.ext1.ext2 /L:lineSize /F:fileSize file list ...
set "myself=%~F0"
set "params=%*"

set "param=%~1"
set "textTypes="
if /I "%param:~0,3%" equ "/T:" (
   set "textTypes=%param:~3%."
   set "params=!params:* =!"
   shift
)

set "param=%~1"
set lineSize=78
if /I "%param:~0,3%" equ "/L:" (
   set "lineSize=%param:~3%"
   set "params=!params:* =!"
   shift
)

set "param=%~1"
if /I "%param:~0,2%" equ "/F" goto FullInstaller


:PartialInstaller

rem Create the heading part of output file
(
echo %atSign%if (@CodeSection == @Batch^) @then
call :getResource BatchSection-PartialInstaller
echo %atSign%end
call :getResource JScriptSection
echo %atSign%if (@CodeSection == @Resources^) @then
) > InstallFiles.bat

rem Convert each given file to hex digits and embed them in its resource
echo --^>  Enter a short description for each division or file
echo/
set /A id=0, dId=0
for %%a in (%params%) do if /I "%%~NXa" neq "InstallFiles.bat" if /I "%%~NXa" neq "%~NX0" (
   if "%%a" neq "-" (
      if not exist "%%~a" (
         echo File not found: %%a
      ) else (
         set /A id+=1
         set "desc= "
         set /P "desc=!id!- %%~NXa: "
         set type=notx
         if defined textTypes if "!textTypes:%%~Xa.=!" neq "%textTypes%" set type=text
         ( rem Start of redirected block
         echo/
         echo ^<resource id="!id!|%%~Za|%%~NXa|!type!|!desc!"^>
         Cscript //nologo //E:JScript "%myself%" !id! "%%~a" !type! !lineSize!
         echo ^</resource^>
         ) >> InstallFiles.bat
         echo %%~NXa file embedded
      )
   ) else (
      set /A dId-=1
      set "desc= "
      set /P "desc=- "
      ( rem Start of redirected block
      echo/
      echo ^<resource id="!dId!|0|- |div|!desc!"^>
      echo ^</resource^>
      ) >> InstallFiles.bat
   )
   echo/
)

rem Create the trailing part of output file
(
echo/
echo :getLastID
echo set lastID=!id!
echo exit /B
echo/
echo %atSign%end
) >> InstallFiles.bat
goto endFile


:FullInstaller

rem Get the maximum file size from this parameter: /F:fileSize
for /F "tokens=2 delims=:" %%a in ("%param%") do set "maxSize=%%a"
if defined maxSize (
   set /A maxSize-=10
) else (
   set /A maxSize=0x7FFFFFFF
)
set "params=!params:* =!"

rem Create the heading part of output file
del InstallFiles??.bat 2> NUL
(
echo %atSign%if (@CodeSection == @Batch^) @then
call :getResource BatchSection-FullInstaller
) > InstallFiles00.bat
echo Enter commands that will be executed after the files were copied,
echo or an empty line to continue:
echo/
:nextCommand
   set "command="
   set /P "command=> "
   if not defined command goto continue
   echo !command!>> InstallFiles00.bat
goto nextCommand
:continue
( rem Start of redirected block
echo goto :EOF
echo/
echo End of Batch section
echo/
echo/
echo %atSign%end
call :getResource JScriptSection
echo %atSign%if (@CodeSection == @Resources^) @then
) >> InstallFiles00.bat

rem Sort files by size in descending order
for %%a in (%params%) do set "N=%%~Na" & if /I "!N:~0,12!%%~Xa" neq "InstallFiles.bat" if /I "%%~Fa" neq "%myself%" (
   if not exist "%%~a" (
      echo File not found: %%a
   ) else (
      set /A fileSize=0x7FFFFFFF-%%~Za
      set fileSize=000000000!fileSize!
      set "fileName[!fileSize:~-10!-%%a]=1"
   )
)

rem Convert each given file to hex digits or encoded text and embed they in its resource
echo/
set id=0
set lastFile=100
for /F "tokens=2 delims=-]" %%a in ('set fileName[') do (
   set /A id+=1
   set type=notx
   if defined textTypes if "!textTypes:%%~Xa.=!" neq "%textTypes%" set type=text
   ( rem Start of redirected block
   echo/
   echo ^<resource id="!id!|%%~Za|%%~NXa|!type!| "^>
   Cscript //nologo //E:JScript "%myself%" !id! "%%~a" !type! !lineSize!
   echo ^</resource^>
   ) > InstallFiles.bat
   rem Insert this data in the first output file with enough free space
   for %%f in (InstallFiles.bat) do set increment=%%~Zf
   for /L %%i in (100,1,!lastFile!) do if exist InstallFiles.bat (
      set i=%%i
      for %%f in ("InstallFiles!i:~1!.bat") do set /A newSize=%%~Zf+increment
      if !newSize! leq %maxSize% (
         type InstallFiles.bat >> InstallFiles!i:~1!.bat
         del  InstallFiles.bat
      )
   )
   if exist InstallFiles.bat (
      rem Create a new output file
      set /A lastFile+=1
      (
      echo :InstallFiles!lastFile:~1!.bat
      echo/
      echo @goto :EOF
      ) > InstallFiles!lastFile:~1!.bat
      if !increment! leq %maxSize% (
         rem Insert this data in the new empty file
         type InstallFiles.bat >> InstallFiles!lastFile:~1!.bat
         del  InstallFiles.bat
      ) else (
         rem Split this data in several new files
         echo Creating part !lastFile:~1!
         set adjust=0
         if !id! gtr 9 set adjust=1
         set /A "line=0, maxLines=(maxSize-1)/(lineSize+4+adjust)+1"
         for /F "delims=" %%b in (InstallFiles.bat) do (
            set /A line+=1
            if !line! equ !maxLines! (
               echo ^</resource^>>> InstallFiles!lastFile:~1!.bat
               set /A lastFile+=1, line=0
               (
               echo :InstallFiles!lastFile:~1!.bat
               echo/
               echo @goto :EOF
               echo ^<resource id="!id!|%%~Za|%%~NXa|!type!| "^>
               ) > InstallFiles!lastFile:~1!.bat
               echo Creating part !lastFile:~1!
            )
            (
            setlocal DisableDelayedExpansion
            echo %%b
            endlocal
            ) >> InstallFiles!lastFile:~1!.bat
         )
         del InstallFiles.bat
      )
   )
   echo %%~NXa file embedded
)

rem Create the trailing part of output file
(
echo/
echo %atSign%end
) >> InstallFiles00.bat


:endFile
echo/
echo InstallFiles.bat file(s) created
goto :EOF


:getResource resourceId
rem Resource data start format: ^<resource id="resourceId"^>
set start=
set lines=
for /F "tokens=1,3 delims=:=>" %%a in ('findstr /N "^</*resource" "%myself%"') do (
   if not defined start (
      if "%1" equ "%%~b" set start=%%a
   ) else (
      if not defined lines set /A lines=%%a-start-1
   )
)
set line=0
for /F "skip=%start% tokens=1* delims=]" %%a in ('find /N /V "" ^< "%myself%"') do (
   setlocal DisableDelayedExpansion
   echo(%%b
   endlocal
   set /A line+=1
   if !line! equ %lines% exit /B
)
exit /B

End of Batch section


@end


// JScript section

// Convert original input file to encoded Stdout
// Antonio Perez Ayala

// Arguments: idNumber fileName type lineSize

var id = WScript.Arguments(0), lineSize = parseInt(WScript.Arguments(3));

if ( WScript.Arguments(2) == "text" ) {

// Convert input text file into an encoded text form in Stdout
// Each line is encoded as: <number of spaces from 3 to 29><line length>:<line contents>

var fso = new ActiveXObject("Scripting.FileSystemObject");
var input = fso.OpenTextFile(WScript.Arguments(1), 1);  // ForReading = 1
var output = WScript.Stdout, outputLine = "", atSign, key, pos;

while ( ! input.AtEndOfStream ) {
   var inputLine = input.ReadLine(), spaces = 0;
   // Encode <number of spaces>
   while ( inputLine.charAt(spaces) == " " ) spaces++;
   if ( 3 <= spaces && spaces <= 29 ) {
      outputLine += spaces;
      inputLine = inputLine.substr(spaces);
   } else {
      outputLine += "0";
   }
   // Break JScript conditional compilation statements
   atSign = 1;
   while ( atSign ) {
      atSign = inputLine.length;
      for ( key in {"if":0,"elif":0,"else":0,"end":0} ) {
         if ( pos = inputLine.indexOf("@"+key)+1 ) atSign=Math.min(atSign,pos);
      }
      if ( atSign < inputLine.length ) {
         outputLine += atSign+":"+inputLine.substr(0,atSign)+"@";
         inputLine = inputLine.substr(atSign);
      } else {
         atSign = 0;
      }
   }
   // Encode joined <line length>: 
   if ( inputLine.length ) outputLine += inputLine.length;
   outputLine += ":";
   if ( outputLine.length >= lineSize ) {
      output.WriteLine(id+":"+outputLine);
      outputLine = "";
   }
   // Encode line contents
   if ( inputLine.length ) outputLine += inputLine;
   // Output result in segments
   while ( outputLine.length > lineSize ) {
      output.WriteLine(id+":"+outputLine.substr(0,lineSize));
      outputLine = outputLine.substr(lineSize);
   }
}
if ( outputLine.length ) output.WriteLine(id+":"+outputLine);

} else {

// Convert binary bytes from input file to Hex digits in Stdout

var ado = WScript.CreateObject("ADODB.Stream");
ado.Type = 2;  // adTypeText = 2
ado.CharSet = "iso-8859-1";  // code page with minimum adjustments for input
ado.Open();
ado.LoadFromFile(WScript.Arguments(1));

var adjustment = "\u20AC\u0081\u201A\u0192\u201E\u2026\u2020\u2021" +
                 "\u02C6\u2030\u0160\u2039\u0152\u008D\u017D\u008F" +
                 "\u0090\u2018\u2019\u201C\u201D\u2022\u2013\u2014" +
                 "\u02DC\u2122\u0161\u203A\u0153\u009D\u017E\u0178" ;

var thisByte = ado.ReadText(1), lastByte = thisByte.charCodeAt(0), lastCount = 1, lastLen = 0,
    output = WScript.Stdout, outputLine = "";
if ( lastByte > 255 ) lastByte = 128 + adjustment.indexOf(thisByte);
while ( ! ado.EOS ) {
   var inputLine = ado.ReadText(128*1024);
   for ( var index = 0; index < inputLine.length; index++ ) {
      thisByte = inputLine.charCodeAt(index);
      if ( thisByte > 255 ) thisByte = 128 + adjustment.indexOf(inputLine.charAt(index));
      if ( thisByte == lastByte ) {
         lastCount++;
      } else {
         lastLen = outputLine.length;
         lastByte = ("0"+lastByte.toString(16)).slice(-2);
         if ( (lastByte == "00" && lastCount == 1) || (lastByte != "00" && lastCount < 4 ) ) {
            for ( var i = 1; i <= lastCount; i++ ) {
               outputLine += lastByte;
            }
         } else {
            outputLine += '[' + lastCount;
            if ( lastByte != "00" ) outputLine += 'x' + lastByte;
            outputLine += ']';
         }
         lastByte = thisByte;
         lastCount = 1;
         if ( outputLine.length > lineSize ) {
            output.WriteLine(id+':'+outputLine.substr(0,lastLen));
            outputLine = outputLine.substr(lastLen);
         }
      }
   }
   WScript.Stderr.Write((ado.Position/ado.Size*100).toFixed() + " % converted\r");
}
lastByte = ("0"+lastByte.toString(16)).slice(-2);
if ( lastCount < 4 ) {
   for ( i = 1; i <= lastCount; i++ ) {
      outputLine += lastByte;
   }
} else {
   outputLine += '[' + lastCount;
   if ( lastByte != "00" ) {
      outputLine += 'x' + lastByte;
   }
   outputLine += ']';
}
output.WriteLine(id+':'+outputLine);
ado.Close();

}

// End of JScript section


@if (@CodeSection == @Resources) @then


<resource id="BatchSection-PartialInstaller">


@echo off
setlocal EnableDelayedExpansion
if "%~1" neq "" if "%~1" neq "/?" goto begin
if "%~1" equ "" (
   echo This program can install the following data files:
   echo/
   for /F tokens^=2-6^ delims^=^"^| %%a in ('findstr "^<resource" "%~F0"') do (
      if %%a gtr 0 (
         echo   %%a- %%c %%e
      ) else (
         echo/
         echo - %%e
      )
   )
   echo/
   echo For help, type: %0 /?
) else (
   echo This program is an installer of several data files included in it.
   echo/
   echo To show a list of the included files, type just:  %0
   echo/
   echo Enter the numbers of the desired files using the same format of "tokens=..."
   echo FOR command's option (type: FOR /? for further details^). For example:
   echo/
   echo     Install just file 6:                 %0 6
   echo     Install files 2, 4 and from 7 to 9:  %0 2,4,7-9
   echo     Install files from 14 to last one:   %0 14*
   echo     Install all files:                   %0 *
   echo/
   echo/
   echo Created using BinToBat.bat file written by Antonio Perez Ayala (aka Aacini^)
)
echo/
goto :EOF

:begin
call :getLastID
set argv=%*
if "%argv%" equ "*" (
   set argv=1-%lastID%
) else (
   if "%argv:~-1%" equ "*" (
      if "%argv:~-2%" equ ",*" set argv=%argv:~0,-1%
      set argv=!argv:~0,-1!-%lastID%
   )
)
set idList=/
for %%a in (%argv%) do (
   for /F "tokens=1,2 delims=-" %%b in ("%%a") do (
      if "%%c" equ "" (
         set idList=!idList!%%b/
      ) else (
         for /L %%i in (%%b,1,%%c) do set idList=!idList!%%i/
      )
   )
)
set action=N
for /F tokens^=2-5^ delims^=^"^| %%a in ('findstr "^<resource" "%~F0"') do (
   if "!idList:/%%a/=/!" neq "%idList%" (
      set "output=%~DP0%%c"
      if exist "!output!" (
         if /I !action! neq A (
            set /P "action=Overwrite %%c? (No/Yes/All): "
            set "action=!action:~0,1!
         )
         set act=!action!
         if /I !act! equ A set act=Y
         if /I !act! equ Y del "!output!"
         if /I !action! neq A set action=N
      )
      if not exist "!output!" (
         echo/
         echo Extracting %%c
         findstr "^%%a:" "%~F0" | Cscript //nologo //E:JScript "%~F0" "!output!" %%b %%d
         echo %%c file created
      )
      echo/
   )
)
goto :EOF

End of Batch section


</resource>


<resource id="BatchSection-FullInstaller">

@echo off
setlocal EnableDelayedExpansion

cd "%~P0"
set lastFile=:dummy:
for %%f in (InstallFiles*.bat) do (
   for /F tokens^=2-5^ delims^=^"^| %%a in ('findstr "^<resource" "%%f"') do (
      if "%%c" neq "!lastFile!" (
         echo Extracting %%c
         set "part="
      ) else (
         echo Appending next part
         set part=part
      )
      findstr "^%%a:" "%%f" | Cscript //nologo //E:JScript InstallFiles00.bat "%%c!part!" %%b %%d
      if defined part (
         type "%%c!part!" >> "%%c"
         del  "%%c!part!"
         echo Part appended
      ) else (
         echo %%c file created
      )
      set "lastFile=%%c"
   )
)
</resource>


<resource id="JScriptSection">


// JScript section

// Convert encoded Stdin to original output file
// Antonio Perez Ayala

// Arguments: fileName size type

if ( WScript.Arguments(2) == "text" ) {

// Convert encoded text from Stdin to output text file
// Each line is encoded as: <number of spaces from 3 to 29><line length>:<line contents>

var fso = new ActiveXObject("Scripting.FileSystemObject");
var output = fso.CreateTextFile(WScript.Arguments(0), true);
//            12345678901234567890123456789 
var spaces = "                             ", cutId, digits, inputBuf;
var input = WScript.StdIn, inputLine = "", newLine = "", len;

while ( ! input.AtEndOfStream || inputLine.length ) {
   if ( ! inputLine.length ) {
      inputLine = input.ReadLine();
      for ( cutId = 0; inputLine.charAt(cutId++) != ":"; );
      inputLine = inputLine.substr(cutId);
   }
   len = inputLine.charAt(0);
   inputLine = inputLine.substr(1);
   if ( len == "1"  ||  len == "2" ) {
      len += inputLine.charAt(0);
      inputLine = inputLine.substr(1);
   }
   if ( len != "@"  ) output.Write(newLine+spaces.substr(0,parseInt(len)));
   newLine = "\r\n";
   for ( digits = 0; inputLine.charAt(digits) != ":"; digits++ );
   len = digits ? parseInt(inputLine.substr(0,digits)) : 0;
   inputLine = inputLine.substr(digits+1);
   while ( inputLine.length < len ) {
      inputBuf = input.ReadLine();
      for ( cutId = 0; inputBuf.charAt(cutId++) != ":"; );
      inputLine += inputBuf.substr(cutId);
   }
   output.Write(inputLine.substr(0,len));
   inputLine = inputLine.substr(len);
}
output.WriteLine();
output.Close();

} else {

// Convert Hex digits from Stdin to binary bytes in output file

var ado = WScript.CreateObject("ADODB.Stream");
ado.Type = 2;  // adTypeText = 2
ado.CharSet = "iso-8859-1";  // right code page for output (no adjustments)
ado.Open();

var input = WScript.StdIn, cutId = 0, outputLine = "", byte, count;
var size = parseInt(WScript.Arguments(1));
while ( ! input.AtEndOfStream ) {
   var inputLine = input.ReadLine();
   if ( cutId == 0 ) while ( inputLine.charAt(cutId++) != ':' );
   for ( var index = cutId; index < inputLine.length; ) {
      if ( inputLine.charAt(index) == '[' ) {
         for ( count = ++index; inputLine.charAt(index) != 'x' &&
                                inputLine.charAt(index) != ']' ; index++ ) ;
         count = parseInt(inputLine.slice(count,index++));
         if ( inputLine.charAt(index-1) == 'x' ) {
            byte = String.fromCharCode(parseInt(inputLine.substr(index,2),16));
            index += 3;
         } else {
            byte = String.fromCharCode(0);
         }
         for ( var i = 1; i <= count; i++ ) {
            outputLine += byte;
         }
      } else {
         outputLine += String.fromCharCode(parseInt(inputLine.substr(index,2),16));
         index += 2;
      }
   }
   if ( outputLine.charAt(32*1024) != "" ) {
      ado.WriteText(outputLine);
      outputLine = "";
      WScript.Stderr.Write((ado.Position/size*100).toFixed() + " % converted\r");
   }
}
if ( outputLine.length ) ado.WriteText(outputLine);
ado.SaveToFile(WScript.Arguments(0),2);  // adSaveCreateOverWrite = 2
ado.Close();

}

// End of JScript section


</resource>


@end
