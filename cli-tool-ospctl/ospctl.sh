#!/bin/sh

# =========================================================================

print_usage() {
	cat - <<HELP
USAGE
  ospctl [-v] [-d DIR] CMD

OPTIONS
  DIR is the directory to specify another location for Open Server.

  CMD is one of the commands explained below.

  These commands are used to control the Open Server main process:
    run         Launch the Open Server
    kill        Terminate the Open Server
    force-kill  Terminate the Open Server forcefully

  These commands are used to control servers:
    start       Start servers
    stop        Stop servers
    restart     Restart servers

  Other commands
    status      Show status for all processes

ENVIRONMENT
  OSP_HOME
  If specified and valid, it's used as the Open Server home directory.
  It can be overwritten with the "-d" option in the command line.
HELP
}

# =========================================================================

MYDIR="$( realpath "$0" | xargs dirname )"

OSP_NAME="Open Server.exe"

main() {
	OSP_VERBOSE=""
	if [ "$1" = "-v" ]
	then
		OSP_VERBOSE=1
		shift
	fi

	if [ "$1" = "-d" ]
	then
		OSP_HOME="$2"
		shift
		shift
	fi

	if [ $# -eq 0 ]
	then
		print_usage
		exit
	fi

	if [ -n "$OSP_HOME" ]
	then
		OSP_HOME="$( detect "$OSP_HOME" )"
	else
		OSP_HOME="$( detect "$PWD" )"
		if [ -z "$OSP_HOME" ] && [ "$PWD" != "$MYDIR" ]
		then
			OSP_HOME="$( detect "$MYDIR" )"
		fi
	fi

	if [ -z "$OSP_HOME" ]
	then
		die "$OSP_NAME not found"
	fi

	case "$1" in
	run )
		echo "Running..."
		"$OSP_HOME/$OSP_NAME" &
		;;
	kill )
		echo "Terminating..."
		taskkill /fi "IMAGENAME EQ $OSP_NAME"
		;;
	force-kill )
		echo "Killing..."
		taskkill /f /fi "IMAGENAME EQ $OSP_NAME"
		;;
	status )
		status
		;;
	start | stop | restart )
		load_ini
		send_command "$1"
		;;
	* )
		die "Illegal command: '$1'"
		;;
	esac
}

# =========================================================================

detect() {
	if [ -n "$OSP_VERBOSE" ]
	then
		warn "Try: $1"
	fi

	if [ -x "$1/$OSP_NAME" ]
	then
		echo "$1"
		return 0
	fi

	if [ "$1" = "/" ] || [ "${1#*:}" = "/" ]
	then
		return 1
	fi

	detect "$( dirname "$1" )"
}

# =========================================================================

load_ini() {
	while IFS='=' read -r k v
	do
		case "$k" in
		web	) OSP_INI_WEB="$v" ;;
		login	) OSP_INI_USER="$v" ;;
		pass	) OSP_INI_PASS="$v" ;;
		port	) OSP_INI_PORT="$v" ;;
		esac
	done <<IN
$(
	dos2unix < "$OSP_HOME/userdata/init.ini" \
	| sed 's/="\([^"]*\)"$/\1/'
)
IN
}

# =========================================================================

send_command() {
	if [ "$OSP_INI_WEB" != "1" ]
	then
		die "Web management not enabled"
	fi

	echo "Sending command: '$1'"

	OSP_AUTH="$( printf '%s' "$OSP_INI_USER:$OSP_INI_PASS" | base64 )"
	wget -q -O /dev/null \
		--header="Authorization: Basic $OSP_AUTH" \
		"http://127.0.0.1:$OSP_INI_PORT/$1"
}

# =========================================================================

status() {
	for n in powershell wmic
	do
		if command -v "$n" >/dev/null
		then
			status_$n
			return
		fi
	done

	die "Unable to display status"
}

status_powershell() {
	# shellcheck disable=SC2016
	powershell -c 'gwmi Win32_Process|?{$_.Caption -eq "'"$OSP_NAME"'"}|% {($p=$_.ProcessId),$_.CommandLine,""}; if($p){gwmi Win32_Process|?{$_.ParentProcessId -eq $p}|% {$_.ProcessId,$_.CommandLine,""}}'
}

status_wmic() {
	OSP_PID=""

	while IFS='=' read -r k v
	do
		if [ "$k" = "ProcessId" ]
		then
			OSP_PID="$v"
		fi
		echo "$k=$v"
	done <<IN
$(
	wmic Process where "Caption='$OSP_NAME'" \
	get ProcessId,CommandLine /value \
	| sed 's/\r//g; /^$/d'
)
IN

	if [ -z "$OSP_PID" ]
	then
		return
	fi

	wmic Process where "ParentProcessId=$OSP_PID" \
	get ProcessId,CommandLine /value \
	| sed 's/\r//g'
}

# =========================================================================

die() {
	warn "$@"
	exit 1
}

warn() {
	echo "$1" >&2
}

# =========================================================================

main "$@"

# =========================================================================

# =EOF
