@echo off

setlocal

cd "%~dp0"

7za a hosts.zip userdata/start.tpl.bat modules/system/html/openserver/index.php
