#!/usr/bin/env /bin/bash
###
#  @file   backup.bash
#  @brief  Time Machine Watcher
#  @author KrizTioaN (christiaanboersma@hotmail.com)
#  @date   2021-07-24
#  @note   BSD-3 licensed
#
###############################################
# Support folder location

SUPPORT_FOLDER="$HOME/Library/Application Support/Time Machine"

# Source variables

source "$SUPPORT_FOLDER/etc/config"

# Functions

function message {
	/usr/local/bin/unbuffer echo "$(date "+%m-%d-%Y %H:%M:%S: $1")"
}

function main {

	message "starting..."

	# Read previous mount status

	MOUNT_STATUS=0

	if [ -e "/tmp/timemachine.mount.status" ]; then

		MOUNT_STATUS=$(cat "/tmp/timemachine.mount.status")

		/usr/local/bin/unbuffer echo -n "$(date "+%m-%d-%Y %H:%M:%S: read previous mount status")"

		if [ "$MOUNT_STATUS" -eq "1" ]; then

			/usr/local/bin/unbuffer echo " (yes)"
		else

			/usr/local/bin/unbuffer echo " (no)"
		fi
	fi

	# Sleep to allow enough time for the system to finish mounting
	# any external volume

	if [ "$MOUNT_STATUS" -eq "0" ]; then

		message "sleeping for $DELAY seconds"

		sleep $DELAY

		message "continuing"
	fi

	# First, check target volume, possibly stopping periodic service

	if [ ! -e "$VOLUME_FOLDER$TARGET_VOLUME" ]; then

		message "$VOLUME_FOLDER$TARGET_VOLUME not available"

		ACTIVE=$(launchctl list "$PERIODIC_LAUNCH_AGENT" >/dev/null 2>/dev/null)

		if [ $? -eq "0" ]; then

			launchctl unload "$SUPPORT_FOLDER/share/$PERIODIC_LAUNCH_AGENT.plist"

			message "unloaded $PERIODIC_LAUNCH_AGENT"
		fi

		echo "0" >"/tmp/timemachine.mount.status"

		message "saved current mount status (no)"

		message "terminating"

		exit 0
	fi

	# Second, check source folder, possibly stopping periodic service

	if [ ! -e "$SOURCE_FOLDER" ]; then

		message "$SOURCE_FOLDER not available"

		ACTIVE=$(launchctl list "$PERIODIC_LAUNCH_AGENT" >/dev/null 2>/dev/null)

		if [ $? -eq "0" ]; then

			launchctl unload "$SUPPORT_FOLDER/share/$PERIODIC_LAUNCH_AGENT.plist"

			message "unloaded $PERIODIC_LAUNCH_AGENT"
		fi

		echo "0" >"/tmp/timemachine.mount.status"

		message "saved current mount status (no)"

		message "terminating"

		exit 0
	fi

	# Check if we are responding to a periodic run or a (first) mount
	# event

	if [ "$1" == "--periodic" ]; then

		message "responding to periodic event"

	elif [ "$MOUNT_STATUS" -eq "0" ]; then

		message "responding to (first) mount event"

		echo "1" >"/tmp/timemachine.mount.status"

		message "saved current mount status (yes)"
	else

		message "not a periodic run and $VOLUME_FOLDER$TARGET_VOLUME already mounted"

		message "terminating"

		exit 0
	fi

	# Check for target folder

	if [ ! -e "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER" ]; then

		/bin/mkdir -p "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER"

		message "created $VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER"

		/bin/cp -f "$SUPPORT_FOLDER/share/${ICON}.icns" "$VOLUME_FOLDER$TARGET_VOLUME/.${ICON}.icns"

		message "persistent volume icon set"
	fi

	# Check for lock file

	if [ -e "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE" ]; then

		message "lock file found at $VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE"

		PID=$(cat "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE")

		message "backup already running with pid $PID"

		message "terminating"

		exit 0
	fi

	# Check for previous backup

	PREVIOUS_BACKUP=0

	if [ -e "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/Latest" ]; then

		PREVIOUS_BACKUP=$(date -j -f "%m%d%Y-%H%M%S" "$(readlink "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/Latest")" "+%s")

		message "previous backup dated $(date -r "$PREVIOUS_BACKUP")"

		if [ $(date "+%s") -lt $(date -v+${DELTA_HOURS}H -j -f "%s" "$PREVIOUS_BACKUP" "+%s") ]; then

			message "backup less than $DELTA_HOURS hours old"

			message "terminating"

			exit 0
		fi
	fi

	# ignore SIGTERM when received from launchd to finish gracefully

	trap -- '' SIGTERM

	# Going for a backup

	message "calling $BACKUP_SCRIPT"

	# spawning backup script

	caffeinate "$SUPPORT_FOLDER/bin/$BACKUP_SCRIPT" &

	disown $!

	message "leaving $(basename "$0")"
}

main $1 >>"$HOME/Library/Logs/$LOG_FILE" 2>&1
