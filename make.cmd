@echo off
::DO NOT USE ! OR % IN YOUR FOLDER NAMES!!!!
::IT WILL BREAK THE SCRIPT!
::Don't forget quotes when specifying paths!
::Use -f for feature mode, -v for version mode
::Pass additional parameters to add DML headers as specified in the headers folder (feature mode only for now)
call build/makedml.cmd -v "%~dp0\src" "%~dp0\out" "vanilla" "scp"
call build/makedml.cmd -Z -v "%~dp0\out" "SS2 Randomiser B17" "Lite"
::pause