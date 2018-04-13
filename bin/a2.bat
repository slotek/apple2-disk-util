@echo off
setlocal
set RUBYLIB=%~dp0\..\lib
ruby "%~dp0\a2" %*
endlocal
