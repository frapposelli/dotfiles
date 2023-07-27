#!/usr/bin/env bash
USER="fabio"
GETMAIL_BIN=/opt/homebrew/bin/getmail
MBSYNC_BIN=/opt/homebrew/bin/mbsync

if ! pgrep -l -f davmail.DavGateway; then
        echo "DavMail not running, opening it"
	su - ${USER} -c "JAVA_HOME=$(/usr/libexec/java_home -v 1.8) open -a DavMail.app"
	sleep 10
fi

if ! pgrep -l -f "MacOS/DEVONthink 3"; then
        echo "DEVONthink not running, opening it"
	su - ${USER} -c "open -a 'DEVONthink 3.app'"
	echo "Waiting for DEVONthink 3 to open and load the database"
	sleep 30
fi

echo "Starting mail retrieval"
su - ${USER} -c "${GETMAIL_BIN}"

# Closing DavMail every single time as it leaks memory
echo "Shutting down DavMail"
su - ${USER} -c "osascript -e 'quit app \"DavMail\"'"

echo "Syncing local Maildir to Synology Archive"
su - ${USER} -c "${MBSYNC_BIN} vmware-archive"
