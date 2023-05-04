@echo off
::Don't forget quotes when specifying paths!
::Passing 1 as the fourth parameter will generate DML headers
call build/makedml.cmd -f "%~dp0\src" "%~dp0\out" 0
pause