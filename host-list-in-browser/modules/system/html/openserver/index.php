<?php

# Uncomment if you want to format hosts as unordered lists
#define('HOSTS_AS_LIST', false);

define('HOSTS_FILE', __DIR__ . '/.hosts.php');

if ( defined('STDIN') ) {
	$http_conf = file_get_contents('php://stdin');

	$re_VirtualHost = "#<VirtualHost\s+\*\:(\d+)>\s*(.+)\s+</VirtualHost>#Usm";
	$re_ServerName = '#^\s*ServerName\s+"([^"]+)"#Um';
	$re_DocumentRoot = '#^\s*DocumentRoot\s+"([^"]+)"\s*#Um';
	$re_SSLEngine = '#^\s*SSLEngine\s+on\s*$#Um';

	$proto = array(
		80 => 'http',
		443 => 'https',
	);

	$hosts = array();

	preg_match_all($re_VirtualHost, $http_conf, $vhosts, PREG_SET_ORDER);

	foreach ($vhosts as $vhost) {
		$site_port = $vhost[1];

		if ( ! preg_match($re_ServerName, $vhost[2], $matches) ) {
			continue;
		}
		$site_name = $matches[1];

		# special case: skip it anyway
		if ( $site_name == 'default' ) {
			continue;
		}

		if ( ! preg_match($re_DocumentRoot, $vhost[2], $matches) ) {
			continue;
		}
		$site_root = $matches[1];

		$site_proto = preg_match($re_SSLEngine, $vhost[2])
			? 'https'
			: 'http';

		$site_url = "$site_proto://$site_name";
		if ( $proto[$site_port] !== $site_proto ) {
			$site_url .= ":$site_port";
		}

		$hosts[$site_name][] = array(
			'url' => $site_url,
			'dir' => $site_root,
		);
	}

	file_put_contents(
		HOSTS_FILE,
		'<?php $hosts = ' . var_export($hosts, true) . '; ?>'
	);

	exit;
}

?><!DOCTYPE html>
<html lang='ru'>

<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>
<title>Open Server :: Tools</title>
<style>
    a {
        background-color: transparent;
        -webkit-text-decoration-skip: objects
    }

    a:active,
    a:hover {
        outline-width: 0
    }

    *,
    *:after,
    *:before {
        box-sizing: inherit;
        margin: 0;
        padding: 0;
        color: #000;
    }

    html {
        box-sizing: border-box;
        font-size: 1px !important;
    }

    body {
        font: normal 14rem/21rem Arial, 'Helvetica CY', 'Nimbus Sans L', sans-serif;
        #background-color: #E5EEF5;
    }

    .outer {
        display: table;
        position: absolute;
        top: 0;
        left: 0;
        height: 100%;
        width: 100%;
    }

    .middle {
        display: table-cell;
        vertical-align: middle;
    }

    .inner {
        margin-left: auto;
        margin-right: auto;
        max-width: 570rem;
        min-width: 360rem;
        padding: 20rem;
    }

    h1 {
        line-height: 48rem;
        font-size: 48rem;
        margin-bottom: 45rem;
    }

    h2 {
        margin: 10px 0;
    }

    hr {
        margin: 10px 0;
    }
    </style>
</head>
<body>
<div class="outer">
<div class="middle">
<div class="inner">
<h1>Welcome!</h1>
<p>Open Server Panel is running ;-)</p>
<hr />
<h2>Documentation</h2>
<ul>
<li><a href="https://ospanel.io/docs/">User Manual</a></li>
</ul>
<?php

$tools = glob('*',  GLOB_ONLYDIR);

if ( isset($tools) && count($tools) ) {
	echo '<hr />';
	echo '<h2>Tools</h2>';
	echo '<ul>';
	foreach ($tools as $tool) {
		printf('<li><a href="%s">%1$s</a></li>', $tool);
	}
	echo '</ul>';
}

if ( file_exists(HOSTS_FILE) ) {
	include HOSTS_FILE;
}

if ( defined('HOSTS_AS_LIST') ) {
	$hosts_prolog = '<ul>';
	$hosts_item = '<li><a href="%s">%1$s</a> [<code>%s</code>]</li>';
	$hosts_epilog = '</ul>';
} else {
	$hosts_prolog = '<table border width=100%><tr><th width=30%>URL</th><th>DocumentRoot</th></tr>';
	$hosts_item = '<tr><td><a href="%s">%1$s</a></td><td><code>%s</code></td></tr>';
	$hosts_epilog = '</table>';
}

if ( isset($hosts) && $hosts_count = count($hosts) ) {
	echo '<hr />';
	printf('<h2>Hosts (%s)</h2>', $hosts_count);
	foreach ($hosts as $name => $sites) {
		printf('<h3>%s</h3>', $name);
		echo $hosts_prolog;
		foreach ($sites as $site) {
			printf($hosts_item, $site['url'], $site['dir']);
		}
		echo $hosts_epilog;
	}
}

?>
</div>
</div>
</div>
</body>
</html>
