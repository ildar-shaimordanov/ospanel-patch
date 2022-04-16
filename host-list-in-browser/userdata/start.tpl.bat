@echo off
"%PHP_BIN%" -n "%sprogdir%\modules\system\html\openserver\index.php" < "%sprogdir%/modules/http/%httpdriver%/conf/httpd.conf"
