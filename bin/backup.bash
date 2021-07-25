#!/usr/bin/env /bin/bash
###
#  @file   backup.bash
#  @brief  Backup
#  @author KrizTioaN (christiaanboersma@hotmail.com)
#  @date   2021-07-24
#  @note   BSD-3 licensed
#
###############################################

# ignore SIGTERM

trap -- '' SIGTERM

# Support folder location

SUPPORT_FOLDER="$HOME/Library/Application Support/Time Machine"

# Source variables

source "$SUPPORT_FOLDER/etc/config"

# Functions

function message() {
    /usr/local/bin/unbuffer echo "$(date "+%m-%d-%Y %H:%M:%S: $1")"
}

function main() {

    message "starting backup (PID $$)"

    # Unload the launch agents

    ACTIVE=$(launchctl list "$WATCHER_LAUNCH_AGENT" >/dev/null 2>/dev/null)

    if [ $? -eq "0" ]; then

        launchctl unload "$LAUNCH_AGENT_FOLDER/$WATCHER_LAUNCH_AGENT.plist"

        message "unloaded $WATCHER_LAUNCH_AGENT"
    fi

    ACTIVE=$(launchctl list "$PERIODIC_LAUNCH_AGENT" >/dev/null 2>/dev/null)

    if [ $? -eq "0" ]; then

        launchctl unload "$SUPPORT_FOLDER/share/$PERIODIC_LAUNCH_AGENT.plist"

        message "unloaded $PERIODIC_LAUNCH_AGENT"
    fi

    # Check for previous backup

    PREVIOUS_BACKUP=0

    if [ -e "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/Latest" ]; then

        PREVIOUS_BACKUP=$(date -j -f "%m%d%Y-%H%M%S" "$(readlink "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/Latest")" "+%s")

        message "previous backup dated $(date -r "$PREVIOUS_BACKUP")"
    fi

    # Set volume icon

    /bin/cp -f "$SUPPORT_FOLDER/share/${ICON}Running.icns" "$VOLUME_FOLDER$TARGET_VOLUME/.${ICON}.icns"

    message "volume icon set"

    # Write lock file

    echo $$ >"$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE"

    message "lock file written at $VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE"

    # Stop photoanalysisd

    launchctl disable gui/$UID/com.apple.photoanalysisd

    launchctl kill -TERM gui/$UID/com.apple.photoanalysisd

    # Set snapshot directory

    SNAPSHOT=$(date "+%m%d%Y-%H%M%S")

    # Check for latest backup

    TARGET_PATH="$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER"

    if [ ! -e "$TARGET_PATH/Latest" ]; then

        ln -s "$TARGET_PATH" "$TARGET_PATH/Latest"
    fi

    # Check for Growl and when available notify

    if [ -e /usr/local/bin/growlnotify ]; then
        /usr/local/bin/growlnotify --name "Backup Daemon" --appIcon "Time Machine" --title "Time Machine:" --message "$(date "+Backup started at %A %d %b %Y, %H:%M:%S")" &>/dev/null
    fi

    # Do the actual backup using rsync

    message "rsync started"

    #caffeinate /usr/local/bin/rsync -auAX \
    caffeinate /usr/bin/rsync -au -E \
        --exclude-from="$SUPPORT_FOLDER/config/timemachine.exclude" \
        --links --partial \
        --numeric-ids \
        --stats --human-readable \
        --link-dest="$TARGET_PATH/$(readlink "$TARGET_PATH/Latest")" \
        --one-file-system \
        "$SOURCE_FOLDER" "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$SNAPSHOT"

    message "rsync finished with code $?"

    # Re-start photoanalysisd

    launchctl enable gui/$UID/com.apple.photoanalysisd

    # Update the link to the latest backup

    pushd "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER" >/dev/null 2>&1

    /bin/rm -f Latest
    /bin/ln -s "$SNAPSHOT" Latest

    message "updated $SNAPSHOT to Latest"

    # Consolidate daily backup

    IFS=

    shopt -s nullglob

    message "consolidating daily backup"

    LIST=($(date -j -v -1d -f "%m%d%Y-%H%M%S" $SNAPSHOT "+%m%d%Y-??????"))

    if [ ${#LIST[@]} -gt 0 ]; then

        message "keeping ${LIST[0]}"

        for ((i = 1; i < ${#LIST[@]}; i++)); do

            message "removing ${LIST[i]}"

            /bin/rm -rf "${LIST[i]}"
        done
    else

        message "nothing to be done"
    fi

    # Consolidate weekly backup

    message "consolidating weekly backup"

    DAY_OF_WEEK=$(date -j -f "%m%d%Y-%H%M%S" $SNAPSHOT "+%w")

    HAD_FIRST=0

    for i in {1..7}; do

        DAY=$((${i} - 7 - $DAY_OF_WEEK))

        if [ "$DAY" -eq "0" ]; then

            continue
        fi

        LIST=($(date -j -v ${DAY}d -f "%m%d%Y-%H%M%S" $SNAPSHOT "+%m%d%Y-??????"))

        if [ ${#LIST[@]} -gt 0 ]; then

            for ((i = 0; i < ${#LIST[@]}; i++)); do

                if [ "$HAD_FIRST" -eq "0" ]; then

                    message "keeping ${LIST[i]}"

                    HAD_FIRST=1

                    continue
                fi

                message "removing ${LIST[i]}"

                /bin/rm -rf "${LIST[i]}"
            done
        fi
    done

    if [ "$HAD_FIRST" -eq "0" ]; then

        message "nothing to be done"
    fi

    # Consolidate monthly backup

    message "consolidating monthly backup"

    LIST=($(date -j -v -1m -f "%m%d%Y-%H%M%S" $SNAPSHOT "+%m??%Y-??????"))

    if [ ${#LIST[@]} -gt 0 ]; then

        message "keeping ${LIST[0]}"

        for ((i = 1; i < ${#LIST[@]}; i++)); do

            message "removing ${LIST[i]}"

            /bin/rm -rf "${LIST[i]}"
        done
    else

        message "nothing to be done"
    fi

    # Consolidate yearly backup

    message "consolidating yearly backup"

    LIST=($(date -j -v -1y -f "%m%d%Y-%H%M%S" $SNAPSHOT "+??%Y-??????"))

    if [ ${#LIST[@]} -gt 0 ]; then

        message "keeping ${LIST[0]}"

        for ((i = 1; i < ${#LIST[@]}; i++)); do

            message "removing ${LIST[i]}"

            /bin/rm -rf ${LIST[i]}
        done
    else

        message "nothing to be done"
    fi

    shopt -u nullglob

    unset IFS

    popd >/dev/null 2>&1

    # Remove the lock file

    /bin/rm -f "$VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE"

    message "lock file removed at $VOLUME_FOLDER$TARGET_VOLUME$TARGET_FOLDER/$LOCK_FILE"

    # Check for Growl and when available notify

    if [ -e /usr/local/bin/growlnotify ]; then
        /usr/local/bin/growlnotify --name "Backup Daemon" --appIcon "Time Machine" --title "Time Machine:" --message "$(date "+Backup finished at %A %d %b %Y, %H:%M:%S")" &>/dev/null
    fi

    # Restore volume icon

    /bin/cp -f "$SUPPORT_FOLDER/share/${ICON}.icns" "$VOLUME_FOLDER$TARGET_VOLUME/.${ICON}.icns"

    message "restored volume icon"

    # Load launch agents

    launchctl load "$LAUNCH_AGENT_FOLDER/$WATCHER_LAUNCH_AGENT.plist"

    message "loaded $WATCHER_LAUNCH_AGENT"

    launchctl load "$SUPPORT_FOLDER/share/$PERIODIC_LAUNCH_AGENT.plist"

    message "loaded $PERIODIC_LAUNCH_AGENT"

    # Done

    message "backup completed"
}

main >>"$HOME/Library/Logs/$LOG_FILE" 2>&1
