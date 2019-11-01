#!/bin/bash
set -eo pipefail

HA_CONFIG=${HA_CONFIG:-"/config"}

# if command starts with an option, prepend hass
if [ "${1:0:1}" = '-' ]; then
	set -- hass --config ${HA_CONFIG} "$@"
fi

# Skip setup if they want an option that stops HA
HELP=0
for arg
do
	case "$arg" in
		-h|--help|--version)
			HELP=1
			break
		;;
	esac
done

# Usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="${1}"
	local def="${2:-}"

	local fvar="${var}_FILE"
	local val="${def}"

	if [ -n "${!var:-}" ] && [ -r "${fvar}" ]
	then
		echo "* Warning: both ${var} and ${fvar} are set, env ${var} takes priority"
	fi
	if [ -n "${!var:-}" ]
	then
		val="${!var}"
	elif [ -r "${fvar}" ]
	then
		val=$(< "${fvar}")
	fi
	export "${var}"="${val}"
}


_check_config() {
	local run
	local errors

	run=(python3 -m homeassistant --config ${HA_CONFIG} --script check_config --info --files)
	if ! errors="$("${run[@]}" 2>&1)"
	then
		cat >&2 <<-EOM
			Error: HA failed while attempting to check config
			       Command was: "${run[*]}"
			$errors
		EOM
		exit 1
	fi
}

if [ "$1" == "hass" ] && [ "${HELP}" == "0" ]
then
	if [ ! -e "${HA_CONFIG}/configuration.yaml" ]
	then
		echo >&2 "Warning: Configuration is uninitialized. Creating default configuration ..."
		run=(python3 -m homeassistant --config ${HA_CONFIG} --script ensure_config)
		if ! errors="$("${run[@]}" 2>&1 >/dev/null)"
		then
			cat >&2 <<-EOM
				Error: HA failed while attempting to create config
				       Command was: "${run[*]}"
				$errors
			EOM
			exit 1
		fi
	else
		# still need to check config, container may have started with --user
		_check_config
	fi
fi

exec "$@"
