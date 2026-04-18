@echo off
rem stubble.bat
rem
rem (c) 1992 Xanadu Operating Company
rem All rights reserved
rem
rem /ravi/9/4/92/
rem
set stubble=%0
:loop
if "%1a"=="a" goto done
        set stubble=%stubble% %1
        shift
        goto loop
:done
echo %stubble% | sed -e "s-\\-/-g" > \tmp\nt-stub.ksh
sh /tmp/nt-stub.ksh > %tmp%\nt-stub.bat
call %tmp%\nt-stub.bat
