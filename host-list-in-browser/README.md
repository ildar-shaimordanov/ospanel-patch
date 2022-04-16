<!-- toc-begin -->
# Table of Content
* [Host list in browser](#host-list-in-browser)
* [How it works](#how-it-works)
  * [Some lacks and their fixes](#some-lacks-and-their-fixes)
* [Why does it work this way exactly](#why-does-it-work-this-way-exactly)
<!-- toc-end -->

# Host list in browser

After running the server your projects are visible in a popup menu by the following series of clicks: Windows tray bar -> Open Server -> My projects. It's matter of preferences, but personally for me it's not convenient. I believe it's true for other people.

Early, [Denwer](https://denwer.ru), the predecessor of [OSPanel](https://ospanel.io/), provided the cool feature: once running it displayed the list of hosts on one of the pages of localhost.

This patch is an attempt to reproduce that feature and display the actual list of recent virtual hosts.

# How it works

There are two files:

1. `osp-host-list/userdata/start.tpl.bat`
1. `osp-host-list/modules/system/html/openserver/index.php`

Open Server allows to extend starting and stopping stages with own batch scripts.

The first file is the template used to generate the script `./userdata/start.bat` to perform actions after launching all modules. To this moment the environment is already configured, so it runs the second file using the PHP binary from the right place and pass for reading the file `httpd.conf` corresponding the currently running Apache server.

This script looks for the Apache `<VirtualHost>` configurations and extract the port, server name, document root and SSL engine usage and store the results in the file `.hosts.php` next to this script.

This script opened in a browser as the part of http://localhost/openserver/ reads the generated file and displays the list of hosts in convenient way.

As a small benefit it also shows the link to the official documentation and the list of tools (Adminer, and phpMyAdmin, by default).

## Some lacks and their fixes

I found that user-defined startup scripts don't work properly.

All `./userdata/*.tpl.bat` files are used and the corresponding `./userdata/*.bat` files are created but Open Server even of version 5.4.1 throws the error dialog box with the message that some `*.bat` files are not found.

This issue is still existing since 2016 and seems not fixed in 2021 (Open Server 5.4.1).

There is workaround reported in the forum's thread [pre_start.tpl.bat / start.tpl.bat](https://ospanel.io/forum/viewtopic.php?f=1&t=2423):

> Решение есть с символической ссылкой

To fix the issue you need to execute the following command with the elevated privileges (assuming that you opened the terminal in the Open Server root directory, for example `C:\OpenServer`):

```
mklink start.bat userdata\start.bat
```

# Why does it work this way exactly

We could read the `httpd.conf` file directly from the PHP script and show everything at once. But there are two weak things:

1. No reliable way to recognize the location of the `httpd.conf` file from the php script running as http://localhost/openserver/ or whatever else.
1. By default, PHP is restricted to get access to files that are out of the `open_basedir` settings.

To avoid necessity in modifying anything in many places and to eliminate possible side effects by these modifications this way is used to find out the real list of hosts.

